-- =============================================================
-- Problem 6 Solution — Employees Whose Manager Left  (LeetCode #1978)
-- *** Instructor use only ***
-- =============================================================
-- Run problem6.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — NOT IN subquery (most readable)
-- =============================================================
-- Filter employees with salary < 30000 AND a manager_id set.
-- Check that the manager_id is NOT among current emp_ids in the table.

SELECT emp_id AS employee_id
FROM employees
WHERE salary < 30000
  AND manager_id IS NOT NULL
  AND manager_id NOT IN (SELECT emp_id FROM employees)
ORDER BY employee_id;


-- =============================================================
-- APPROACH 2 — LEFT JOIN with NULL check (anti-join pattern)
-- =============================================================
-- LEFT JOIN the table to itself: employee's manager_id → manager's emp_id.
-- Where the join finds no match (m.emp_id IS NULL) → manager left.
-- Also filter salary < 30000 and manager_id IS NOT NULL.

SELECT e.emp_id AS employee_id
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
WHERE e.salary < 30000
  AND e.manager_id IS NOT NULL
  AND m.emp_id IS NULL
ORDER BY employee_id;


-- =============================================================
-- APPROACH 3 — NOT EXISTS correlated subquery
-- =============================================================
-- For each employee, check that no row in the table has
-- emp_id = that employee's manager_id.
-- Safer than NOT IN when the subquery could return NULLs
-- (NOT IN with NULLs returns no rows — NOT EXISTS handles NULLs correctly).

SELECT emp_id AS employee_id
FROM employees e
WHERE salary < 30000
  AND manager_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM employees m WHERE m.emp_id = e.manager_id
  )
ORDER BY employee_id;

-- Note:
--   Approach 1 (NOT IN) is the most concise — fine here because emp_id has no NULLs.
--   Approach 2 (LEFT JOIN anti-join) is the most common pattern in production queries.
--   Approach 3 (NOT EXISTS) is the safest — never breaks on NULLs in the subquery.
