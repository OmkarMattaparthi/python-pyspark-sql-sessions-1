-- =============================================================
-- Problem 2 — Gaps and Islands
-- Pattern: generate_series + EXCEPT / LEFT JOIN to find missing dates
-- =============================================================
-- Question:
--   For user_id = 1, find all dates between 2024-01-01 and 2024-01-10
--   where the user did NOT log in.
--   Return: missing_date ordered ascending.
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
--   missing_date
--   ------------
--   2024-01-04
--   2024-01-05
--   2024-01-06
--   2024-01-09
--   2024-01-10

-- YOUR ANSWER:
