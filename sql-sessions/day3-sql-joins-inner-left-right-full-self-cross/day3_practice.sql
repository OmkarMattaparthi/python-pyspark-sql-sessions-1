-- =============================================================
-- Day 3 Practice — JOINs: INNER, LEFT, RIGHT, FULL, SELF, CROSS
-- =============================================================
-- Standalone: no dependency on day1_practice.sql.
-- Run this file top-to-bottom on any clean PostgreSQL database.
--
-- Tables created here:
--   company.departments       — dept_id, dept_name, location
--   company.employees         — emp_id, first_name, last_name, email, salary, dept_id, hire_date, status, manager_id
--   company.projects          — project_id, project_name, dept_id
--   company.employee_projects — emp_id, project_id, role


-- ===============================================================
-- DATA SETUP — schema + purposeful data for all JOIN demonstrations
-- ===============================================================
--
-- What each JOIN will show with this data:
--   INNER JOIN       → 6 of 8 employees (Grace + Henry have no dept → excluded)
--   LEFT JOIN        → all 8 employees; Grace and Henry get NULL for dept columns
--   RIGHT JOIN       → all 5 depts; Operations and Legal get NULL for employee columns
--   FULL OUTER JOIN  → all 8 employees + 2 empty depts visible together
--   SELF JOIN        → org chart — Alice is CEO, Bob+Carol report to Alice, etc.
--   CROSS JOIN       → 8 employees × 5 departments = 40 rows
--   Multi-table JOIN → Alice+Bob appear TWICE (2 projects each) → row-multiplication demo
-- ---------------------------------------------------------------


-- Step 1: Drop and recreate schema cleanly
DROP SCHEMA IF EXISTS company CASCADE;
CREATE SCHEMA company;


-- Step 2: Departments — 5 rows, 2 intentionally empty
--
--   dept_id | dept_name   | location
--   --------+-------------+-----------
--      1    | Engineering | Pune          ← has employees
--      2    | Marketing   | Mumbai        ← has employees
--      3    | HR          | Bangalore     ← has employees
--      4    | Operations  | Delhi         ← EMPTY → visible in LEFT/RIGHT/FULL JOIN
--      5    | Legal       | Chennai       ← EMPTY → visible in LEFT/RIGHT/FULL JOIN

CREATE TABLE company.departments (
    dept_id   SERIAL       PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    location  VARCHAR(100)
);

INSERT INTO company.departments (dept_name, location) VALUES
    ('Engineering', 'Pune'),       -- dept_id = 1
    ('Marketing',   'Mumbai'),     -- dept_id = 2
    ('HR',          'Bangalore'),  -- dept_id = 3
    ('Operations',  'Delhi'),      -- dept_id = 4  ← EMPTY
    ('Legal',       'Chennai');    -- dept_id = 5  ← EMPTY


-- Step 3: Employees — 8 rows with deliberate variety
--
--   emp_id | first_name | dept_id | salary | note
--   -------+------------+---------+--------+----------------------------------------
--      1   | Alice      |    1    |  95000 | Engineering — CEO, no manager
--      2   | Bob        |    1    |  82000 | Engineering — reports to Alice
--      3   | Carol      |    2    |  78000 | Marketing   — reports to Alice
--      4   | David      |    2    |  67000 | Marketing   — reports to Bob
--      5   | Eve        |    3    |  71000 | HR          — reports to Bob
--      6   | Frank      |    3    |  59000 | HR inactive — reports to Bob (salary < manager)
--      7   | Grace      |  NULL   |  54000 | NO dept     → anti-join demo
--      8   | Henry      |  NULL   |  48000 | NO dept     → anti-join demo

CREATE TABLE company.employees (
    emp_id     SERIAL       PRIMARY KEY,
    first_name VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL,
    email      VARCHAR(100) UNIQUE NOT NULL,
    salary     NUMERIC(10,2),
    dept_id    INT          REFERENCES company.departments(dept_id),
    hire_date  DATE,
    status     VARCHAR(20)  DEFAULT 'active',
    manager_id INT          REFERENCES company.employees(emp_id)
);

INSERT INTO company.employees
    (first_name, last_name, email,                          salary, dept_id, hire_date,    status)
VALUES
    ('Alice', 'Adams',  'alice.adams@company.com',   95000,  1,    '2019-03-01', 'active'),   -- emp_id = 1
    ('Bob',   'Brown',  'bob.brown@company.com',     82000,  1,    '2020-06-15', 'active'),   -- emp_id = 2
    ('Carol', 'Clark',  'carol.clark@company.com',   78000,  2,    '2021-01-10', 'active'),   -- emp_id = 3
    ('David', 'Davis',  'david.davis@company.com',   67000,  2,    '2021-09-20', 'active'),   -- emp_id = 4
    ('Eve',   'Evans',  'eve.evans@company.com',     71000,  3,    '2022-04-05', 'active'),   -- emp_id = 5
    ('Frank', 'Foster', 'frank.foster@company.com',  59000,  3,    '2022-11-18', 'inactive'), -- emp_id = 6
    ('Grace', 'Green',  'grace.green@company.com',   54000,  NULL, '2023-02-28', 'active'),   -- emp_id = 7 ← NULL dept
    ('Henry', 'Harris', 'henry.harris@company.com',  48000,  NULL, '2023-07-01', 'active');   -- emp_id = 8 ← NULL dept

-- Org chart (self-referencing manager assignments):
--   Alice (1)  ← CEO, no manager
--   ├── Bob   (2)  reports to Alice
--   │   ├── David (4)  reports to Bob (67k < Bob's 82k)
--   │   ├── Eve   (5)  reports to Bob (71k < Bob's 82k)
--   │   └── Frank (6)  reports to Bob (59k < Bob's 82k) ← earns less than manager
--   └── Carol (3)  reports to Alice
--       ├── Grace (7)  reports to Carol (no dept, but has a manager)
--       └── Henry (8)  reports to Carol

UPDATE company.employees SET manager_id = NULL WHERE emp_id = 1;          -- Alice: CEO
UPDATE company.employees SET manager_id = 1    WHERE emp_id IN (2, 3);    -- Bob, Carol → Alice
UPDATE company.employees SET manager_id = 2    WHERE emp_id IN (4, 5, 6); -- David, Eve, Frank → Bob
UPDATE company.employees SET manager_id = 3    WHERE emp_id IN (7, 8);    -- Grace, Henry → Carol


-- Step 4: Projects — 4 rows, two belong to Engineering (creates row-multiplication)
--
--   project_id | project_name          | dept_id
--   -----------+-----------------------+--------
--       1      | Data Platform Rebuild |    1    Engineering
--       2      | CRM Migration         |    2    Marketing
--       3      | Payroll Upgrade       |    3    HR
--       4      | Cloud Infrastructure  |    1    Engineering (second Eng project)

CREATE TABLE company.projects (
    project_id   SERIAL       PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INT          REFERENCES company.departments(dept_id)
);

INSERT INTO company.projects (project_name, dept_id) VALUES
    ('Data Platform Rebuild', 1),   -- project_id = 1
    ('CRM Migration',         2),   -- project_id = 2
    ('Payroll Upgrade',       3),   -- project_id = 3
    ('Cloud Infrastructure',  1);   -- project_id = 4


-- Step 5: Employee-project assignments
--
--   emp_id | project_id | role              | note
--   -------+------------+-------------------+----------------------------------
--     1    |     1      | Lead Engineer     | Alice on Data Platform
--     1    |     4      | Technical Advisor | Alice on Cloud Infra  ← DUPLICATE ROW in JOIN
--     2    |     1      | Developer         | Bob on Data Platform
--     2    |     2      | Analyst           | Bob on CRM Migration  ← DUPLICATE ROW in JOIN
--     3    |     2      | Project Manager   | Carol on CRM Migration
--     6    |     3      | HR Analyst        | Frank on Payroll Upgrade
--   David(4), Eve(5), Grace(7), Henry(8) → 0 projects (visible in LEFT JOIN as 'No Project')

CREATE TABLE company.employee_projects (
    emp_id     INT         REFERENCES company.employees(emp_id),
    project_id INT         REFERENCES company.projects(project_id),
    role       VARCHAR(50),
    PRIMARY KEY (emp_id, project_id)
);

INSERT INTO company.employee_projects (emp_id, project_id, role) VALUES
    (1, 1, 'Lead Engineer'),
    (1, 4, 'Technical Advisor'),
    (2, 1, 'Developer'),
    (2, 2, 'Analyst'),
    (3, 2, 'Project Manager'),
    (6, 3, 'HR Analyst');


-- Sanity check — verify counts before running queries
SELECT 'departments'      AS tbl, COUNT(*) AS rows FROM company.departments
UNION ALL
SELECT 'employees',                COUNT(*)         FROM company.employees
UNION ALL
SELECT 'projects',                 COUNT(*)         FROM company.projects
UNION ALL
SELECT 'employee_projects',        COUNT(*)         FROM company.employee_projects;
-- Expected: departments=5, employees=8, projects=4, employee_projects=6


-- ===============================================================
-- SECTION 1: INNER JOIN
-- ===============================================================
--
-- Returns only rows that have a match in BOTH tables.
-- Grace (NULL dept) and Henry (NULL dept) are excluded from results.
-- Operations and Legal (no employees) are also excluded.
-- ---------------------------------------------------------------


-- Basic INNER JOIN: employees with their department name.
-- Grace (emp_id=7) and Henry (emp_id=8) have dept_id=NULL → no match → excluded.
-- Result: 6 rows (Alice, Bob, Carol, David, Eve, Frank).
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    d.dept_name,
    e.salary
FROM company.employees   e
INNER JOIN company.departments d ON e.dept_id = d.dept_id;

-- Plain JOIN is identical to INNER JOIN
SELECT
    e.emp_id,
    e.first_name,
    d.dept_name
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id;


-- INNER JOIN + WHERE filter — only Pune and Mumbai employees
SELECT
    e.first_name,
    e.last_name,
    d.dept_name,
    d.location
FROM company.employees   e
JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.location IN ('Pune', 'Mumbai');


-- INNER JOIN + GROUP BY — headcount per department (empty depts excluded)
SELECT
    d.dept_name,
    COUNT(e.emp_id)         AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    SUM(e.salary)           AS total_payroll
FROM company.departments d
JOIN company.employees   e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY headcount DESC;


-- INNER JOIN + ORDER BY + LIMIT — top 3 earners with dept
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name,
    e.salary
FROM company.employees   e
JOIN company.departments d ON e.dept_id = d.dept_id
ORDER BY e.salary DESC
LIMIT 3;


-- ===============================================================
-- SECTION 2: LEFT JOIN
-- ===============================================================
--
-- Returns ALL rows from the left (FROM) table.
-- Right-side columns are NULL where no match exists.
-- Grace and Henry (NULL dept_id) still appear — with NULL for dept columns.
-- ---------------------------------------------------------------


-- All 8 employees; Grace and Henry get NULL for dept_name and dept_id.
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    d.dept_name,  -- NULL for Grace and Henry
    d.dept_id     -- NULL for Grace and Henry
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id;


-- COALESCE replaces NULL with 'No Department' for display
SELECT
    e.emp_id,
    e.first_name,
    COALESCE(d.dept_name, 'No Department') AS dept_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id;


-- All 5 departments with headcount (Operations=0, Legal=0 appear)
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS headcount   -- COUNT on FK column: NULLs not counted → 0 for empty depts
FROM company.departments d
LEFT JOIN company.employees  e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY headcount DESC;


-- ANTI-JOIN: employees with NO department (Grace and Henry)
SELECT
    e.emp_id,
    e.first_name,
    e.last_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;   -- right side is NULL → no match found → Grace and Henry


-- ANTI-JOIN: departments with NO employees (Operations and Legal)
SELECT
    d.dept_id,
    d.dept_name
FROM company.departments d
LEFT JOIN company.employees  e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;    -- right side is NULL → no employees in this dept


-- ON vs WHERE — critical difference for LEFT JOIN
-- WRONG: WHERE on right-side column turns LEFT JOIN into INNER JOIN
-- Grace and Henry have d.dept_name = NULL; WHERE d.dept_name = 'Engineering' drops them
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering';   -- only 2 rows returned — Grace+Henry lost!

-- CORRECT: filter inside ON clause — all 8 employees appear; non-Engineering get NULL dept_name
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d
    ON  e.dept_id   = d.dept_id
    AND d.dept_name = 'Engineering';   -- 8 rows returned — Grace+Henry still present


-- ===============================================================
-- SECTION 3: RIGHT JOIN
-- ===============================================================
--
-- Returns ALL rows from the right (JOIN) table.
-- Left-side columns are NULL where no match exists.
-- All 5 departments appear; Operations and Legal show NULL for employee columns.
-- Rule: FROM a RIGHT JOIN b  ≡  FROM b LEFT JOIN a
-- ---------------------------------------------------------------


-- All 5 departments; Operations and Legal show NULL for first_name
SELECT
    e.first_name,    -- NULL for Operations and Legal
    d.dept_id,
    d.dept_name
FROM company.employees   e
RIGHT JOIN company.departments d ON e.dept_id = d.dept_id;


-- Same result using LEFT JOIN (preferred style — swap table order)
SELECT
    d.dept_id,
    d.dept_name,
    e.first_name
FROM company.departments d
LEFT JOIN company.employees  e ON d.dept_id = e.dept_id;


-- RIGHT JOIN with aggregation — headcount per dept including empty depts
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS headcount
FROM company.employees   e
RIGHT JOIN company.departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY headcount DESC;


-- ===============================================================
-- SECTION 4: FULL OUTER JOIN
-- ===============================================================
--
-- Returns ALL rows from BOTH tables.
-- Unmatched left rows → right columns are NULL.
-- Unmatched right rows → left columns are NULL.
-- Use for data reconciliation between two sources.
-- ---------------------------------------------------------------


-- All 8 employees + all 5 departments in one result set.
-- Grace and Henry: dept_id and dept_name are NULL.
-- Operations and Legal: emp_id and first_name are NULL.
SELECT
    e.emp_id,
    e.first_name,
    d.dept_id,
    d.dept_name
FROM company.employees   e
FULL OUTER JOIN company.departments d ON e.dept_id = d.dept_id
ORDER BY e.emp_id NULLS LAST;


-- Find ALL unmatched rows from either side at once
SELECT
    e.emp_id,
    e.first_name,
    d.dept_id,
    d.dept_name,
    CASE
        WHEN e.emp_id  IS NULL THEN 'Department has no employees'
        WHEN d.dept_id IS NULL THEN 'Employee has no department'
    END AS issue
FROM company.employees   e
FULL OUTER JOIN company.departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL
   OR d.dept_id IS NULL;


-- Data reconciliation pattern: compare staging vs production using FULL OUTER JOIN.
-- staging  → employees 1, 2, and a new emp_id=99 (INSERT candidate)
-- production → employees 1, 2, 3  (emp 3 not in staging = DELETE candidate)
-- emp 1 salary differs between staging and production → UPDATE candidate
WITH staging AS (
    SELECT emp_id, first_name, ROUND(salary * 1.10, 2) AS salary
    FROM company.employees
    WHERE emp_id IN (1, 2)
    UNION ALL
    SELECT 99, 'NewHire', 55000.00   -- simulated new employee not yet in production
),
production AS (
    SELECT emp_id, first_name, salary
    FROM company.employees
    WHERE emp_id IN (1, 2, 3)
)
SELECT
    COALESCE(s.emp_id,     p.emp_id)     AS emp_id,
    COALESCE(s.first_name, p.first_name) AS first_name,
    s.salary                             AS staging_salary,
    p.salary                             AS prod_salary,
    CASE
        WHEN p.emp_id IS NULL   THEN 'INSERT'    -- in staging, not in production
        WHEN s.emp_id IS NULL   THEN 'DELETE'    -- in production, not in staging
        WHEN s.salary <> p.salary THEN 'UPDATE'  -- in both but salary changed
        ELSE                         'NO CHANGE'
    END AS action
FROM staging    s
FULL OUTER JOIN production p ON s.emp_id = p.emp_id;


-- ===============================================================
-- SECTION 5: SELF JOIN
-- ===============================================================
--
-- A table joined to itself using two different aliases.
-- Use LEFT JOIN so top-level rows (Alice = CEO, manager_id=NULL) still appear.
-- ---------------------------------------------------------------


-- Each employee with their manager's name.
-- Alice (emp_id=1, manager_id=NULL) → manager columns are NULL (she's the CEO).
-- Bob (emp_id=2, manager_id=1) → manager = Alice.
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name   AS employee,
    m.first_name || ' ' || m.last_name   AS manager        -- NULL for Alice
FROM company.employees e
LEFT JOIN company.employees m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;


-- Find employees who earn MORE than their own manager.
-- Alice has no manager so she's excluded (INNER JOIN).
-- David (67k) < Bob (82k) → not returned. Eve (71k) < Bob → not returned. Frank (59k) < Bob → not returned.
-- Result: 0 rows with current data — intentional, shows the query works correctly.
SELECT
    e.first_name  AS employee,
    e.salary      AS employee_salary,
    m.first_name  AS manager,
    m.salary      AS manager_salary,
    e.salary - m.salary AS difference
FROM company.employees e
JOIN company.employees m ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;


-- Pairs of employees in the same department (no duplicates, no self-pairs).
-- a.emp_id < b.emp_id: ensures (Alice,Bob) appears but NOT also (Bob,Alice).
SELECT
    a.first_name AS employee_1,
    b.first_name AS employee_2,
    a.dept_id
FROM company.employees a
JOIN company.employees b
    ON  a.dept_id = b.dept_id
    AND a.emp_id  < b.emp_id
ORDER BY a.dept_id, a.emp_id;


-- ===============================================================
-- SECTION 6: CROSS JOIN
-- ===============================================================
--
-- Cartesian product — every row of A paired with every row of B.
-- No ON condition. Rows = rows_in_A × rows_in_B.
-- ---------------------------------------------------------------


-- Every employee paired with every department: 8 × 5 = 40 rows
SELECT
    e.first_name AS employee,
    d.dept_name  AS department
FROM company.employees   e
CROSS JOIN company.departments d
ORDER BY e.first_name, d.dept_name;


-- Verify the math
SELECT
    (SELECT COUNT(*) FROM company.employees)    AS emp_count,
    (SELECT COUNT(*) FROM company.departments)  AS dept_count,
    (SELECT COUNT(*) FROM company.employees)
    * (SELECT COUNT(*) FROM company.departments) AS expected_cross_join_rows;


-- Practical use: quarter × department reporting scaffold.
-- Every quarter/dept combination exists even if no data — good for time-series reports.
SELECT
    q.quarter,
    d.dept_name
FROM (VALUES ('Q1'), ('Q2'), ('Q3'), ('Q4')) AS q(quarter)
CROSS JOIN company.departments d
ORDER BY q.quarter, d.dept_name;


-- ===============================================================
-- SECTION 7: MULTIPLE JOINs — THREE OR MORE TABLES
-- ===============================================================
--
-- Chain as many JOINs as needed; each adds one more table to the result.
-- Alice and Bob each have 2 projects → they appear TWICE after joining to employee_projects.
-- ---------------------------------------------------------------


-- Three-table INNER JOIN: employees → departments → projects.
-- Only Alice, Bob, Carol, Frank qualify (assigned to a project AND have a dept).
-- Alice appears TWICE (2 projects), Bob appears TWICE (2 projects).
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name,
    p.project_name,
    ep.role
FROM company.employees        e
JOIN company.departments       d  ON e.dept_id     = d.dept_id
JOIN company.employee_projects ep ON e.emp_id      = ep.emp_id
JOIN company.projects          p  ON ep.project_id = p.project_id
ORDER BY e.last_name, p.project_name;


-- Mixed INNER + LEFT JOIN: all employees with their dept and projects (if any).
-- INNER JOIN to departments: employees must have a dept (Grace and Henry excluded).
-- LEFT JOIN to projects: David, Eve, Frank show 'No Project'.
SELECT
    e.first_name || ' ' || e.last_name       AS full_name,
    d.dept_name,
    COALESCE(p.project_name, 'No Project')   AS project_name,
    ep.role
FROM company.employees        e
JOIN company.departments       d  ON e.dept_id     = d.dept_id
LEFT JOIN company.employee_projects ep ON e.emp_id      = ep.emp_id
LEFT JOIN company.projects          p  ON ep.project_id = p.project_id
ORDER BY e.last_name, p.project_name NULLS LAST;


-- Count projects per employee including 0-project employees.
-- Alice=2, Bob=2, Carol=1, Frank=1, David=0, Eve=0, Grace=0, Henry=0.
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    COUNT(ep.project_id)               AS project_count
FROM company.employees        e
LEFT JOIN company.employee_projects ep ON e.emp_id = ep.emp_id
GROUP BY e.emp_id, e.first_name, e.last_name
ORDER BY project_count DESC, e.first_name;


-- ===============================================================
-- SECTION 8: JOIN + AGGREGATION + CASE
-- ===============================================================


-- Per-department stats including empty departments, with payroll status label.
SELECT
    d.dept_name,
    COUNT(e.emp_id)                          AS headcount,
    ROUND(COALESCE(AVG(e.salary), 0), 2)     AS avg_salary,
    COALESCE(SUM(e.salary), 0)               AS total_payroll,
    CASE
        WHEN SUM(e.salary) > 200000 THEN 'High'
        WHEN SUM(e.salary) > 100000 THEN 'Medium'
        WHEN SUM(e.salary) > 0      THEN 'Low'
        ELSE                             'No Payroll'
    END                                      AS payroll_status
FROM company.departments d
LEFT JOIN company.employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY total_payroll DESC NULLS LAST;


-- Each employee's salary vs their department average (subquery join).
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name,
    e.salary,
    ROUND(dept_avg.avg_salary, 2)       AS dept_avg_salary,
    CASE
        WHEN e.salary > dept_avg.avg_salary THEN 'Above average'
        WHEN e.salary < dept_avg.avg_salary THEN 'Below average'
        ELSE                                     'At average'
    END                                 AS salary_vs_avg
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
JOIN (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM company.employees
    GROUP BY dept_id
) dept_avg ON e.dept_id = dept_avg.dept_id
ORDER BY d.dept_name, e.salary DESC;


-- ===============================================================
-- SECTION 9: COMMON MISTAKES — DEMONSTRATED AND FIXED
-- ===============================================================


-- MISTAKE 1: COUNT(*) vs COUNT(col) after LEFT JOIN
-- Operations and Legal have 0 employees but LEFT JOIN produces one NULL row per dept.
-- COUNT(*) counts that NULL row as 1 → wrong. COUNT(e.emp_id) returns 0 → correct.
SELECT
    d.dept_name,
    COUNT(*)        AS wrong_headcount,    -- Operations=1, Legal=1 — WRONG
    COUNT(e.emp_id) AS correct_headcount   -- Operations=0, Legal=0 — CORRECT
FROM company.departments d
LEFT JOIN company.employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY d.dept_name;


-- MISTAKE 2: WHERE on right-side column silently converts LEFT JOIN to INNER JOIN
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering';    -- BUG: Grace and Henry dropped (their d.dept_name is NULL)

-- Fixed: put the filter in the ON clause — all 8 employees remain
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d
    ON  e.dept_id   = d.dept_id
    AND d.dept_name = 'Engineering';   -- non-Engineering employees get NULL dept_name


-- MISTAKE 3: Implicit CROSS JOIN from old-style comma syntax
SELECT * FROM company.employees, company.departments;   -- 8 × 5 = 40 rows — accidental!

-- Fixed: always use explicit JOIN ... ON
SELECT * FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id;


-- MISTAKE 4: Row multiplication from one-to-many JOIN
-- employees has 8 rows. Alice and Bob each have 2 project assignments.
-- After LEFT JOIN to employee_projects: result has 10 rows (8 + 2 extra for Alice and Bob).
SELECT COUNT(*) AS employee_rows      FROM company.employees;
SELECT COUNT(*) AS after_project_join FROM company.employees e
LEFT JOIN company.employee_projects ep ON e.emp_id = ep.emp_id;
-- employee_rows=8, after_project_join=10 → row multiplication confirmed


-- ---------------------------------------------------------------
-- CLEANUP (uncomment to reset completely)
-- ---------------------------------------------------------------
-- DROP SCHEMA IF EXISTS company CASCADE;
