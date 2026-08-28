-- =============================================================
-- Problem 2 Solution — Calculate Special Bonus  (LeetCode #1873)
-- *** Instructor use only ***
-- =============================================================
-- Run problem2.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — CASE WHEN (reference solution, most readable)
-- =============================================================
-- Check both conditions in one CASE expression.
-- % 2 = 1 → odd id.  NOT LIKE 'M%' → name does not start with M.
-- Both must be true for the bonus; otherwise 0.

SELECT
    employee_id,
    CASE
        WHEN employee_id % 2 = 1 AND name NOT LIKE 'M%' THEN salary
        ELSE 0
    END AS bonus
FROM employees
ORDER BY employee_id;


-- =============================================================
-- APPROACH 2 — IIF-style with separate conditions in WHERE + UNION
-- =============================================================
-- Split into two groups: employees who get a bonus and those who don't.
-- UNION ALL combines them, then sort in the outer query.

SELECT employee_id, salary AS bonus
FROM employees
WHERE employee_id % 2 = 1 AND name NOT LIKE 'M%'

UNION ALL

SELECT employee_id, 0 AS bonus
FROM employees
WHERE NOT (employee_id % 2 = 1 AND name NOT LIKE 'M%')

ORDER BY employee_id;


-- =============================================================
-- APPROACH 3 — Multiply salary by a 0/1 flag (arithmetic trick)
-- =============================================================
-- Cast the boolean condition to an integer (1 = true, 0 = false).
-- Multiply salary by that flag — avoids CASE entirely.
-- PostgreSQL supports CAST(bool AS INT) or using CASE inline.

SELECT
    employee_id,
    salary * (CASE WHEN employee_id % 2 = 1 AND name NOT LIKE 'M%' THEN 1 ELSE 0 END) AS bonus
FROM employees
ORDER BY employee_id;

-- Note: Approach 1 is the cleanest and most interview-standard.
-- Approach 3 is a one-liner trick worth knowing — interviewers like it.
