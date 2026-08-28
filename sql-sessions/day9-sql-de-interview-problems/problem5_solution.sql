-- =============================================================
-- Problem 5 Solution — Find Missing IDs  (LeetCode #1613)
-- *** Instructor use only ***
-- =============================================================
-- Run problem5.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — generate_series + EXCEPT (cleanest in PostgreSQL)
-- =============================================================
-- generate_series produces every integer from 1 to MAX(customer_id).
-- EXCEPT removes the IDs that already exist in the table.
-- What remains are the missing IDs.

SELECT generate_series(1, (SELECT MAX(customer_id) FROM customers)) AS ids
EXCEPT
SELECT customer_id FROM customers
ORDER BY ids;


-- =============================================================
-- APPROACH 2 — generate_series + LEFT JOIN with NULL filter
-- =============================================================
-- Same spine generation but uses LEFT JOIN instead of EXCEPT.
-- Rows where c.customer_id IS NULL → ID not in the table = missing.

SELECT s.ids
FROM generate_series(1, (SELECT MAX(customer_id) FROM customers)) AS s(ids)
LEFT JOIN customers c ON c.customer_id = s.ids
WHERE c.customer_id IS NULL
ORDER BY s.ids;


-- =============================================================
-- APPROACH 3 — Recursive CTE (works in all SQL dialects)
-- =============================================================
-- Recursively counts from 1 up to MAX(customer_id).
-- Filter out IDs that exist in the table using NOT IN.
-- Useful when generate_series is not available (MySQL, SQL Server).

WITH RECURSIVE all_ids AS (
    SELECT 1 AS ids
    UNION ALL
    SELECT ids + 1
    FROM all_ids
    WHERE ids < (SELECT MAX(customer_id) FROM customers)
)
SELECT ids
FROM all_ids
WHERE ids NOT IN (SELECT customer_id FROM customers)
ORDER BY ids;

-- Note:
--   Approach 1 is the most concise — preferred in PostgreSQL interviews.
--   Approach 2 is the standard LEFT JOIN anti-pattern — works everywhere.
--   Approach 3 (recursive CTE) is dialect-agnostic — good to know for non-PG DBs.
