-- =============================================================
-- Day 3 Practice — JOINs: INNER, LEFT, RIGHT, FULL, SELF, CROSS
-- =============================================================
-- Prerequisite: run day1_practice.sql first to create company schema & tables
--
-- Tables used:
--   company.employees         — emp_id, first_name, last_name, email, salary, dept_id, hire_date, status, manager_id
--   company.departments       — dept_id, dept_name, location
--   company.projects          — project_id, project_name, dept_id  (created below)
--   company.employee_projects — emp_id, project_id, role            (created below)


-- ===============================================================
-- DATA SETUP — fresh, purposeful data for all JOIN demonstrations
-- ===============================================================
--
-- We reset and reload data here so every JOIN produces clearly visible results.
-- Each table is designed with specific "interesting" rows:
--
--   departments  → 5 depts: 3 have employees, 2 are empty (visible in LEFT/RIGHT/FULL JOIN)
--   employees    → 8 employees: 6 linked to depts, 1 with NULL dept_id, 1 with invalid dept_id
--                  (visible in LEFT JOIN anti-join and FULL OUTER JOIN)
--   projects     → 4 projects: 3 linked to depts, 1 standalone
--   employee_projects → some employees have 0, 1, or 2 projects
--                  (visible in multi-table JOIN and row-multiplication demo)
--
-- What each JOIN will show:
--   INNER JOIN          → 6 employees with a matching dept (emp 7 and 8 excluded)
--   LEFT JOIN           → all 8 employees; emp 7 (NULL dept) and emp 8 (bad dept) show NULL dept_name
--   RIGHT JOIN          → all 5 depts; 'Operations' and 'Legal' show NULL for employee cols
--   FULL OUTER JOIN     → everything: 8 employees + 2 empty depts all in one result
--   SELF JOIN (manager) → emp 1 = CEO (no manager), emps 2-5 report to emp 1, emps 6-8 report to emp 2
--   CROSS JOIN          → 8 employees × 5 departments = 40 rows
--   Multi-table JOIN    → employees → dept → projects via employee_projects
-- ---------------------------------------------------------------


-- Step 1: Wipe existing data (order matters — child tables first)
TRUNCATE company.employees    RESTART IDENTITY CASCADE;
TRUNCATE company.departments  RESTART IDENTITY CASCADE;


-- Step 2: Departments — 5 rows, 2 intentionally empty (no employees will link to them)
--
--   dept_id | dept_name    | location
--   --------+--------------+------------
--      1    | Engineering  | Pune          ← has employees
--      2    | Marketing    | Mumbai        ← has employees
--      3    | HR           | Bangalore     ← has employees
--      4    | Operations   | Delhi         ← EMPTY — visible in LEFT/RIGHT/FULL JOIN
--      5    | Legal        | Chennai       ← EMPTY — visible in LEFT/RIGHT/FULL JOIN

INSERT INTO company.departments (dept_name, location) VALUES
    ('Engineering', 'Pune'),        -- dept_id = 1
    ('Marketing',   'Mumbai'),      -- dept_id = 2
    ('HR',          'Bangalore'),   -- dept_id = 3
    ('Operations',  'Delhi'),       -- dept_id = 4  ← no employees → shows in LEFT/FULL JOIN
    ('Legal',       'Chennai');     -- dept_id = 5  ← no employees → shows in LEFT/FULL JOIN


-- Step 3: Employees — 8 rows with deliberate variety
--
--   emp_id | first_name | dept_id | salary  | note
--   -------+------------+---------+---------+----------------------------------------------
--      1   | Alice      |    1    |  95000  | Engineering, CEO / top-level (no manager)
--      2   | Bob        |    1    |  82000  | Engineering, reports to Alice
--      3   | Carol      |    2    |  78000  | Marketing, reports to Alice
--      4   | David      |    2    |  67000  | Marketing, reports to Bob
--      5   | Eve        |    3    |  71000  | HR, reports to Bob
--      6   | Frank      |    3    |  59000  | HR, reports to Bob; salary < manager → visible in SELF JOIN
--      7   | Grace      |  NULL   |  54000  | NO department → visible in LEFT JOIN anti-join
--      8   | Henry      |   99   |  48000  | dept_id=99 doesn't exist → visible in LEFT/FULL JOIN
--
-- Note: emp 4 (David, 67k) reports to Bob (82k) — David earns less than his manager.
--       emp 6 (Frank, 59k) reports to Bob (82k) — Frank earns less too.
--       We'll set manager relationships via UPDATE after insert (self-referencing FK).

INSERT INTO company.employees (first_name, last_name, email, salary, dept_id, hire_date, status) VALUES
    ('Alice', 'Adams',   'alice.adams@company.com',   95000, 1,    '2019-03-01', 'active'),   -- emp_id = 1
    ('Bob',   'Brown',   'bob.brown@company.com',     82000, 1,    '2020-06-15', 'active'),   -- emp_id = 2
    ('Carol', 'Clark',   'carol.clark@company.com',   78000, 2,    '2021-01-10', 'active'),   -- emp_id = 3
    ('David', 'Davis',   'david.davis@company.com',   67000, 2,    '2021-09-20', 'active'),   -- emp_id = 4
    ('Eve',   'Evans',   'eve.evans@company.com',     71000, 3,    '2022-04-05', 'active'),   -- emp_id = 5
    ('Frank', 'Foster',  'frank.foster@company.com',  59000, 3,    '2022-11-18', 'inactive'), -- emp_id = 6
    ('Grace', 'Green',   'grace.green@company.com',   54000, NULL, '2023-02-28', 'active'),   -- emp_id = 7  ← NULL dept
    ('Henry', 'Harris',  'henry.harris@company.com',  48000, 99,   '2023-07-01', 'active');   -- emp_id = 8  ← bad dept_id (no FK since we didn't enforce it here)


-- Step 4: Add manager_id column (self-referencing FK for SELF JOIN demos)
ALTER TABLE company.employees
    ADD COLUMN IF NOT EXISTS manager_id INT REFERENCES company.employees(emp_id);

-- Org chart:
--   Alice (1)  ← CEO, no manager
--   ├── Bob   (2)  reports to Alice
--   │   ├── David (4)  reports to Bob
--   │   ├── Eve   (5)  reports to Bob
--   │   └── Frank (6)  reports to Bob  (salary 59k < Bob's 82k → shows in earn-more-than-manager query)
--   └── Carol (3)  reports to Alice
--       └── (no direct reports)
--   Grace (7)  reports to Carol  (no dept — still has a manager)
--   Henry (8)  reports to Carol

UPDATE company.employees SET manager_id = NULL WHERE emp_id = 1;          -- Alice: CEO
UPDATE company.employees SET manager_id = 1    WHERE emp_id IN (2, 3);    -- Bob, Carol → Alice
UPDATE company.employees SET manager_id = 2    WHERE emp_id IN (4, 5, 6); -- David, Eve, Frank → Bob
UPDATE company.employees SET manager_id = 3    WHERE emp_id IN (7, 8);    -- Grace, Henry → Carol


-- Step 5: Projects and assignments (for multi-table JOIN demos)
CREATE TABLE IF NOT EXISTS company.projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INT REFERENCES company.departments(dept_id)
);

CREATE TABLE IF NOT EXISTS company.employee_projects (
    emp_id     INT REFERENCES company.employees(emp_id),
    project_id INT REFERENCES company.projects(project_id),
    role       VARCHAR(50),
    PRIMARY KEY (emp_id, project_id)
);

INSERT INTO company.projects (project_name, dept_id) VALUES
    ('Data Platform Rebuild', 1),   -- project_id = 1, Engineering
    ('CRM Migration',         2),   -- project_id = 2, Marketing
    ('Payroll Upgrade',       3),   -- project_id = 3, HR
    ('Cloud Infrastructure',  1);   -- project_id = 4, Engineering (2nd Engineering project)

-- Assignments:
--   Alice  → 2 projects (row multiplier demo — Alice appears twice in INNER JOIN to projects)
--   Bob    → 2 projects
--   Carol  → 1 project
--   David  → 0 projects  ← visible in LEFT JOIN (shows 'No Project')
--   Eve    → 0 projects  ← visible in LEFT JOIN
--   Frank  → 1 project
--   Grace  → 0 projects (no dept + no project)
--   Henry  → 0 projects

INSERT INTO company.employee_projects (emp_id, project_id, role) VALUES
    (1, 1, 'Lead Engineer'),       -- Alice on Data Platform
    (1, 4, 'Technical Advisor'),   -- Alice on Cloud Infra  ← Alice appears TWICE after JOIN
    (2, 1, 'Developer'),           -- Bob on Data Platform
    (2, 2, 'Analyst'),             -- Bob on CRM Migration  ← Bob appears TWICE after JOIN
    (3, 2, 'Project Manager'),     -- Carol on CRM Migration
    (6, 3, 'HR Analyst');          -- Frank on Payroll Upgrade


-- Quick sanity check — run these after setup to confirm data loaded correctly:
SELECT 'departments' AS tbl, COUNT(*) AS rows FROM company.departments
UNION ALL
SELECT 'employees',           COUNT(*)         FROM company.employees
UNION ALL
SELECT 'projects',            COUNT(*)         FROM company.projects
UNION ALL
SELECT 'employee_projects',   COUNT(*)         FROM company.employee_projects;

-- Expected output:
--   departments       | 5
--   employees         | 8
--   projects          | 4
--   employee_projects | 6


-- ===============================================================
-- SECTION 1: INNER JOIN
-- ===============================================================
--
-- INNER JOIN returns only rows that have a match in BOTH tables.
-- Any employee whose dept_id does not exist in departments is excluded.
-- Any department that has no employees is excluded.
-- This is the most common join — use it when you only want fully-linked data.
--
-- Syntax:
--   FROM left_table  alias
--   [INNER] JOIN right_table alias ON left.col = right.col
--
-- The keyword INNER is optional — plain JOIN defaults to INNER JOIN.
-- ---------------------------------------------------------------


-- Basic INNER JOIN: each employee with their department name.
-- emp_id 1 has dept_id=1 → matches departments row where dept_id=1 → row included.
-- An employee with dept_id=99 (no matching dept row) → excluded.
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    d.dept_name,
    e.salary
FROM company.employees   e
INNER JOIN company.departments d ON e.dept_id = d.dept_id;

-- Same query using plain JOIN (INNER is implied — same result)
SELECT
    e.emp_id,
    e.first_name,
    d.dept_name
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id;


-- INNER JOIN with WHERE filter — add location filter after joining.
-- WHERE runs AFTER the JOIN result is assembled; only matching rows survive.
SELECT
    e.first_name,
    e.last_name,
    d.dept_name,
    d.location
FROM company.employees   e
JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.location IN ('Pune', 'Mumbai');


-- INNER JOIN with GROUP BY — headcount per department.
-- COUNT(e.emp_id) counts only non-NULL emp_ids = one per matched employee.
-- Only departments with at least one employee appear (INNER JOIN excludes empty depts).
SELECT
    d.dept_name,
    COUNT(e.emp_id)          AS headcount,
    ROUND(AVG(e.salary), 2)  AS avg_salary,
    SUM(e.salary)            AS total_payroll
FROM company.departments d
JOIN company.employees   e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY headcount DESC;


-- INNER JOIN with ORDER BY and LIMIT — top 3 highest earners with their dept.
SELECT
    e.first_name || ' ' || e.last_name  AS full_name,
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
-- LEFT JOIN returns ALL rows from the left (FROM) table.
-- For rows that have a match in the right table, right-side columns are filled in.
-- For rows with NO match in the right table, all right-side columns come back as NULL.
-- Use LEFT JOIN when you cannot afford to lose left-table rows due to missing right-side data.
--
-- Syntax:
--   FROM left_table  alias
--   LEFT [OUTER] JOIN right_table alias ON condition
-- OUTER is optional — LEFT JOIN and LEFT OUTER JOIN are identical.
-- ---------------------------------------------------------------


-- All employees, including those with no department (dept_id = NULL or no matching dept).
-- Where there is no matching dept row, dept_name comes back as NULL.
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    d.dept_name       -- NULL for employees with no department
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id;


-- COALESCE to replace NULL with a friendly label.
-- COALESCE(x, y) returns x if x is not NULL, otherwise y.
SELECT
    e.emp_id,
    e.first_name,
    COALESCE(d.dept_name, 'No Department') AS dept_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id;


-- All departments with their employee count — including empty departments.
-- COUNT(e.emp_id) returns 0 for departments with no employees (NULLs not counted).
-- If we used INNER JOIN, empty departments would disappear from the result.
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS headcount
FROM company.departments d
LEFT JOIN company.employees  e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY headcount DESC;


-- ANTI-JOIN PATTERN: find employees who have NO department assigned.
-- Step 1: LEFT JOIN brings all employees, NULLing the dept columns for unmatched ones.
-- Step 2: WHERE d.dept_id IS NULL keeps ONLY the unmatched employees.
-- This is faster than a NOT IN / NOT EXISTS subquery on large tables.
SELECT
    e.emp_id,
    e.first_name,
    e.last_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;    -- NULL on the RIGHT side means no match was found


-- ANTI-JOIN: find departments that have NO employees.
SELECT
    d.dept_id,
    d.dept_name
FROM company.departments d
LEFT JOIN company.employees  e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;     -- NULL on the RIGHT side means no employees in this dept


-- Filter in ON vs WHERE — critical difference for LEFT JOIN.
-- WRONG: WHERE filter on right-side column turns LEFT JOIN into INNER JOIN.
--   Employees with no Engineering dept match have d.dept_name = NULL.
--   WHERE d.dept_name = 'Engineering' excludes ALL NULL rows → becomes an INNER JOIN.
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering';   -- excludes all non-Engineering employees!

-- CORRECT: put the right-side filter inside the ON clause.
--   All employees still appear; only the dept_name column is filtered —
--   employees NOT in Engineering get NULL for dept_name instead of being excluded.
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d
    ON  e.dept_id   = d.dept_id
    AND d.dept_name = 'Engineering';   -- filter is part of the join condition, not a row filter


-- ===============================================================
-- SECTION 3: RIGHT JOIN
-- ===============================================================
--
-- RIGHT JOIN is the mirror image of LEFT JOIN.
-- ALL rows from the RIGHT table (JOIN table) are kept.
-- Left-side columns are NULL where no match exists.
-- In practice, most developers flip the table order and use LEFT JOIN for consistency.
--
-- Rule: FROM a RIGHT JOIN b  ≡  FROM b LEFT JOIN a
-- ---------------------------------------------------------------


-- All departments, even those with no employees.
-- Equivalent to: FROM departments d LEFT JOIN employees e ...
SELECT
    d.dept_id,
    d.dept_name,
    e.first_name        -- NULL if the department has no employees
FROM company.employees   e
RIGHT JOIN company.departments d ON e.dept_id = d.dept_id;


-- Rewrite as LEFT JOIN (same result, more conventional style).
SELECT
    d.dept_id,
    d.dept_name,
    e.first_name
FROM company.departments d
LEFT JOIN company.employees  e ON d.dept_id = e.dept_id;


-- RIGHT JOIN with aggregation — headcount per department including empty ones.
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
-- FULL OUTER JOIN returns ALL rows from BOTH tables.
-- Where a left row has no right match, right columns are NULL.
-- Where a right row has no left match, left columns are NULL.
-- Use for data reconciliation between two sources.
-- ---------------------------------------------------------------


-- All employees + all departments, regardless of whether they match.
-- Employees with no dept: dept columns are NULL.
-- Departments with no employees: emp columns are NULL.
SELECT
    e.emp_id,
    e.first_name,
    d.dept_id,
    d.dept_name
FROM company.employees   e
FULL OUTER JOIN company.departments d ON e.dept_id = d.dept_id
ORDER BY e.emp_id NULLS LAST;


-- Find ALL unmatched rows from either side at once.
-- This is the combination of both anti-join patterns in one query.
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


-- Data reconciliation pattern: compare staging vs production.
-- Simulated with a CTE (we'll cover CTEs in detail later — just follow the pattern here).
-- This is the standard MERGE-detection query used in ETL pipelines.
WITH staging AS (
    -- Simulating a staging table by aliasing employees with modified values
    SELECT emp_id, first_name, salary * 1.10 AS salary
    FROM company.employees
    WHERE emp_id IN (1, 2, 99)  -- emp 99 doesn't exist in prod → INSERT candidate
),
production AS (
    SELECT emp_id, first_name, salary
    FROM company.employees
    WHERE emp_id IN (1, 2, 3)   -- emp 3 not in staging → DELETE candidate
)
SELECT
    COALESCE(s.emp_id, p.emp_id)   AS emp_id,
    COALESCE(s.first_name, p.first_name) AS first_name,
    s.salary                       AS staging_salary,
    p.salary                       AS prod_salary,
    CASE
        WHEN p.emp_id IS NULL                THEN 'INSERT'   -- in staging, not in prod
        WHEN s.emp_id IS NULL                THEN 'DELETE'   -- in prod, not in staging
        WHEN s.salary <> p.salary            THEN 'UPDATE'   -- in both, salary differs
        ELSE                                      'NO CHANGE'
    END AS action
FROM staging   s
FULL OUTER JOIN production p ON s.emp_id = p.emp_id;


-- ===============================================================
-- SECTION 5: SELF JOIN
-- ===============================================================
--
-- A SELF JOIN is when a table is joined to itself using two different aliases.
-- The same table acts as both left and right.
-- Common uses: hierarchical data (employee → manager), comparing rows within a table.
--
-- Always use LEFT JOIN for manager queries so top-level rows (no manager) still appear.
-- ---------------------------------------------------------------


-- Employee with their manager's name.
-- Alias 'e' = the employee row.
-- Alias 'm' = the same employees table but read as the manager row.
-- e.manager_id links to m.emp_id — the manager's primary key.
-- LEFT JOIN: the CEO (manager_id = NULL) still appears with NULL as manager name.
SELECT
    e.emp_id,
    e.first_name                             AS employee_first,
    e.last_name                              AS employee_last,
    m.first_name                             AS manager_first,
    m.last_name                              AS manager_last
FROM company.employees e
LEFT JOIN company.employees m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;


-- Find employees who earn MORE than their manager.
-- INNER JOIN here — we only care about employees who have a manager.
SELECT
    e.first_name  AS employee,
    e.salary      AS employee_salary,
    m.first_name  AS manager,
    m.salary      AS manager_salary,
    e.salary - m.salary AS difference
FROM company.employees e
JOIN company.employees m ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;


-- Pairs of employees in the same department (no duplicates).
-- a.emp_id < b.emp_id ensures each pair appears only once:
-- (Alice, Bob) but NOT also (Bob, Alice) — the < condition makes order deterministic.
SELECT
    a.first_name AS employee_1,
    b.first_name AS employee_2,
    a.dept_id
FROM company.employees a
JOIN company.employees b
    ON  a.dept_id = b.dept_id
    AND a.emp_id  < b.emp_id    -- prevents duplicates and self-pairs
ORDER BY a.dept_id, a.emp_id;


-- ===============================================================
-- SECTION 6: CROSS JOIN
-- ===============================================================
--
-- CROSS JOIN produces the cartesian product — every row of table A paired with
-- every row of table B. No ON condition is needed or valid.
-- Result rows = rows_in_A × rows_in_B.
-- Use for: generating all combinations, building reporting scaffolds.
-- Accidental CROSS JOINs (missing ON) are a common and expensive bug.
-- ---------------------------------------------------------------


-- Every employee paired with every department — all combinations.
-- 5 employees × 3 departments = 15 rows.
SELECT
    e.first_name  AS employee,
    d.dept_name   AS department
FROM company.employees   e
CROSS JOIN company.departments d
ORDER BY e.first_name, d.dept_name;


-- Verify the row count: employees × departments
SELECT
    (SELECT COUNT(*) FROM company.employees)    AS emp_count,
    (SELECT COUNT(*) FROM company.departments)  AS dept_count,
    (SELECT COUNT(*) FROM company.employees)
    * (SELECT COUNT(*) FROM company.departments) AS cross_join_rows;


-- Practical use: generate a quarter × department scaffold for a reporting grid.
-- VALUES creates an inline table of quarters.
-- CROSS JOIN pairs every quarter with every department.
-- A pipeline then LEFT JOINs actual sales data onto this scaffold
-- so every cell in the report exists even with zero sales.
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
-- Queries often join 3, 4, or more tables.
-- Each JOIN adds one more table to the running result set.
-- The order of JOINs generally doesn't affect correctness but affects readability.
-- Aliases become essential — always alias every table.
-- ---------------------------------------------------------------


-- projects and employee_projects were created and loaded in the DATA SETUP block above.
-- Current data:
--   projects          → Data Platform Rebuild (Eng), CRM Migration (Mktg), Payroll Upgrade (HR), Cloud Infrastructure (Eng)
--   employee_projects → Alice (2 projects), Bob (2), Carol (1), Frank (1), David/Eve/Grace/Henry (0 each)


-- Three-table INNER JOIN: employee → dept → project.
-- Only employees assigned to a project AND with a department appear.
SELECT
    e.first_name || ' ' || e.last_name  AS full_name,
    d.dept_name,
    p.project_name,
    ep.role
FROM company.employees        e
JOIN company.departments      d  ON e.dept_id    = d.dept_id
JOIN company.employee_projects ep ON e.emp_id    = ep.emp_id
JOIN company.projects          p  ON ep.project_id = p.project_id
ORDER BY e.last_name;


-- Mix INNER and LEFT JOIN: all employees, their dept, and projects (if any).
-- The INNER JOIN to departments stays so employees must have a dept.
-- The LEFT JOIN to employee_projects keeps employees with no project assigned.
SELECT
    e.first_name || ' ' || e.last_name  AS full_name,
    d.dept_name,
    COALESCE(p.project_name, 'No Project') AS project_name,
    ep.role
FROM company.employees        e
JOIN company.departments      d  ON e.dept_id    = d.dept_id
LEFT JOIN company.employee_projects ep ON e.emp_id    = ep.emp_id
LEFT JOIN company.projects          p  ON ep.project_id = p.project_id
ORDER BY e.last_name;


-- Count projects per employee including those with 0 projects.
SELECT
    e.first_name || ' ' || e.last_name  AS full_name,
    COUNT(ep.project_id)                AS project_count  -- 0 for NULLs (no project rows)
FROM company.employees        e
LEFT JOIN company.employee_projects ep ON e.emp_id = ep.emp_id
GROUP BY e.emp_id, e.first_name, e.last_name
ORDER BY project_count DESC;


-- ===============================================================
-- SECTION 8: JOIN + AGGREGATION + CASE
-- ===============================================================
--
-- JOINs, GROUP BY, and CASE compose naturally.
-- Always join first, then group, then apply CASE on aggregated results.
-- When using LEFT JOIN, remember: COUNT(*) counts NULL rows; COUNT(col) does not.
-- ---------------------------------------------------------------


-- Per-department stats with a CASE label — including empty departments.
-- COUNT(e.emp_id) → 0 for depts with no employees (NULLs not counted by COUNT(col)).
-- COALESCE on AVG → returns NULL for empty depts; we handle with CASE.
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


-- Employees vs their department's average — above or below?
-- The subquery calculates avg salary per dept_id first.
-- Then we JOIN that result to employees to compare each employee's salary.
SELECT
    e.first_name || ' ' || e.last_name  AS full_name,
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


-- MISTAKE 1: COUNT(*) vs COUNT(col) after LEFT JOIN.
-- COUNT(*) counts every row including those with NULL in e.emp_id.
-- A department with no employees still has 1 row in the result (with NULLs).
-- COUNT(*) for that row returns 1 — wrong. COUNT(e.emp_id) returns 0 — correct.
SELECT
    d.dept_name,
    COUNT(*)        AS wrong_headcount,    -- counts the NULL placeholder row as 1
    COUNT(e.emp_id) AS correct_headcount   -- skips NULL — returns 0 for empty depts
FROM company.departments d
LEFT JOIN company.employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name;


-- MISTAKE 2: WHERE on right-side column turns LEFT JOIN into INNER JOIN.
-- Broken: WHERE d.dept_name = 'Engineering' eliminates rows where d is NULL.
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering';    -- BUG: drops all employees not in Engineering

-- Fixed: move the filter into the ON clause.
SELECT e.first_name, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d
    ON  e.dept_id   = d.dept_id
    AND d.dept_name = 'Engineering';  -- employees NOT in Engineering get NULL dept_name


-- MISTAKE 3: Implicit CROSS JOIN from old-style comma syntax.
-- Old-style FROM a, b means CROSS JOIN — every row × every row.
-- Always use explicit JOIN ... ON syntax.
SELECT * FROM company.employees, company.departments;   -- accidental CROSS JOIN!

-- Corrected:
SELECT * FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id;


-- MISTAKE 4: Row multiplication from one-to-many JOIN.
-- Each employee assigned to N projects will appear N times after the join.
-- Always check row count before and after suspicious joins.
SELECT COUNT(*) AS before_join FROM company.employees;

SELECT COUNT(*) AS after_join
FROM company.employees e
LEFT JOIN company.employee_projects ep ON e.emp_id = ep.emp_id;
-- after_join > before_join if any employee has multiple project rows


-- ---------------------------------------------------------------
-- CLEANUP (uncomment to reset for re-practice)
-- ---------------------------------------------------------------
-- DROP TABLE IF EXISTS company.employee_projects;
-- DROP TABLE IF EXISTS company.projects;
-- ALTER TABLE company.employees DROP COLUMN IF EXISTS manager_id;
