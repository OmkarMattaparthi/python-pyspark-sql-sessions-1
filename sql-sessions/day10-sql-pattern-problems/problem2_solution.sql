-- =============================================================
-- Problem 2 Solution — Gaps and Islands (missing dates)
-- *** Instructor use only ***
-- =============================================================
-- Run problem2.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — generate_series + EXCEPT (cleanest in PostgreSQL)
-- =============================================================
-- Generate every date in the range, then subtract dates that exist.

SELECT gs::DATE AS missing_date
FROM generate_series('2024-01-01'::DATE, '2024-01-10'::DATE, '1 day') AS gs
EXCEPT
SELECT login_date FROM user_logins WHERE user_id = 1
ORDER BY missing_date;


-- =============================================================
-- APPROACH 2 — generate_series + LEFT JOIN with NULL filter
-- =============================================================
-- Left join the date spine to actual logins.
-- Rows where login_date IS NULL = dates with no login.

SELECT gs::DATE AS missing_date
FROM generate_series('2024-01-01'::DATE, '2024-01-10'::DATE, '1 day') AS gs
LEFT JOIN user_logins ul
       ON ul.login_date = gs::DATE AND ul.user_id = 1
WHERE ul.login_date IS NULL
ORDER BY missing_date;


-- =============================================================
-- APPROACH 3 — NOT EXISTS correlated subquery
-- =============================================================
-- For each date in the range, check that no login record exists.

SELECT gs::DATE AS missing_date
FROM generate_series('2024-01-01'::DATE, '2024-01-10'::DATE, '1 day') AS gs
WHERE NOT EXISTS (
    SELECT 1
    FROM user_logins ul
    WHERE ul.login_date = gs::DATE AND ul.user_id = 1
)
ORDER BY missing_date;

-- Note:
--   Approach 1 (EXCEPT) is the most concise and readable.
--   Approach 2 (LEFT JOIN + IS NULL) is the standard anti-join pattern.
--   Approach 3 (NOT EXISTS) is the safest — handles NULLs correctly.
