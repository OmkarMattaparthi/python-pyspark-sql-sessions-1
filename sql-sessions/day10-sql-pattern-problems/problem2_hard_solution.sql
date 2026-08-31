-- =============================================================
-- Problem 2 Hard Solution — Longest Login Streak per User
-- *** Instructor use only ***
-- =============================================================


-- =============================================================
-- APPROACH 1 — ROW_NUMBER subtraction trick to identify streaks
-- =============================================================
-- Consecutive calendar dates form a streak when (login_date - ROW_NUMBER) is constant.
-- Steps:
--   1. Deduplicate logins so each user has at most one row per day.
--   2. Assign row_number per user ordered by date.
--   3. Subtract row_number from login_date → a constant "grp" for each streak.
--   4. COUNT days per (user_id, grp) → streak length.
--   5. Find max streak per user; resolve ties by picking the most recent streak.

WITH daily AS (
    SELECT DISTINCT user_id, login_date
    FROM user_logins
),
numbered AS (
    SELECT
        user_id,
        login_date,
        login_date - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date))::INT AS grp
    FROM daily
),
streaks AS (
    SELECT
        user_id,
        grp,
        COUNT(*)         AS streak_len,
        MAX(login_date)  AS streak_end
    FROM numbered
    GROUP BY user_id, grp
),
best AS (
    SELECT
        user_id,
        streak_len AS longest_streak,
        streak_end AS most_recent_end,
        RANK() OVER (PARTITION BY user_id ORDER BY streak_len DESC, streak_end DESC) AS rnk
    FROM streaks
)
SELECT user_id, longest_streak, most_recent_end
FROM best
WHERE rnk = 1
ORDER BY user_id;


-- =============================================================
-- APPROACH 2 — LAG + cumulative flag to mark streak groups
-- =============================================================
-- Use LAG to check if the previous login is exactly 1 day before.
-- If not → new streak starts (flag=1). CUMULATIVE SUM of the flag gives a group id.

WITH daily AS (
    SELECT DISTINCT user_id, login_date FROM user_logins
),
flagged AS (
    SELECT
        user_id,
        login_date,
        CASE
            WHEN login_date - LAG(login_date) OVER (PARTITION BY user_id ORDER BY login_date) = 1
            THEN 0 ELSE 1
        END AS new_streak
    FROM daily
),
grouped AS (
    SELECT
        user_id,
        login_date,
        SUM(new_streak) OVER (PARTITION BY user_id ORDER BY login_date) AS grp
    FROM flagged
),
streaks AS (
    SELECT
        user_id,
        grp,
        COUNT(*)        AS streak_len,
        MAX(login_date) AS streak_end
    FROM grouped
    GROUP BY user_id, grp
),
best AS (
    SELECT
        user_id,
        streak_len AS longest_streak,
        streak_end AS most_recent_end,
        RANK() OVER (PARTITION BY user_id ORDER BY streak_len DESC, streak_end DESC) AS rnk
    FROM streaks
)
SELECT user_id, longest_streak, most_recent_end
FROM best
WHERE rnk = 1
ORDER BY user_id;

-- Note:
--   When two streaks share the same max length, ORDER BY streak_end DESC inside RANK
--   ensures the most recently ended streak wins — that's why RANK not ROW_NUMBER:
--   both approaches intentionally expose the tie resolution via the window ORDER BY.
