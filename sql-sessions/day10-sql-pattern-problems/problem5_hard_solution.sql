-- =============================================================
-- Problem 5 Hard Solution — First Success, Last Failure, Current Fail Streak
-- *** Instructor use only ***
-- =============================================================


-- =============================================================
-- APPROACH 1 — ROW_NUMBER subtraction trick to find streak groups
-- =============================================================
-- For the current_fail_streak, assign a global row_number per pipeline
-- and a row_number only over FAILED rows. Their difference is constant
-- within each consecutive block of FAILEDs at the end.
-- The LAST block of FAILEDs must touch the last run of the pipeline.

WITH ordered AS (
    SELECT
        pipeline,
        status,
        run_at,
        ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at) AS rn_all,
        ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at DESC) AS rn_desc
    FROM pipeline_runs
),
last_status AS (
    SELECT pipeline, status AS last_run_status
    FROM ordered
    WHERE rn_desc = 1
),
fail_streaks AS (
    SELECT
        pipeline,
        run_at,
        rn_all,
        ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at) AS rn_fail,
        rn_all - ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at) AS grp
    FROM ordered
    WHERE status = 'FAILED'
),
streak_ends AS (
    SELECT
        fs.pipeline,
        COUNT(*) AS streak_len,
        MAX(rn_all) AS last_rn
    FROM fail_streaks fs
    GROUP BY fs.pipeline, fs.grp
),
last_rn_per_pipe AS (
    SELECT pipeline, MAX(rn_all) AS total_runs
    FROM ordered
    GROUP BY pipeline
),
current_streak AS (
    SELECT se.pipeline, se.streak_len
    FROM streak_ends se
    JOIN last_rn_per_pipe lp ON se.pipeline = lp.pipeline
    WHERE se.last_rn = lp.total_runs
),
summary AS (
    SELECT
        pipeline,
        MIN(CASE WHEN status = 'SUCCESS' THEN run_at END) AS first_success,
        MAX(CASE WHEN status = 'FAILED'  THEN run_at END) AS last_failure
    FROM pipeline_runs
    GROUP BY pipeline
)
SELECT
    s.pipeline,
    s.first_success,
    s.last_failure,
    COALESCE(cs.streak_len, 0) AS current_fail_streak
FROM summary s
LEFT JOIN current_streak cs ON s.pipeline = cs.pipeline
JOIN last_status ls ON s.pipeline = ls.pipeline
ORDER BY s.pipeline;


-- =============================================================
-- APPROACH 2 — LAG-based consecutive failure detection
-- =============================================================
-- Walk the run history per pipeline from the END (using DESC ordering).
-- Count consecutive FAILEDs starting from the latest run.
-- A non-FAILED row breaks the streak.

WITH ordered AS (
    SELECT
        pipeline,
        status,
        run_at,
        ROW_NUMBER() OVER (PARTITION BY pipeline ORDER BY run_at DESC) AS rn_desc,
        LAG(status) OVER (PARTITION BY pipeline ORDER BY run_at DESC) AS next_status
    FROM pipeline_runs
),
fail_flags AS (
    SELECT
        pipeline,
        status,
        rn_desc,
        CASE
            WHEN status = 'FAILED'
             AND (next_status = 'FAILED' OR next_status IS NULL)
            THEN 1 ELSE 0
        END AS in_end_streak
    FROM ordered
),
end_streaks AS (
    SELECT pipeline, SUM(in_end_streak) AS current_fail_streak
    FROM fail_flags
    WHERE rn_desc <= (
        SELECT MIN(rn_desc)
        FROM fail_flags ff2
        WHERE ff2.pipeline = fail_flags.pipeline
          AND ff2.status != 'FAILED'
    ) OR (
        SELECT COUNT(*) FROM pipeline_runs pr2
        WHERE pr2.pipeline = fail_flags.pipeline AND pr2.status != 'FAILED'
    ) = 0
    GROUP BY pipeline
),
summary AS (
    SELECT
        pipeline,
        MIN(CASE WHEN status = 'SUCCESS' THEN run_at END) AS first_success,
        MAX(CASE WHEN status = 'FAILED'  THEN run_at END) AS last_failure
    FROM pipeline_runs
    GROUP BY pipeline
)
SELECT
    s.pipeline,
    s.first_success,
    s.last_failure,
    COALESCE(es.current_fail_streak, 0) AS current_fail_streak
FROM summary s
LEFT JOIN end_streaks es ON s.pipeline = es.pipeline
ORDER BY s.pipeline;


-- =============================================================
-- APPROACH 3 — Simple: count FAILEDs after last SUCCESS
-- =============================================================
-- current_fail_streak = count of FAILEDs that occurred AFTER the most recent SUCCESS.
-- If pipeline has never succeeded, count all FAILEDs.
-- If last run is SUCCESS, current_fail_streak = 0.

WITH last_success AS (
    SELECT pipeline, MAX(run_at) AS last_success_at
    FROM pipeline_runs
    WHERE status = 'SUCCESS'
    GROUP BY pipeline
),
summary AS (
    SELECT
        p.pipeline,
        MIN(CASE WHEN p.status = 'SUCCESS' THEN p.run_at END) AS first_success,
        MAX(CASE WHEN p.status = 'FAILED'  THEN p.run_at END) AS last_failure
    FROM pipeline_runs p
    GROUP BY p.pipeline
),
streak AS (
    SELECT
        p.pipeline,
        COUNT(*) AS current_fail_streak
    FROM pipeline_runs p
    LEFT JOIN last_success ls ON p.pipeline = ls.pipeline
    WHERE p.status = 'FAILED'
      AND (ls.last_success_at IS NULL OR p.run_at > ls.last_success_at)
    GROUP BY p.pipeline
)
SELECT
    s.pipeline,
    s.first_success,
    s.last_failure,
    COALESCE(st.current_fail_streak, 0) AS current_fail_streak
FROM summary s
LEFT JOIN streak st ON s.pipeline = st.pipeline
ORDER BY s.pipeline;

-- Note:
--   Approach 3 is the simplest and most readable: FAILEDs after the last SUCCESS
--   are exactly the current trailing failure streak.
--   It handles edge cases: pipeline never succeeded (ls.last_success_at IS NULL)
--   and pipeline's last run is SUCCESS (no FAILEDs after last SUCCESS → streak = 0).
