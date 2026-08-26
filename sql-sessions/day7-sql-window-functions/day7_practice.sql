-- =============================================================
-- Day 7 Practice — SQL Window Functions
-- =============================================================
-- Standalone: no dependency on any previous day's file.
-- Run this file top-to-bottom on any clean PostgreSQL database.
--
-- Tables created here:
--   company.departments  — dept_id, dept_name
--   company.employees    — emp_id, name, dept_id, salary, hire_date
--   company.orders       — order_id, customer_id, order_date, amount
--   company.order_items  — order_item_id, order_id, product_id, quantity, unit_price
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
-- SECTION 6 — LAG: look at the previous row
-- =============================================================

-- LAG(column, offset, default) returns the value from a row that is
-- 'offset' rows BEFORE the current row in the defined ORDER BY order.
-- offset defaults to 1 (immediately previous row).
-- default is returned when there is no previous row (first row).

-- Simple LAG: previous order amount
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LAG(amount)       OVER (ORDER BY order_date)    AS prev_amount,
    LAG(amount, 1, 0) OVER (ORDER BY order_date)    AS prev_amount_or_0
FROM company.orders
ORDER BY order_date;

-- LAG per customer: compare each order to the customer's previous order
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LAG(amount)     OVER (PARTITION BY customer_id ORDER BY order_date)  AS prev_order_amount,
    amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS change_from_prev
FROM company.orders
ORDER BY customer_id, order_date;

-- LAG to calculate days between consecutive orders for same customer
SELECT
    order_id,
    customer_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)  AS prev_order_date,
    order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_since_prev
FROM company.orders
ORDER BY customer_id, order_date;


-- =============================================================
-- SECTION 7 — LEAD: look at the next row
-- =============================================================

-- LEAD(column, offset, default) returns the value from a row that is
-- 'offset' rows AFTER the current row.
-- The last row in the window has no next row → returns NULL or default.

-- Simple LEAD: next order amount
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LEAD(amount)       OVER (ORDER BY order_date)    AS next_amount,
    LEAD(amount, 1, 0) OVER (ORDER BY order_date)    AS next_amount_or_0
FROM company.orders
ORDER BY order_date;

-- LEAD per customer: find gap to next order
-- Use to detect customers who churned (next order > 30 days away)
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)  AS next_order_date,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
        - order_date                                                        AS days_to_next_order
FROM company.orders
ORDER BY customer_id, order_date;


-- =============================================================
-- SECTION 8 — Running Totals: SUM with ORDER BY in OVER()
-- =============================================================

-- When you add ORDER BY inside an aggregate window function,
-- the frame becomes RANGE UNBOUNDED PRECEDING TO CURRENT ROW by default.
-- This means: "sum all rows from the start up to and including this row."
-- Result: a cumulative / running total.

-- Running total of order amounts ordered by date (all customers together)
SELECT
    order_id,
    order_date,
    amount,
    SUM(amount)   OVER (ORDER BY order_date)    AS running_total,
    ROUND(AVG(amount) OVER (ORDER BY order_date), 2) AS running_avg,
    COUNT(*)      OVER (ORDER BY order_date)    AS running_order_count
FROM company.orders
ORDER BY order_date;

-- Running total PER CUSTOMER ordered by their order date
-- Each customer's running total resets when the next customer starts
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date)  AS customer_running_total
FROM company.orders
ORDER BY customer_id, order_date;

-- Running count of employees hired per department (who was hired when?)
SELECT
    name,
    dept_id,
    hire_date,
    salary,
    COUNT(*) OVER (PARTITION BY dept_id ORDER BY hire_date)  AS hire_order_in_dept,
    SUM(salary) OVER (PARTITION BY dept_id ORDER BY hire_date) AS running_dept_payroll
FROM company.employees
ORDER BY dept_id, hire_date;


-- =============================================================
-- SECTION 9 — Window Frames: ROWS BETWEEN
-- =============================================================

-- A frame specifies WHICH rows within the partition to include
-- for the current row's calculation.
-- ROWS BETWEEN works by row position (not value).
-- RANGE BETWEEN works by value — affects ties.
--
-- Common frame patterns:
--   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW      → running total (default with ORDER BY)
--   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING → full partition total
--   ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING              → 3-row window
--   ROWS BETWEEN 6 PRECEDING AND CURRENT ROW              → 7-row rolling window

-- 3-day moving average: previous day + today + next day
SELECT
    sale_date,
    daily_sales,
    ROUND(AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) AS moving_avg_3day
FROM company.sales_daily
ORDER BY sale_date;

-- First and last rows of the window have fewer neighbours:
-- Row 1: only current + next    (no previous) → average of 2 rows
-- Last:  only previous + current (no next)    → average of 2 rows


-- 7-day rolling sum: today + 6 previous days
SELECT
    sale_date,
    daily_sales,
    SUM(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_sum,
    ROUND(AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7day_avg
FROM company.sales_daily
ORDER BY sale_date;


-- ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
-- = all rows in the partition, regardless of ORDER BY
-- = same result as SUM OVER (PARTITION BY ...) with no ORDER BY

SELECT
    name,
    dept_id,
    salary,
    -- These two produce identical results:
    SUM(salary) OVER (PARTITION BY dept_id)  AS dept_total_a,
    SUM(salary) OVER (
        PARTITION BY dept_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                         AS dept_total_b
FROM company.employees
ORDER BY dept_id;


-- =============================================================
-- SECTION 10 — FIRST_VALUE, LAST_VALUE, NTH_VALUE
-- =============================================================

-- These return a specific value from within the window frame.
-- FIRST_VALUE → value from the first row in the ordered window
-- LAST_VALUE  → value from the last row (NEEDS explicit full frame)
-- NTH_VALUE   → value from the Nth row (NEEDS explicit full frame)

-- FIRST_VALUE: name of the highest-paid employee per department
-- shown on EVERY employee's row
SELECT
    name,
    dept_id,
    salary,
    FIRST_VALUE(name)   OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS top_earner_in_dept,
    FIRST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS max_salary_in_dept
FROM company.employees
ORDER BY dept_id, salary DESC;


-- LAST_VALUE: name of the LOWEST-paid employee per department
-- CRITICAL: must add ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
-- Without it, the default frame stops at the current row → LAST_VALUE returns the current row's value!

SELECT
    name,
    dept_id,
    salary,
    -- WRONG — returns current employee's name, not the lowest earner:
    LAST_VALUE(name) OVER (PARTITION BY dept_id ORDER BY salary DESC)       AS wrong_last,

    -- RIGHT — full frame so LAST_VALUE sees all rows in the partition:
    LAST_VALUE(name) OVER (
        PARTITION BY dept_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                                         AS bottom_earner_in_dept
FROM company.employees
ORDER BY dept_id, salary DESC;


-- NTH_VALUE: name of the 2nd highest paid employee per department
-- Also needs full frame
SELECT
    name,
    dept_id,
    salary,
    NTH_VALUE(name, 2) OVER (
        PARTITION BY dept_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS second_highest_earner
FROM company.employees
ORDER BY dept_id, salary DESC;

-- HR has only 1 employee (Grace) → NTH_VALUE(name, 2) returns NULL


-- =============================================================
-- SECTION 11 — Named WINDOW Clause
-- =============================================================

-- When the same window definition appears multiple times in a query,
-- define it once with WINDOW and reference it by name.
-- This avoids repetition and reduces the chance of inconsistency.

-- Without named window — same definition repeated 4 times
SELECT
    name,
    dept_id,
    salary,
    ROW_NUMBER()  OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn,
    RANK()        OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk,
    DENSE_RANK()  OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dense_rnk,
    NTILE(3)      OVER (PARTITION BY dept_id ORDER BY salary DESC) AS tier
FROM company.employees
ORDER BY dept_id, salary DESC;


-- With named window — defined once, referenced four times
SELECT
    name,
    dept_id,
    salary,
    ROW_NUMBER()  OVER w  AS rn,
    RANK()        OVER w  AS rnk,
    DENSE_RANK()  OVER w  AS dense_rnk,
    NTILE(3)      OVER w  AS tier
FROM company.employees
WINDOW w AS (PARTITION BY dept_id ORDER BY salary DESC)
ORDER BY dept_id, salary DESC;

-- Both queries produce identical results. The WINDOW clause version
-- is easier to maintain — change the partition or order once, it updates everywhere.


-- =============================================================
-- SECTION 12 — Common Mistakes
-- =============================================================

-- Mistake 1: Window functions in WHERE — not allowed
-- Window functions are computed AFTER the WHERE filter.
-- You must wrap them in a subquery or CTE.

-- WRONG: this throws an error
-- SELECT name, salary
-- FROM company.employees
-- WHERE ROW_NUMBER() OVER (ORDER BY salary DESC) <= 3;

-- RIGHT: CTE approach
WITH ranked AS (
    SELECT
        name,
        salary,
        ROW_NUMBER() OVER (ORDER BY salary DESC)  AS rn
    FROM company.employees
)
SELECT name, salary FROM ranked WHERE rn <= 3;

-- RIGHT: subquery approach
SELECT name, salary
FROM (
    SELECT name, salary,
           ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
    FROM company.employees
) t
WHERE rn <= 3;


-- Mistake 2: LAST_VALUE returning current row (missing frame)
-- Shown in Section 10 — always add ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING


-- Mistake 3: Confusing ORDER BY in OVER() with ORDER BY at the end of the query
-- They are completely independent — one controls the window computation,
-- the other controls the output display order.

SELECT
    name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC)  AS salary_rank   -- window order: salary high to low
FROM company.employees
ORDER BY name;   -- display order: alphabetical — independent of window order


-- Mistake 4: using RANK when ROW_NUMBER is needed (or vice versa)
-- Use ROW_NUMBER for: pagination, dedup (pick one row per key)
-- Use RANK for: competition-style ("top 3 salaries" — ties stay)
-- Use DENSE_RANK for: "top 3 salary levels" — no gaps after ties

-- Dedup example: keep only the most recently hired employee per department
WITH ranked AS (
    SELECT
        name,
        dept_id,
        hire_date,
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY hire_date DESC) AS rn
    FROM company.employees
)
SELECT dept_id, name, hire_date FROM ranked WHERE rn = 1;


-- =============================================================
-- SECTION 13 — Combined: all window functions together
-- =============================================================

-- A single query showing ranking, running total, LAG, FIRST_VALUE,
-- and NTILE together for a full analytical view of each employee.

SELECT
    e.name,
    d.dept_name,
    e.salary,
    e.hire_date,

    -- Ranking within department
    RANK()          OVER w_dept                           AS rank_in_dept,
    DENSE_RANK()    OVER w_dept                           AS dense_rank_in_dept,

    -- Salary position in the company
    NTILE(4)        OVER (ORDER BY e.salary DESC)         AS salary_quartile,

    -- Department aggregates (no ORDER BY → full partition, not cumulative)
    ROUND(AVG(e.salary) OVER (PARTITION BY e.dept_id), 2) AS dept_avg,
    MAX(e.salary)   OVER (PARTITION BY e.dept_id)         AS dept_max,

    -- Top earner name in each department
    FIRST_VALUE(e.name) OVER w_dept                       AS dept_top_earner,

    -- Running total of salary by hire date (company-wide)
    SUM(e.salary)   OVER (ORDER BY e.hire_date)           AS cumulative_payroll,

    -- Percent of department payroll this employee represents
    ROUND(
        e.salary / SUM(e.salary) OVER (PARTITION BY e.dept_id) * 100, 2
    )                                                      AS pct_of_dept_payroll

FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
WINDOW w_dept AS (PARTITION BY e.dept_id ORDER BY e.salary DESC)
ORDER BY d.dept_name, rank_in_dept;


-- Month-over-month sales change using LAG on sales_daily
-- Group by month first, then apply LAG in outer query

SELECT
    month_start,
    TO_CHAR(month_start, 'Mon-YYYY')                                   AS month_label,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month_start)                   AS prev_month_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month_start) AS change,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month_start), 0) * 100
    , 2)                                                                AS pct_change
FROM (
    SELECT
        DATE_TRUNC('month', order_date)::DATE  AS month_start,
        SUM(amount)                            AS monthly_revenue
    FROM company.orders
    GROUP BY DATE_TRUNC('month', order_date)
) monthly
ORDER BY month_start;


-- 3-day moving average and 7-day rolling sum side by side on daily sales
SELECT
    sale_date,
    daily_sales,

    -- 3-day centered moving average
    ROUND(AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2)  AS moving_avg_3day,

    -- 7-day rolling sum (trailing)
    SUM(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )      AS rolling_7day_sum,

    -- Running cumulative total from day 1
    SUM(daily_sales) OVER (ORDER BY sale_date)  AS cumulative_total,

    -- Today as % of the grand total
    ROUND(
        daily_sales / SUM(daily_sales) OVER () * 100
    , 2)   AS pct_of_all_days

FROM company.sales_daily
ORDER BY sale_date;
