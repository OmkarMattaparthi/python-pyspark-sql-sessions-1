-- =============================================================
-- Problem 5 Hard — First and Last Event
-- Pattern: First success, last failure, consecutive failures streak
-- =============================================================
-- Question:
--   For each pipeline report:
--     - first_success      : timestamp of the first SUCCESS run
--     - last_failure       : timestamp of the most recent FAILED run (NULL if none)
--     - current_fail_streak: number of consecutive FAILED runs at the END of the run history
--                            (0 if the most recent run is SUCCESS)
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
    ('etl_customers', 'FAILED',  '2024-01-13 09:15:00'),
    ('etl_products',  'FAILED',  '2024-01-10 10:00:00'),
    ('etl_products',  'FAILED',  '2024-01-11 10:05:00'),
    ('etl_products',  'SUCCESS', '2024-01-12 10:10:00');

-- Expected output:
--
--   pipeline       | first_success       | last_failure        | current_fail_streak
--   ---------------+---------------------+---------------------+--------------------
--   etl_customers  | 2024-01-10 09:00:00 | 2024-01-13 09:15:00 |                   2
--   etl_orders     | 2024-01-10 08:00:00 | 2024-01-11 08:05:00 |                   0
--   etl_products   | 2024-01-12 10:10:00 | 2024-01-11 10:05:00 |                   0
--
-- Note:
--   etl_customers ends with 2 consecutive FAILEDs → current_fail_streak = 2
--   etl_orders last run is SUCCESS → current_fail_streak = 0
--   etl_products last run is SUCCESS → current_fail_streak = 0

-- YOUR ANSWER:
