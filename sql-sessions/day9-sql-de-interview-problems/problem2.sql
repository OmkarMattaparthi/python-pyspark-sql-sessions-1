-- =============================================================
-- Problem 2 — Calculate Special Bonus  (LeetCode #1873)
-- DATA ENGINEER SQL INTERVIEW CHALLENGE
-- =============================================================
-- Question:
--   Calculate the bonus of each employee.
--   Bonus = 100% of salary IF:
--     - employee_id is an ODD number  AND
--     - name does NOT start with 'M'
--   Otherwise bonus = 0.
--   Order by employee_id.
-- =============================================================

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id  INT PRIMARY KEY,
    name         VARCHAR(50),
    salary       INT
);

INSERT INTO employees (employee_id, name, salary) VALUES
    (2, 'Meir',    3000),
    (3, 'Michael', 3800),
    (7, 'Addilyn', 7400),
    (8, 'Juan',    6100),
    (9, 'Kannon',  7700);

-- Expected output:
--
--   employee_id | bonus
--   ------------+-------
--             2 |     0    (even id)
--             3 |     0    (odd id BUT name starts with 'M')
--             7 |  7400    (odd id AND name does not start with 'M')
--             8 |     0    (even id)
--             9 |  7700    (odd id AND name does not start with 'M')

-- YOUR ANSWER:
