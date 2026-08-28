-- =============================================================
-- Day 7 Practice — Window Functions Part 1
--                  OVER, PARTITION BY, ROW_NUMBER, RANK,
--                  DENSE_RANK, NTILE
-- =============================================================
-- Standalone: no dependency on any previous day's file.
-- Continued in day8_practice.sql: LAG, LEAD, running totals,
-- ROWS BETWEEN frames, FIRST_VALUE, LAST_VALUE, WINDOW clause.
-- Run this file top-to-bottom on any clean PostgreSQL database.
--
-- Tables created here:
--   company.departments  — dept_id, dept_name
--   company.employees    — emp_id, name, dept_id, salary, hire_date
--   company.orders       — order_id, customer_id, order_date, amount
--   company.sales_daily  — sale_id, sale_date, daily_sales


-- =============================================================
-- DATA SETUP — schema + purposeful data for all Window demos
-- =============================================================
--
-- What the data is designed to show:
--   OVER ()              → company-wide aggregate on every row
--   PARTITION BY dept    → per-department aggregate on every row
--   ROW_NUMBER           → unique numbering even with ties
--   RANK / DENSE_RANK    → two employees with same salary → tie demo
--   NTILE(4)             → salary quartiles
--   LAG / LEAD           → month-over-month change on orders
--   Running total        → cumulative sum ordered by date
--   ROWS BETWEEN         → 3-day and 7-day moving average on daily sales
--   FIRST_VALUE          → top earner per dept shown on every row
-- -------------------------------------------------------------


-- Step 1: Drop and recreate schema cleanly
DROP SCHEMA IF EXISTS company CASCADE;
CREATE SCHEMA company;


-- Step 2: Departments — 4 departments
--
--   dept_id | dept_name
--   --------+-----------
--       1   | Engineering
--       2   | Marketing
--       3   | HR
--       4   | Finance

CREATE TABLE company.departments (
    dept_id    SERIAL       PRIMARY KEY,
    dept_name  VARCHAR(100) NOT NULL
);

INSERT INTO company.departments (dept_name) VALUES
    ('Engineering'),   -- dept_id = 1
    ('Marketing'),     -- dept_id = 2
    ('HR'),            -- dept_id = 3
    ('Finance');       -- dept_id = 4


-- Step 3: Employees — 10 rows with deliberate salary ties for ranking demos
--
-- Deliberate variety:
--   Alice & Bob        → same salary 90000  ← TIE demo for RANK/DENSE_RANK
--   Engineering dept   → 3 employees (most populated)
--   HR dept            → 1 employee only  ← NTH_VALUE returns NULL here
--   hire_date spread   → running total ordered by hire_date demo

CREATE TABLE company.employees (
    emp_id    SERIAL       PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    dept_id   INT          REFERENCES company.departments(dept_id),
    salary    NUMERIC(10,2),
    hire_date DATE
);

INSERT INTO company.employees (name, dept_id, salary, hire_date) VALUES
    ('Alice',   1, 90000, '2020-03-01'),   -- emp_id = 1  Engineering  TIE
    ('Bob',     1, 90000, '2021-06-15'),   -- emp_id = 2  Engineering  TIE
    ('Carol',   1, 75000, '2022-01-10'),   -- emp_id = 3  Engineering
    ('David',   2, 80000, '2020-07-20'),   -- emp_id = 4  Marketing
    ('Eva',     2, 65000, '2023-03-05'),   -- emp_id = 5  Marketing
    ('Frank',   2, 65000, '2022-11-01'),   -- emp_id = 6  Marketing    TIE
    ('Grace',   3, 70000, '2021-09-18'),   -- emp_id = 7  HR
    ('Henry',   4, 85000, '2020-05-12'),   -- emp_id = 8  Finance
    ('Irene',   4, 72000, '2023-08-01'),   -- emp_id = 9  Finance
    ('John',    4, 58000, '2024-01-15');   -- emp_id = 10 Finance


-- Step 4: Orders — 12 orders across 3 customers to demo LAG/LEAD and running totals
--
-- customer_id 1 = 4 orders (gap > 30 days between some)
-- customer_id 2 = 5 orders
-- customer_id 3 = 3 orders

CREATE TABLE company.orders (
    order_id     SERIAL       PRIMARY KEY,
    customer_id  INT,
    order_date   DATE         NOT NULL,
    amount       NUMERIC(10,2)
);

INSERT INTO company.orders (customer_id, order_date, amount) VALUES
    (1, '2024-01-05',  5000.00),   -- order_id = 1
    (2, '2024-01-10',  8000.00),   -- order_id = 2
    (1, '2024-01-20',  3000.00),   -- order_id = 3
    (3, '2024-02-01', 12000.00),   -- order_id = 4
    (2, '2024-02-14',  4500.00),   -- order_id = 5
    (1, '2024-03-01',  7000.00),   -- order_id = 6   gap > 30 days from order 3
    (3, '2024-03-10',  2000.00),   -- order_id = 7
    (2, '2024-03-22',  9000.00),   -- order_id = 8
    (1, '2024-04-15',  6000.00),   -- order_id = 9   gap > 30 days from order 6
    (2, '2024-04-28', 11000.00),   -- order_id = 10
    (3, '2024-05-05',  3500.00),   -- order_id = 11
    (2, '2024-05-20',  5500.00);   -- order_id = 12


-- Step 5: sales_daily — 20 days of data for moving average and rolling sum demos
--
-- Deliberate design:
--   Values vary enough to make moving averages interesting
--   Gap on 2024-01-07 (Sunday) — streak demo

CREATE TABLE company.sales_daily (
    sale_id     SERIAL       PRIMARY KEY,
    sale_date   DATE         NOT NULL UNIQUE,
    daily_sales NUMERIC(10,2)
);

INSERT INTO company.sales_daily (sale_date, daily_sales) VALUES
    ('2024-01-01',  5200.00),
    ('2024-01-02',  4800.00),
    ('2024-01-03',  6100.00),
    ('2024-01-04',  3900.00),
    ('2024-01-05',  7200.00),
    ('2024-01-06',  5500.00),
    ('2024-01-08',  4100.00),   -- gap: 2024-01-07 missing
    ('2024-01-09',  6800.00),
    ('2024-01-10',  9000.00),
    ('2024-01-11',  7400.00),
    ('2024-01-12',  5100.00),
    ('2024-01-13',  8200.00),
    ('2024-01-14',  4600.00),
    ('2024-01-15', 10500.00),
    ('2024-01-16',  3800.00),
    ('2024-01-17',  6200.00),
    ('2024-01-18',  7800.00),
    ('2024-01-19',  5400.00),
    ('2024-01-20',  9100.00),
    ('2024-01-21',  6700.00);


-- Sanity check: row counts
-- Expected: departments=4, employees=10, orders=12, sales_daily=20
SELECT 'departments' AS tbl, COUNT(*) AS rows FROM company.departments
UNION ALL
SELECT 'employees',   COUNT(*) FROM company.employees
UNION ALL
SELECT 'orders',      COUNT(*) FROM company.orders
UNION ALL
SELECT 'sales_daily', COUNT(*) FROM company.sales_daily;


-- =============================================================
-- SECTION 1 — What is a Window Function? OVER() basics
-- =============================================================

-- A window function computes a value FOR EACH ROW using a set of related rows.
-- Unlike GROUP BY, it does NOT collapse rows — you keep all 10 employee rows
-- AND see the aggregate value on every row at the same time.

-- Compare GROUP BY vs OVER():

-- GROUP BY — collapses rows, loses individual employee detail
SELECT dept_id, AVG(salary) AS dept_avg
FROM company.employees
GROUP BY dept_id;

-- Window function — keeps all rows, adds dept avg alongside each one
SELECT
    emp_id,
    name,
    dept_id,
    salary,
    AVG(salary) OVER ()  AS company_avg_salary    -- OVER() with no args = entire table
FROM company.employees
ORDER BY dept_id, salary DESC;

-- Notice: company_avg_salary is the same on every single row.
-- That is the whole point — no row is collapsed.


-- =============================================================
-- SECTION 2 — PARTITION BY: compute per group without collapsing
-- =============================================================

-- PARTITION BY is like GROUP BY for window functions.
-- It divides rows into independent groups and computes the function
-- separately within each group — but still returns ALL rows.

SELECT
    emp_id,
    name,
    dept_id,
    salary,
    -- company-wide average (no partition)
    ROUND(AVG(salary) OVER (), 2)                       AS company_avg,
    -- department-level average (partitioned)
    ROUND(AVG(salary) OVER (PARTITION BY dept_id), 2)   AS dept_avg,
    -- how far above or below the department average
    ROUND(salary - AVG(salary) OVER (PARTITION BY dept_id), 2) AS diff_from_dept_avg
FROM company.employees
ORDER BY dept_id, salary DESC;


-- Multiple aggregate windows on the same row
-- All five aggregates computed per department without collapsing rows
SELECT
    name,
    dept_id,
    salary,
    COUNT(*)     OVER (PARTITION BY dept_id)  AS dept_headcount,
    SUM(salary)  OVER (PARTITION BY dept_id)  AS dept_total_payroll,
    ROUND(AVG(salary) OVER (PARTITION BY dept_id), 2) AS dept_avg_salary,
    MIN(salary)  OVER (PARTITION BY dept_id)  AS dept_min_salary,
    MAX(salary)  OVER (PARTITION BY dept_id)  AS dept_max_salary
FROM company.employees
ORDER BY dept_id, salary DESC;


-- =============================================================
-- SECTION 3 — ROW_NUMBER: unique sequential numbers
-- =============================================================

-- ROW_NUMBER() assigns 1, 2, 3 … to rows in the order specified.
-- Ties are broken arbitrarily — two rows with the same salary still get different numbers.
-- No gaps, no duplicates — always unique.

-- Company-wide row number ordered by salary (highest = 1)
SELECT
    emp_id,
    name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC)  AS company_rank
FROM company.employees;

-- Row number PER DEPARTMENT ordered by salary
-- Each dept starts counting from 1 independently
SELECT
    name,
    dept_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS rank_in_dept
FROM company.employees
ORDER BY dept_id, rank_in_dept;

-- Practical use: pick the highest-paid employee per department
-- Window functions cannot go in WHERE — wrap in a subquery
SELECT dept_id, name, salary
FROM (
    SELECT
        name,
        dept_id,
        salary,
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
    FROM company.employees
) ranked
WHERE rn = 1;


-- =============================================================
-- SECTION 4 — RANK and DENSE_RANK: handling ties
-- =============================================================

-- RANK()       → ties get the same rank; next rank SKIPS (1, 2, 2, 4)
-- DENSE_RANK() → ties get the same rank; next rank is consecutive (1, 2, 2, 3)
-- ROW_NUMBER() → no ties allowed; each row gets a unique number (1, 2, 3, 4)

-- Side-by-side comparison — Alice and Bob both earn 90000 (TIE)
-- Eva and Frank both earn 65000 (another TIE in Marketing)
SELECT
    name,
    dept_id,
    salary,
    ROW_NUMBER()  OVER (ORDER BY salary DESC)  AS row_num,    -- unique, no tie
    RANK()        OVER (ORDER BY salary DESC)  AS rnk,        -- gaps after tie
    DENSE_RANK()  OVER (ORDER BY salary DESC)  AS dense_rnk   -- no gaps after tie
FROM company.employees
ORDER BY salary DESC;

-- Expected result pattern:
-- salary 90000 → row_num 1, row_num 2 | rank 1, rank 1 | dense_rank 1, dense_rank 1
-- salary 85000 → row_num 3            | rank 3          | dense_rank 2   (RANK skips 2!)
-- salary 80000 → row_num 4            | rank 4          | dense_rank 3
-- salary 75000 → row_num 5            | rank 5          | dense_rank 4
-- salary 72000 → row_num 6            | rank 6          | dense_rank 5
-- salary 70000 → row_num 7            | rank 7          | dense_rank 6
-- salary 65000 → row_num 8, row_num 9 | rank 8, rank 8  | dense_rank 7, dense_rank 7
-- salary 58000 → row_num 10           | rank 10         | dense_rank 8


-- RANK per department — demonstrates per-partition ties
SELECT
    name,
    dept_id,
    salary,
    RANK()       OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS rank_in_dept,
    DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS dense_rank_in_dept
FROM company.employees
ORDER BY dept_id, salary DESC;


-- =============================================================
-- SECTION 5 — NTILE: dividing into equal buckets
-- =============================================================

-- NTILE(n) divides rows into n roughly equal groups and assigns
-- a bucket number 1 through n.
-- If rows don't divide evenly, earlier buckets get one extra row.
-- Common use: quartiles (n=4), deciles (n=10), percentile groups.

-- Salary quartiles: 1 = lowest 25%, 4 = highest 25%
SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary ASC)   AS salary_quartile
FROM company.employees
ORDER BY salary ASC;

-- NTILE per department: salary tier within each department
SELECT
    name,
    dept_id,
    salary,
    NTILE(3) OVER (PARTITION BY dept_id ORDER BY salary ASC)  AS tier_in_dept,
    CASE NTILE(3) OVER (PARTITION BY dept_id ORDER BY salary ASC)
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Mid'
        WHEN 3 THEN 'High'
    END AS salary_tier
FROM company.employees
ORDER BY dept_id, salary;


-- =============================================================
-- END OF DAY 7
-- Sections 6 onwards (LAG, LEAD, running totals, ROWS BETWEEN,
-- FIRST_VALUE, LAST_VALUE, NTH_VALUE, WINDOW clause) continue
-- in day8_practice.sql — run that file next.
-- =============================================================
