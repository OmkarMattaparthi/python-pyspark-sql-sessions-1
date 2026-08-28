-- =============================================================
-- Problem 3 — Group Employees Same Salary  (LeetCode #1917)
-- DATA ENGINEER SQL INTERVIEW CHALLENGE
-- =============================================================
-- Question:
--   Write a query to get the employee_id, name, salary, and
--   team_id (dense rank by salary) of employees who share
--   the same salary with at least one other employee.
--
-- Rules:
--   - Only include salaries shared by >= 2 employees.
--   - team_id is assigned using DENSE_RANK ordered by salary ASC.
--   - Order by team_id, then employee_id.
-- =============================================================

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id  INT PRIMARY KEY,
    name         VARCHAR(50),
    salary       INT
);

INSERT INTO employees (employee_id, name, salary) VALUES
    (2, 'Meir',    3000),
    (3, 'Michael', 3000),
    (7, 'Addilyn', 7400),
    (8, 'Juan',    6100),
    (9, 'Kannon',  7700),
    (1, 'Bob',     7400);

-- Expected output:
--
--   employee_id | name    | salary | team_id
--   ------------+---------+--------+---------
--             2 | Meir    |   3000 |       1
--             3 | Michael |   3000 |       1
--             1 | Bob     |   7400 |       2
--             7 | Addilyn |   7400 |       2
--
-- Note: Juan (6100) and Kannon (7700) are excluded — unique salaries.

-- YOUR ANSWER:
