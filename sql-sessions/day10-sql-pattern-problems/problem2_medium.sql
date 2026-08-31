-- =============================================================
-- Problem 2 Medium — Gaps and Islands
-- Pattern: ROW_NUMBER subtraction trick to find consecutive streaks
-- =============================================================
-- Question:
--   For each user, identify each consecutive login streak —
--   its start date, end date, and length in days.
--   Order by user_id, streak_start.
-- =============================================================

DROP TABLE IF EXISTS user_logins;

CREATE TABLE user_logins (
    login_id   SERIAL PRIMARY KEY,
    user_id    INT,
    login_date DATE
);

INSERT INTO user_logins (user_id, login_date) VALUES
    (1, '2024-01-01'),
    (1, '2024-01-02'),
    (1, '2024-01-03'),
    (1, '2024-01-07'),
    (1, '2024-01-08'),
    (1, '2024-01-15'),
    (2, '2024-01-01'),
    (2, '2024-01-04'),
    (2, '2024-01-05'),
    (2, '2024-01-06');

-- Expected output:
--
--   user_id | streak_start | streak_end | streak_days
--   --------+--------------+------------+------------
--         1 | 2024-01-01   | 2024-01-03 |           3
--         1 | 2024-01-07   | 2024-01-08 |           2
--         1 | 2024-01-15   | 2024-01-15 |           1
--         2 | 2024-01-01   | 2024-01-01 |           1
--         2 | 2024-01-04   | 2024-01-06 |           3
--
-- Hint: The gaps & islands trick —
--   login_date - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date)
--   gives the same value for all dates in a consecutive streak.
--   GROUP BY user_id and that difference, then MIN = start, MAX = end.

-- YOUR ANSWER:
