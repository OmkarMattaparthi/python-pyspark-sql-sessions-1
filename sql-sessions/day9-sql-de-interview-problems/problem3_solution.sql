-- =============================================================
-- Problem 3 Solution — Group Employees Same Salary  (LeetCode #1917)
-- *** Instructor use only ***
-- =============================================================
-- Run problem3.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — CTE chain: filter shared salaries, then rank
-- =============================================================
-- Step 1 (Counts CTE): find salaries shared by >= 2 employees.
-- Step 2 (Teams CTE): assign team_id using DENSE_RANK on those salaries.
-- Step 3: JOIN employees back to Teams to get final output.
-- This is the reference solution pattern.

WITH counts AS (
    SELECT salary
    FROM employees
    GROUP BY salary
    HAVING COUNT(*) >= 2
),
teams AS (
    SELECT salary,
           DENSE_RANK() OVER (ORDER BY salary) AS team_id
    FROM counts
)
SELECT
    e.employee_id,
    e.name,
    e.salary,
    t.team_id
FROM employees e
JOIN teams t ON e.salary = t.salary
ORDER BY t.team_id, e.employee_id;


-- =============================================================
-- APPROACH 2 — Subquery in WHERE + window function
-- =============================================================
-- Filter rows where the salary appears more than once using a subquery.
-- Then assign DENSE_RANK in a wrapping query.
-- Avoids an explicit CTE but does the same work.

SELECT
    employee_id,
    name,
    salary,
    DENSE_RANK() OVER (ORDER BY salary) AS team_id
FROM employees
WHERE salary IN (
    SELECT salary
    FROM employees
    GROUP BY salary
    HAVING COUNT(*) >= 2
)
ORDER BY team_id, employee_id;


-- =============================================================
-- APPROACH 3 — Self JOIN to find shared salaries
-- =============================================================
-- Join the table to itself: for each employee, find at least one
-- OTHER employee with the same salary (e1.employee_id <> e2.employee_id).
-- DISTINCT removes duplicates that the self-join produces.
-- Then wrap to assign DENSE_RANK.

WITH shared AS (
    SELECT DISTINCT e1.employee_id, e1.name, e1.salary
    FROM employees e1
    JOIN employees e2
        ON e1.salary = e2.salary
       AND e1.employee_id <> e2.employee_id
)
SELECT
    employee_id,
    name,
    salary,
    DENSE_RANK() OVER (ORDER BY salary) AS team_id
FROM shared
ORDER BY team_id, employee_id;

-- Note:
--   Approach 1 is the cleanest — preferred in interviews.
--   Approach 2 is more concise but nests a subquery.
--   Approach 3 shows the self-join technique — good to know but verbose.
--   All three return the same 4 rows.
