-- =============================================================
-- Problem 6 — Employees Whose Manager Left the Company  (LeetCode #1978)
-- DATA ENGINEER SQL INTERVIEW CHALLENGE
-- =============================================================
-- Question:
--   Find the IDs of employees whose salary is strictly less than
--   $30,000 AND whose manager has left the company.
--
-- Rules:
--   - A manager has "left" if their emp_id no longer exists in the table.
--   - Employees with manager_id = NULL are top-level (no manager).
--   - Order by employee_id ascending.
-- =============================================================

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    manager_id  INT,
    salary      INT
);

INSERT INTO employees (emp_id, name, manager_id, salary) VALUES
    (3,  'Mila',      9,    60301),
    (12, 'Antonella', NULL, 31000),
    (13, 'Emery',     NULL, 67084),
    (1,  'Kalel',     11,   21241),
    (9,  'Mikaela',   NULL, 50937),
    (11, 'Joziah',    6,    28485);

-- Expected output:
--
--   employee_id
--   -----------
--            11
--
-- Explanation:
--   emp 1  (Kalel,  salary 21241, manager 11) — manager 11 EXISTS in table → excluded
--   emp 11 (Joziah, salary 28485, manager  6) — manager 6 MISSING from table → included
--   All others: salary >= 30000 or no manager → excluded

-- YOUR ANSWER:
