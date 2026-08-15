from datetime import datetime, timezone
from config.settings import BRONZE_SCHEMA, PAYMENTS_TABLE, METADATA_TABLE, PIPELINE_NAME


# ── Schema / table setup ────────────────────────────────────────────────────

def ensure_schema(conn):
    """Create bronze schema if it doesn't exist."""
    with conn.cursor() as cur:
        cur.execute(f"CREATE SCHEMA IF NOT EXISTS {BRONZE_SCHEMA};")
    conn.commit()
    print(f"[loader] Schema '{BRONZE_SCHEMA}' ready")


def ensure_payments_table(conn):
    """Create bronze.payments if it doesn't exist."""
    with conn.cursor() as cur:
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS {BRONZE_SCHEMA}.{PAYMENTS_TABLE} (
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
                ingested_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
            );
        """)
    conn.commit()
    print(f"[loader] Table '{BRONZE_SCHEMA}.{PAYMENTS_TABLE}' ready")


def ensure_metadata_table(conn):
    """Create bronze.pipeline_metadata if it doesn't exist."""
    with conn.cursor() as cur:
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS {BRONZE_SCHEMA}.{METADATA_TABLE} (
                id              SERIAL PRIMARY KEY,
                pipeline_name   VARCHAR(100) NOT NULL,
                load_type       VARCHAR(20)  NOT NULL,   -- 'full' or 'incremental'
                status          VARCHAR(20)  NOT NULL,   -- 'success' or 'failed'
                records_fetched INT          DEFAULT 0,
                records_inserted INT         DEFAULT 0,
                records_skipped INT          DEFAULT 0,
                last_updated_at TIMESTAMPTZ,             -- max updated_at from loaded records
                started_at      TIMESTAMPTZ,
                finished_at     TIMESTAMPTZ
            );
        """)
    conn.commit()
    print(f"[loader] Table '{BRONZE_SCHEMA}.{METADATA_TABLE}' ready")


# ── Metadata helpers ─────────────────────────────────────────────────────────

def get_last_updated_at(conn):
    """
    Return the max updated_at from the last successful run stored in pipeline_metadata.
    Used by incremental load to know where to resume from.
    Returns ISO string or None.
    """
    with conn.cursor() as cur:
        cur.execute(f"""
            SELECT last_updated_at
            FROM {BRONZE_SCHEMA}.{METADATA_TABLE}
            WHERE pipeline_name = %s
              AND status = 'success'
            ORDER BY finished_at DESC
            LIMIT 1;
        """, (PIPELINE_NAME,))
        row = cur.fetchone()
    if row and row[0]:
        return row[0].isoformat()
    return None


def write_metadata(conn, load_type, status, records_fetched, records_inserted,
                   records_skipped, last_updated_at, started_at):
    """Insert a pipeline run record into pipeline_metadata."""
    finished_at = datetime.now(timezone.utc)
    with conn.cursor() as cur:
        cur.execute(f"""
            INSERT INTO {BRONZE_SCHEMA}.{METADATA_TABLE}
                (pipeline_name, load_type, status, records_fetched,
                 records_inserted, records_skipped, last_updated_at,
                 started_at, finished_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            PIPELINE_NAME, load_type, status,
            records_fetched, records_inserted, records_skipped,
            last_updated_at, started_at, finished_at,
        ))
    conn.commit()
    print(f"[loader] Metadata written — status={status}, inserted={records_inserted}, duration={finished_at - started_at}")


# ── Upsert ───────────────────────────────────────────────────────────────────

def upsert_payments(conn, records):
    """
    Upsert a list of transformed payment dicts into bronze.payments.
    ON CONFLICT (id) updates all mutable fields — safe to re-run (idempotent).
    Returns count of rows upserted.
    """
    if not records:
        print("[loader] No records to insert")
        return 0

    sql = f"""
        INSERT INTO {BRONZE_SCHEMA}.{PAYMENTS_TABLE}
            (id, payment_id, session_id, customer_id, gateway,
             amount_aud, gst, payment_mode, status,
             processed_at, created_at, updated_at, ingested_at)
        VALUES
            (%(id)s, %(payment_id)s, %(session_id)s, %(customer_id)s, %(gateway)s,
             %(amount_aud)s, %(gst)s, %(payment_mode)s, %(status)s,
             %(processed_at)s, %(created_at)s, %(updated_at)s, %(ingested_at)s)
        ON CONFLICT (id) DO UPDATE SET
            payment_id   = EXCLUDED.payment_id,
            session_id   = EXCLUDED.session_id,
            customer_id  = EXCLUDED.customer_id,
            gateway      = EXCLUDED.gateway,
            amount_aud   = EXCLUDED.amount_aud,
            gst          = EXCLUDED.gst,
            payment_mode = EXCLUDED.payment_mode,
            status       = EXCLUDED.status,
            processed_at = EXCLUDED.processed_at,
            created_at   = EXCLUDED.created_at,
            updated_at   = EXCLUDED.updated_at,
            ingested_at  = EXCLUDED.ingested_at;
    """
    with conn.cursor() as cur:
        cur.executemany(sql, records)
    conn.commit()
    print(f"[loader] Upserted {len(records)} records into {BRONZE_SCHEMA}.{PAYMENTS_TABLE}")
    return len(records)


def get_max_updated_at(records):
    """Return the max updated_at from a list of transformed records (as string)."""
    timestamps = [r["updated_at"] for r in records if r.get("updated_at")]
    return max(timestamps) if timestamps else None
