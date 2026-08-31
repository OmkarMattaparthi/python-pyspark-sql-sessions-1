-- =============================================================
-- Problem 2 Hard — Gaps and Islands
-- Pattern: Find longest streak per user + rank users by streak length
-- =============================================================
-- Question:
--   For each user find their LONGEST consecutive login streak.
--   Return: user_id, longest_streak, streak_start, streak_end.
--   If a user has two streaks of equal max length, return the most recent one.
--   Order by longest_streak DESC, user_id ASC.
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
    (2, '2024-01-06'),
    (2, '2024-01-07'),
    (2, '2024-01-08'),
    (3, '2024-01-10'),
    (3, '2024-01-11'),
    (3, '2024-01-20'),
    (3, '2024-01-21');

-- Expected output:
--
--   user_id | longest_streak | streak_start | streak_end
--   --------+----------------+--------------+------------
--         2 |              5 | 2024-01-04   | 2024-01-08
--         1 |              3 | 2024-01-01   | 2024-01-03
--         3 |              2 | 2024-01-20   | 2024-01-21  ← most recent of two equal streaks
--
-- Note: user 3 has two streaks of length 2 (Jan 10-11 and Jan 20-21).
--       Return the most recent one (Jan 20-21).

-- YOUR ANSWER:
