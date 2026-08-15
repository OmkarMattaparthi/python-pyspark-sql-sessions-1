from datetime import datetime, timezone


def create_tables(connection):
    cursor = connection.cursor()

    # create bronze schema if not exists
    cursor.execute("CREATE SCHEMA IF NOT EXISTS bronze;")

    # create payments table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS bronze.payments (
            id            BIGINT PRIMARY KEY,
            payment_id    VARCHAR(100) UNIQUE NOT NULL,
            session_id    VARCHAR(100),
            customer_id   VARCHAR(100),
            gateway       VARCHAR(50),
            amount_aud    NUMERIC(12, 2),
            gst           NUMERIC(12, 2),
            payment_mode  VARCHAR(50),
            status        VARCHAR(50),
            processed_at  TIMESTAMPTZ,
            created_at    TIMESTAMPTZ,
            updated_at    TIMESTAMPTZ,
            ingested_at   TIMESTAMPTZ
        );
    """)

    # create pipeline metadata table to track last run
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS bronze.pipeline_metadata (
            id            SERIAL PRIMARY KEY,
            pipeline_name VARCHAR(100),
            load_type     VARCHAR(20),
            last_run_at   TIMESTAMPTZ,
            last_updated_at TIMESTAMPTZ,
            records_inserted INT
        );
    """)

    connection.commit()
    print("Tables ready")


def get_last_updated_at(connection):
    cursor = connection.cursor()
    cursor.execute("""
        SELECT last_updated_at
        FROM bronze.pipeline_metadata
        WHERE pipeline_name = 'voltgrid_payments'
        ORDER BY last_run_at DESC
        LIMIT 1;
    """)
    row = cursor.fetchone()
    if row and row[0]:
        return row[0].isoformat()
    return None


def insert_payments(connection, records):
    cursor = connection.cursor()

    query = """
        INSERT INTO bronze.payments (
            id, payment_id, session_id, customer_id, gateway,
            amount_aud, gst, payment_mode, status,
            processed_at, created_at, updated_at, ingested_at
        )
        VALUES (
            %(id)s, %(payment_id)s, %(session_id)s, %(customer_id)s, %(gateway)s,
            %(amount_aud)s, %(gst)s, %(payment_mode)s, %(status)s,
            %(processed_at)s, %(created_at)s, %(updated_at)s, %(ingested_at)s
        )
        ON CONFLICT (id) DO UPDATE SET
            status       = EXCLUDED.status,
            amount_aud   = EXCLUDED.amount_aud,
            updated_at   = EXCLUDED.updated_at,
            ingested_at  = EXCLUDED.ingested_at;
    """

    cursor.executemany(query, records)
    connection.commit()
    print(f"Inserted {len(records)} records into bronze.payments")


def save_pipeline_metadata(connection, load_type, records_inserted, last_updated_at):
    cursor = connection.cursor()
    cursor.execute("""
        INSERT INTO bronze.pipeline_metadata
            (pipeline_name, load_type, last_run_at, last_updated_at, records_inserted)
        VALUES (%s, %s, %s, %s, %s);
    """, (
        "voltgrid_payments",
        load_type,
        datetime.now(timezone.utc),
        last_updated_at,
        records_inserted
    ))
    connection.commit()
    print("Pipeline metadata saved")
