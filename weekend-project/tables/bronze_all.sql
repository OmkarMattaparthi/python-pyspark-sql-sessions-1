-- Bronze schema
CREATE SCHEMA IF NOT EXISTS bronze;

-- ── bronze.payments ──────────────────────────────────────────────────────────
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

-- ── bronze.sessions ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bronze.sessions (
    id             BIGINT PRIMARY KEY,
    session_id     VARCHAR(100) UNIQUE NOT NULL,
    vehicle_id     VARCHAR(100),
    station_id     VARCHAR(100),
    customer_id    VARCHAR(100),
    started_at     TIMESTAMPTZ,
    ended_at       TIMESTAMPTZ,
    duration_min   INT,
    energy_kwh     NUMERIC(10, 3),
    cost_aud       NUMERIC(12, 2),
    peak_power_kw  NUMERIC(10, 2),
    connector_type VARCHAR(50),
    session_status VARCHAR(50),
    payment_id     VARCHAR(100),
    created_at     TIMESTAMPTZ,
    updated_at     TIMESTAMPTZ,
    ingested_at    TIMESTAMPTZ
);

-- ── bronze.customers ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bronze.customers (
    id            BIGINT PRIMARY KEY,
    customer_id   VARCHAR(100) UNIQUE NOT NULL,
    full_name     VARCHAR(200),
    email         VARCHAR(200),
    phone         VARCHAR(50),
    loyalty_tier  VARCHAR(50),
    signup_date   DATE,
    created_at    TIMESTAMPTZ,
    updated_at    TIMESTAMPTZ,
    ingested_at   TIMESTAMPTZ
);

-- ── bronze.vehicles (SCD2 — multiple rows per vehicle_id for history) ─────────
CREATE TABLE IF NOT EXISTS bronze.vehicles (
    id                   BIGINT PRIMARY KEY,
    vehicle_id           VARCHAR(100) NOT NULL,
    make                 VARCHAR(100),
    model                VARCHAR(100),
    year                 INT,
    vehicle_type         VARCHAR(20),
    battery_capacity_kwh NUMERIC(8, 2),
    range_km             INT,
    registration_state   VARCHAR(10),
    partner_id           VARCHAR(100),
    effective_from       DATE,
    effective_to         DATE,
    is_current           BOOLEAN,
    created_at           TIMESTAMPTZ,
    updated_at           TIMESTAMPTZ,
    ingested_at          TIMESTAMPTZ
);

-- ── bronze.stations ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bronze.stations (
    id                 BIGINT PRIMARY KEY,
    station_id         VARCHAR(100) UNIQUE NOT NULL,
    name               VARCHAR(200),
    state_code         VARCHAR(10),
    city               VARCHAR(100),
    latitude           NUMERIC(10, 6),
    longitude          NUMERIC(10, 6),
    charger_type       VARCHAR(50),
    max_power_kw       NUMERIC(8, 2),
    num_connectors     INT,
    operator           VARCHAR(100),
    is_active          BOOLEAN,
    commissioned_date  DATE,
    created_at         TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ,
    ingested_at        TIMESTAMPTZ
);

-- ── bronze.partners ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bronze.partners (
    id                 BIGINT PRIMARY KEY,
    partner_id         VARCHAR(100) UNIQUE NOT NULL,
    partner_name       VARCHAR(200),
    state              VARCHAR(50),
    status             VARCHAR(50),
    revenue_share_pct  NUMERIC(5, 2),
    contract_start     DATE,
    contract_end       DATE,
    created_at         TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ,
    ingested_at        TIMESTAMPTZ
);

-- ── bronze.energy_prices ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bronze.energy_prices (
    id              BIGINT PRIMARY KEY,
    price_id        VARCHAR(100) UNIQUE NOT NULL,
    station_id      VARCHAR(100),
    state_code      VARCHAR(10),
    price_per_kwh   NUMERIC(8, 4),
    off_peak_price  NUMERIC(8, 4),
    peak_price      NUMERIC(8, 4),
    currency        VARCHAR(10),
    tariff_type     VARCHAR(50),
    effective_from  TIMESTAMPTZ,
    effective_to    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    ingested_at     TIMESTAMPTZ
);

-- ── bronze.pipeline_metadata ──────────────────────────────────────────────────
-- tracks last run per pipeline — used to determine incremental load cursor
CREATE TABLE IF NOT EXISTS bronze.pipeline_metadata (
    id                SERIAL PRIMARY KEY,
    pipeline_name     VARCHAR(100),
    load_type         VARCHAR(20),
    last_run_at       TIMESTAMPTZ,
    last_updated_at   TIMESTAMPTZ,
    records_inserted  INT
);
