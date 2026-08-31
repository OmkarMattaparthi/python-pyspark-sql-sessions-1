-- =============================================================
-- Problem 2 Medium Solution — Gaps and Islands (login streaks)
-- *** Instructor use only ***
-- =============================================================
-- Run problem2_medium.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — ROW_NUMBER subtraction trick (classic gaps & islands)
-- =============================================================
-- For consecutive dates:
--   login_date - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date)
--   produces the SAME value for all dates in the same streak.
-- A gap breaks consecutiveness → the difference increases → new group.
-- GROUP BY user_id + that difference, then MIN = start, MAX = end.

WITH numbered AS (
    SELECT
        user_id,
        login_date,
        login_date - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) || ' days')::INTERVAL AS grp
    FROM user_logins
)
SELECT
    user_id,
    MIN(login_date)                            AS streak_start,
    MAX(login_date)                            AS streak_end,
    MAX(login_date) - MIN(login_date) + 1      AS streak_days
FROM numbered
GROUP BY user_id, grp
ORDER BY user_id, streak_start;


-- =============================================================
-- APPROACH 2 — LAG to detect streak boundaries, then SUM to assign group IDs
-- =============================================================
-- Step 1: use LAG to check if the previous login was exactly 1 day before.
--         If not → this row is the start of a new streak (flag = 1).
-- Step 2: SUM(flag) OVER (PARTITION BY user_id ORDER BY login_date)
--         gives a cumulative count that increments at each streak start = group ID.
-- Step 3: GROUP BY user_id + group ID.

WITH flagged AS (
    SELECT
        user_id,
        login_date,
        CASE
            WHEN login_date - LAG(login_date) OVER (PARTITION BY user_id ORDER BY login_date) = 1
            THEN 0 ELSE 1
        END AS is_new_streak
    FROM user_logins
),
grouped AS (
    SELECT
        user_id,
        login_date,
        SUM(is_new_streak) OVER (PARTITION BY user_id ORDER BY login_date) AS streak_id
    FROM flagged
)
SELECT
    user_id,
    MIN(login_date)                       AS streak_start,
    MAX(login_date)                       AS streak_end,
    MAX(login_date) - MIN(login_date) + 1 AS streak_days
FROM grouped
GROUP BY user_id, streak_id
ORDER BY user_id, streak_start;

-- Note:
--   Approach 1 (ROW_NUMBER subtraction) is the classic gaps & islands trick — learn this.
--   Approach 2 (LAG + cumulative SUM flag) is more explicit and easier to understand.
--   Both return the same result.
--   streak_days = MAX - MIN + 1 because both endpoints are inclusive.
