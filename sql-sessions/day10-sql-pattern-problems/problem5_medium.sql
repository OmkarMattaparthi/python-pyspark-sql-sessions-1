-- =============================================================
-- Problem 5 Medium — First and Last Event
-- Pattern: MIN + MAX + LAST_VALUE / ROW_NUMBER to get status of last run
-- =============================================================
-- Question:
--   For each pipeline, show the first run time, last run time,
--   and the status of the most recent run.
--   Return: pipeline, first_run, last_run, last_status.
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
--   pipeline       | first_run           | last_run            | last_status
--   ---------------+---------------------+---------------------+------------
--   etl_customers  | 2024-01-10 09:00:00 | 2024-01-12 09:10:00 | FAILED
--   etl_orders     | 2024-01-10 08:00:00 | 2024-01-13 08:00:00 | SUCCESS
--   etl_products   | 2024-01-10 10:00:00 | 2024-01-12 10:10:00 | SUCCESS

-- YOUR ANSWER:
