CREATE TABLE payments (
    id BIGINT PRIMARY KEY,
    payment_id VARCHAR(100) UNIQUE NOT NULL,
    session_id VARCHAR(100),
    customer_id VARCHAR(100),
    gateway VARCHAR(50),
    amount_aud NUMERIC(12,2),
    gst NUMERIC(12,2),
    payment_mode VARCHAR(50),
    status VARCHAR(50),
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    loaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);