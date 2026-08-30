-- =============================================================
-- Problem 5 — First and Last Event
-- Pattern: MIN/MAX per group or FIRST_VALUE window function
-- =============================================================
-- Question:
--   Find the very first run time for each pipeline.
--   Return: pipeline, first_run.
--   Order by pipeline.
-- =============================================================

DROP TABLE IF EXISTS pipeline_runs;

CREATE TABLE pipeline_runs (
    run_id    SERIAL PRIMARY KEY,
    pipeline  VARCHAR(50),
    status    VARCHAR(20),
    run_at    TIMESTAMP
);

INSERT INTO pipeline_runs (pipeline, status, run_at) VALUES
    ('etl_orders',    'SUCCESS', '2024-01-10 08:00:00'),
    ('etl_orders',    'FAILED',  '2024-01-11 08:05:00'),
    ('etl_orders',    'SUCCESS', '2024-01-12 08:10:00'),
    ('etl_orders',    'SUCCESS', '2024-01-13 08:00:00'),
    ('etl_customers', 'SUCCESS', '2024-01-10 09:00:00'),
    ('etl_customers', 'SUCCESS', '2024-01-11 09:05:00'),
    ('etl_customers', 'FAILED',  '2024-01-12 09:10:00'),
    ('etl_products',  'FAILED',  '2024-01-10 10:00:00'),
    ('etl_products',  'FAILED',  '2024-01-11 10:05:00'),
    ('etl_products',  'SUCCESS', '2024-01-12 10:10:00');

-- Expected output:
--
--   pipeline       | first_run
--   ---------------+---------------------
--   etl_customers  | 2024-01-10 09:00:00
--   etl_orders     | 2024-01-10 08:00:00
--   etl_products   | 2024-01-10 10:00:00

-- YOUR ANSWER:
