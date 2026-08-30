-- =============================================================
-- Problem 5 Solution — First and Last Event
-- *** Instructor use only ***
-- =============================================================
-- Run problem5.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — MIN with GROUP BY (simplest)
-- =============================================================
-- MIN(run_at) per pipeline = first run. Straightforward aggregation.

SELECT
    pipeline,
    MIN(run_at) AS first_run
FROM pipeline_runs
GROUP BY pipeline
ORDER BY pipeline;


-- =============================================================
-- APPROACH 2 — FIRST_VALUE window function
-- =============================================================
-- FIRST_VALUE returns the first value in the window partition.
-- Wrap in a CTE to deduplicate (each row gets the same first_run value).

WITH first_runs AS (
    SELECT DISTINCT
        pipeline,
        FIRST_VALUE(run_at) OVER (
            PARTITION BY pipeline
            ORDER BY run_at
        ) AS first_run
    FROM pipeline_runs
)
SELECT pipeline, first_run
FROM first_runs
ORDER BY pipeline;


-- =============================================================
-- APPROACH 3 — ROW_NUMBER filter (most flexible, extend easily)
-- =============================================================
-- Assign row numbers per pipeline ordered by run_at.
-- rn = 1 is the first run. Easy to extend to "first N runs" later.

WITH ranked AS (
    SELECT
        pipeline,
        run_at AS first_run,
        ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at) AS rn
    FROM pipeline_runs
)
SELECT pipeline, first_run
FROM ranked
WHERE rn = 1
ORDER BY pipeline;

-- Note:
--   Approach 1 (GROUP BY MIN) is the most concise — use this for simple first/last.
--   Approach 2 (FIRST_VALUE) is the window function version — good to know.
--   Approach 3 (ROW_NUMBER) is the most flexible — easily extends to top-N or last-N.
