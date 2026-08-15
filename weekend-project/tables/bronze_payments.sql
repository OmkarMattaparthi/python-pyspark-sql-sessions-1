-- Bronze schema
CREATE SCHEMA IF NOT EXISTS bronze;

-- bronze.payments — raw payment records from VoltGrid API
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
    ingested_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- bronze.pipeline_metadata — tracks each pipeline run for incremental load support
CREATE TABLE IF NOT EXISTS bronze.pipeline_metadata (
    id               SERIAL PRIMARY KEY,
    pipeline_name    VARCHAR(100) NOT NULL,
    load_type        VARCHAR(20)  NOT NULL,   -- 'full' or 'incremental'
    status           VARCHAR(20)  NOT NULL,   -- 'success' or 'failed'
    records_fetched  INT          DEFAULT 0,
    records_inserted INT          DEFAULT 0,
    records_skipped  INT          DEFAULT 0,
    last_updated_at  TIMESTAMPTZ,             -- max updated_at from loaded batch (used as next incremental cursor)
    started_at       TIMESTAMPTZ,
    finished_at      TIMESTAMPTZ
);
