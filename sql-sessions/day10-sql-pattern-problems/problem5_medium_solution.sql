-- =============================================================
-- Problem 5 Medium Solution — First and Last Event + Last Status
-- *** Instructor use only ***
-- =============================================================
-- Run problem5_medium.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — MIN/MAX + subquery for last status (most readable)
-- =============================================================
-- MIN(run_at) = first run, MAX(run_at) = last run.
-- A correlated subquery fetches the status of the row matching MAX(run_at).

SELECT
    pipeline,
    MIN(run_at) AS first_run,
    MAX(run_at) AS last_run,
    (
        SELECT status FROM pipeline_runs pr2
        WHERE pr2.pipeline = pr.pipeline
        ORDER BY run_at DESC
        LIMIT 1
    ) AS last_status
FROM pipeline_runs pr
GROUP BY pipeline
ORDER BY pipeline;


-- =============================================================
-- APPROACH 2 — ROW_NUMBER CTE to isolate first and last rows
-- =============================================================
-- Assign two row numbers per pipeline: one ascending (first), one descending (last).
-- Filter rn_asc = 1 → first run; rn_desc = 1 → last run. Then join both.

WITH ranked AS (
    SELECT
        pipeline,
        status,
        run_at,
        ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at ASC)  AS rn_asc,
        ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at DESC) AS rn_desc
    FROM pipeline_runs
)
SELECT
    f.pipeline,
    f.run_at  AS first_run,
    l.run_at  AS last_run,
    l.status  AS last_status
FROM ranked f
JOIN ranked l ON f.pipeline = l.pipeline AND l.rn_desc = 1
WHERE f.rn_asc = 1
ORDER BY f.pipeline;


-- =============================================================
-- APPROACH 3 — FIRST_VALUE and LAST_VALUE window functions
-- =============================================================
-- FIRST_VALUE and LAST_VALUE with full frame clause give
-- first and last values within each partition in a single pass.

WITH windowed AS (
    SELECT DISTINCT
        pipeline,
        FIRST_VALUE(run_at) OVER (
            PARTITION BY pipeline ORDER BY run_at
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS first_run,
        LAST_VALUE(run_at) OVER (
            PARTITION BY pipeline ORDER BY run_at
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_run,
        LAST_VALUE(status) OVER (
            PARTITION BY pipeline ORDER BY run_at
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_status
    FROM pipeline_runs
)
SELECT pipeline, first_run, last_run, last_status
FROM windowed
ORDER BY pipeline;

-- Note:
--   Approach 1 is the most concise but uses a correlated subquery per row.
--   Approach 2 (double ROW_NUMBER) is explicit and scales well.
--   Approach 3 (FIRST/LAST_VALUE) — remember the full frame is REQUIRED for LAST_VALUE.
--   Without ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING,
--   LAST_VALUE returns the current row, not the last row of the partition.
