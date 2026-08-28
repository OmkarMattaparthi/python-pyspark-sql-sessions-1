-- =============================================================
-- Day 8 Practice — Window Functions Part 2
--                  LAG, LEAD, Running Totals, ROWS BETWEEN,
--                  FIRST_VALUE, LAST_VALUE, NTH_VALUE,
--                  WINDOW clause, Common Mistakes
-- =============================================================
-- Standalone: no dependency on any previous day's file.
-- This is the continuation of day7_practice.sql.
-- Run this file top-to-bottom on any clean PostgreSQL database.
--
-- Tables created here:
--   company.departments  — dept_id, dept_name
--   company.employees    — emp_id, name, dept_id, salary, hire_date
--   company.orders       — order_id, customer_id, order_date, amount
--   company.sales_daily  — sale_id, sale_date, daily_sales


-- =============================================================
-- DATA SETUP — same schema as day7 (fully re-created here)
-- =============================================================

DROP SCHEMA IF EXISTS company CASCADE;
CREATE SCHEMA company;

CREATE TABLE company.departments (
    dept_id    SERIAL       PRIMARY KEY,
    dept_name  VARCHAR(100) NOT NULL
);
INSERT INTO company.departments (dept_name) VALUES
    ('Engineering'), ('Marketing'), ('HR'), ('Finance');

CREATE TABLE company.employees (
    emp_id    SERIAL       PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    dept_id   INT          REFERENCES company.departments(dept_id),
    salary    NUMERIC(10,2),
    hire_date DATE
);
INSERT INTO company.employees (name, dept_id, salary, hire_date) VALUES
    ('Alice',  1, 90000, '2020-03-01'),
    ('Bob',    1, 90000, '2021-06-15'),
    ('Carol',  1, 75000, '2022-01-10'),
    ('David',  2, 80000, '2020-07-20'),
    ('Eva',    2, 65000, '2023-03-05'),
    ('Frank',  2, 65000, '2022-11-01'),
    ('Grace',  3, 70000, '2021-09-18'),
    ('Henry',  4, 85000, '2020-05-12'),
    ('Irene',  4, 72000, '2023-08-01'),
    ('John',   4, 58000, '2024-01-15');

CREATE TABLE company.orders (
    order_id     SERIAL        PRIMARY KEY,
    customer_id  INT,
    order_date   DATE          NOT NULL,
    amount       NUMERIC(10,2)
);
INSERT INTO company.orders (customer_id, order_date, amount) VALUES
    (1, '2024-01-05',  5000.00),
    (2, '2024-01-10',  8000.00),
    (1, '2024-01-20',  3000.00),
    (3, '2024-02-01', 12000.00),
    (2, '2024-02-14',  4500.00),
    (1, '2024-03-01',  7000.00),
    (3, '2024-03-10',  2000.00),
    (2, '2024-03-22',  9000.00),
    (1, '2024-04-15',  6000.00),
    (2, '2024-04-28', 11000.00),
    (3, '2024-05-05',  3500.00),
    (2, '2024-05-20',  5500.00);

CREATE TABLE company.sales_daily (
    sale_id     SERIAL        PRIMARY KEY,
    sale_date   DATE          NOT NULL UNIQUE,
    daily_sales NUMERIC(10,2)
);
INSERT INTO company.sales_daily (sale_date, daily_sales) VALUES
    ('2024-01-01',  5200.00), ('2024-01-02',  4800.00),
    ('2024-01-03',  6100.00), ('2024-01-04',  3900.00),
    ('2024-01-05',  7200.00), ('2024-01-06',  5500.00),
    ('2024-01-08',  4100.00), ('2024-01-09',  6800.00),
    ('2024-01-10',  9000.00), ('2024-01-11',  7400.00),
    ('2024-01-12',  5100.00), ('2024-01-13',  8200.00),
    ('2024-01-14',  4600.00), ('2024-01-15', 10500.00),
    ('2024-01-16',  3800.00), ('2024-01-17',  6200.00),
    ('2024-01-18',  7800.00), ('2024-01-19',  5400.00),
    ('2024-01-20',  9100.00), ('2024-01-21',  6700.00);

-- Sanity check
SELECT 'departments' AS tbl, COUNT(*) AS rows FROM company.departments
UNION ALL SELECT 'employees',   COUNT(*) FROM company.employees
UNION ALL SELECT 'orders',      COUNT(*) FROM company.orders
UNION ALL SELECT 'sales_daily', COUNT(*) FROM company.sales_daily;


-- =============================================================
-- SECTION 1 — LAG: look at the previous row
-- =============================================================

-- LAG(column, offset, default)
--   offset  = how many rows back (default 1)
--   default = value returned when there is no previous row
-- Use: compare current row to a prior row (prev month, prev order, prev event)

-- Basic LAG: what was the previous order amount (company-wide, ordered by date)?
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LAG(amount)        OVER (ORDER BY order_date)    AS prev_amount,
    LAG(amount, 1, 0)  OVER (ORDER BY order_date)    AS prev_amount_or_zero
FROM company.orders
ORDER BY order_date;
-- First row: prev_amount = NULL, prev_amount_or_zero = 0


-- LAG per customer: each order compared to THAT CUSTOMER's previous order
-- PARTITION BY resets LAG independently for each customer
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date)          AS prev_order_amount,
    amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS change_from_prev
FROM company.orders
ORDER BY customer_id, order_date;


-- LAG for gap detection: days between consecutive orders per customer
-- Gap > 30 days = potential churn signal
SELECT
    order_id,
    customer_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)  AS prev_order_date,
    order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_gap,
    CASE
        WHEN order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) > 30
        THEN 'Long gap'
        WHEN LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) IS NULL
        THEN 'First order'
        ELSE 'Normal'
    END AS gap_type
FROM company.orders
ORDER BY customer_id, order_date;


-- =============================================================
-- SECTION 2 — LEAD: look at the next row
-- =============================================================

-- LEAD(column, offset, default)
--   Returns value from a row AFTER the current row.
--   Last row in the window returns NULL or default.
-- Use: look ahead — next event, next order, next date

-- Basic LEAD: what is the next order amount?
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LEAD(amount)        OVER (ORDER BY order_date)   AS next_amount,
    LEAD(amount, 1, 0)  OVER (ORDER BY order_date)   AS next_amount_or_zero
FROM company.orders
ORDER BY order_date;
-- Last row: next_amount = NULL


-- LEAD per customer: days until next order for the same customer
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)    AS next_order_date,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
        - order_date                                                         AS days_to_next
FROM company.orders
ORDER BY customer_id, order_date;
-- NULL in next_order_date = most recent order for that customer (no next yet)


-- Combined LAG + LEAD: see previous AND next on the same row
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LAG(amount)  OVER (PARTITION BY customer_id ORDER BY order_date)  AS prev_amount,
    LEAD(amount) OVER (PARTITION BY customer_id ORDER BY order_date)  AS next_amount,
    CASE
        WHEN LAG(amount)  OVER (PARTITION BY customer_id ORDER BY order_date) IS NULL THEN 'First'
        WHEN LEAD(amount) OVER (PARTITION BY customer_id ORDER BY order_date) IS NULL THEN 'Last'
        ELSE 'Middle'
    END AS order_position
FROM company.orders
ORDER BY customer_id, order_date;


-- =============================================================
-- SECTION 3 — Running Totals: SUM/AVG/COUNT with ORDER BY
-- =============================================================

-- Adding ORDER BY inside a window aggregate creates a cumulative calculation.
-- Default frame: RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- = "from the first row up to and including this row"

-- Running total of orders by date (company-wide)
SELECT
    order_id,
    order_date,
    amount,
    SUM(amount)            OVER (ORDER BY order_date)    AS running_total,
    ROUND(AVG(amount) OVER (ORDER BY order_date), 2)     AS running_avg,
    COUNT(*)               OVER (ORDER BY order_date)    AS running_count
FROM company.orders
ORDER BY order_date;
-- running_total increases with every row; running_avg fluctuates


-- Running total PER CUSTOMER — resets for each customer
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    SUM(amount)  OVER (PARTITION BY customer_id ORDER BY order_date)  AS customer_running_total,
    COUNT(*)     OVER (PARTITION BY customer_id ORDER BY order_date)  AS customer_order_number
FROM company.orders
ORDER BY customer_id, order_date;


-- Running hire count per department (who joined the team over time?)
SELECT
    name,
    dept_id,
    hire_date,
    salary,
    COUNT(*)    OVER (PARTITION BY dept_id ORDER BY hire_date)  AS nth_hire_in_dept,
    SUM(salary) OVER (PARTITION BY dept_id ORDER BY hire_date)  AS running_dept_payroll
FROM company.employees
ORDER BY dept_id, hire_date;


-- =============================================================
-- SECTION 4 — ROWS BETWEEN: controlling the window frame
-- =============================================================

-- A frame defines WHICH rows the function includes relative to the current row.
-- ROWS BETWEEN = frame by row count (position)
-- RANGE BETWEEN = frame by value (affects ties differently)
--
-- Frame boundary keywords:
--   UNBOUNDED PRECEDING  — first row of partition
--   n PRECEDING          — n rows before current row
--   CURRENT ROW          — current row only
--   n FOLLOWING          — n rows after current row
--   UNBOUNDED FOLLOWING  — last row of partition

-- 3-day centered moving average (1 before + current + 1 after)
SELECT
    sale_date,
    daily_sales,
    ROUND(AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) AS moving_avg_3day
FROM company.sales_daily
ORDER BY sale_date;
-- First row: only 2 rows in frame (current + next) → average of 2
-- Last row:  only 2 rows in frame (prev + current) → average of 2


-- 7-day trailing rolling sum (current + 6 previous days)
SELECT
    sale_date,
    daily_sales,
    SUM(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )  AS rolling_7day_sum,
    ROUND(AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7day_avg
FROM company.sales_daily
ORDER BY sale_date;
-- First 6 rows have fewer than 7 days of history → partial window


-- Explicit full-partition frame = same as no ORDER BY
-- SUM OVER (PARTITION BY dept_id) and the explicit frame are identical
SELECT
    name,
    dept_id,
    salary,
    SUM(salary) OVER (PARTITION BY dept_id)                                                    AS dept_total_a,
    SUM(salary) OVER (PARTITION BY dept_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS dept_total_b
FROM company.employees
ORDER BY dept_id;
-- dept_total_a = dept_total_b on every row — confirmed equivalent


-- =============================================================
-- SECTION 5 — FIRST_VALUE, LAST_VALUE, NTH_VALUE
-- =============================================================

-- FIRST_VALUE(col) — value from the first row of the ordered window frame
-- LAST_VALUE(col)  — value from the last row (requires full frame to work correctly)
-- NTH_VALUE(col,n) — value from the Nth row (requires full frame)

-- FIRST_VALUE: highest-paid employee name per department on every row
SELECT
    name,
    dept_id,
    salary,
    FIRST_VALUE(name)   OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS top_earner,
    FIRST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS max_salary
FROM company.employees
ORDER BY dept_id, salary DESC;
-- Every employee in the same dept sees the same top_earner name


-- LAST_VALUE gotcha: WITHOUT full frame it returns the CURRENT ROW value (not last)
-- because the default frame stops at the current row.
SELECT
    name,
    dept_id,
    salary,
    LAST_VALUE(name) OVER (
        PARTITION BY dept_id ORDER BY salary DESC
    ) AS wrong_bottom_earner,   -- returns current row's name — WRONG

    LAST_VALUE(name) OVER (
        PARTITION BY dept_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS correct_bottom_earner  -- full frame: sees all rows → correct
FROM company.employees
ORDER BY dept_id, salary DESC;


-- NTH_VALUE: name of the 2nd highest paid in each department
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
-- HR has only 1 employee → second_highest_earner = NULL for Grace


-- =============================================================
-- SECTION 6 — Named WINDOW Clause
-- =============================================================

-- Repeating the same OVER() definition many times is error-prone.
-- Name it once with WINDOW, reference it as OVER w.
-- You can still extend a named window: OVER (w ORDER BY salary).

-- Without WINDOW clause — same definition repeated 4 times
SELECT
    name, dept_id, salary,
    ROW_NUMBER()  OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn,
    RANK()        OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk,
    DENSE_RANK()  OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dense_rnk,
    NTILE(3)      OVER (PARTITION BY dept_id ORDER BY salary DESC) AS tier
FROM company.employees
ORDER BY dept_id, salary DESC;


-- With WINDOW clause — defined once, referenced 4 times
SELECT
    name, dept_id, salary,
    ROW_NUMBER()  OVER w  AS rn,
    RANK()        OVER w  AS rnk,
    DENSE_RANK()  OVER w  AS dense_rnk,
    NTILE(3)      OVER w  AS tier
FROM company.employees
WINDOW w AS (PARTITION BY dept_id ORDER BY salary DESC)
ORDER BY dept_id, salary DESC;
-- Identical output; WINDOW clause version is easier to maintain


-- Multiple named windows in one query
SELECT
    name,
    dept_id,
    salary,
    hire_date,
    RANK()   OVER dept_salary   AS salary_rank_in_dept,
    ROW_NUMBER() OVER dept_hire AS hire_order_in_dept
FROM company.employees
WINDOW
    dept_salary AS (PARTITION BY dept_id ORDER BY salary DESC),
    dept_hire   AS (PARTITION BY dept_id ORDER BY hire_date ASC)
ORDER BY dept_id, salary DESC;


-- =============================================================
-- SECTION 7 — Common Mistakes
-- =============================================================

-- Mistake 1: Window function in WHERE → error
-- Window functions run after FROM/WHERE/GROUP BY — cannot be used in WHERE.
-- Fix: wrap in a subquery or CTE.

-- WRONG (commented out — would error):
-- SELECT name FROM company.employees WHERE ROW_NUMBER() OVER (ORDER BY salary DESC) = 1;

-- RIGHT — CTE:
WITH ranked AS (
    SELECT name, salary, ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
    FROM company.employees
)
SELECT name, salary FROM ranked WHERE rn = 1;

-- RIGHT — subquery:
SELECT name, salary
FROM (
    SELECT name, salary, ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
    FROM company.employees
) t
WHERE rn = 1;


-- Mistake 2: LAST_VALUE without full frame returns current row value
-- Already demonstrated in Section 5 above.
-- Rule: always add ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--       when using LAST_VALUE or NTH_VALUE.


-- Mistake 3: ORDER BY in OVER() vs ORDER BY at end of SELECT
-- These are independent — window ORDER BY controls the computation frame,
-- the trailing ORDER BY controls the display order of the result set.
SELECT
    name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS salary_rank   -- computed high-to-low
FROM company.employees
ORDER BY name;   -- displayed alphabetically — independent of window order


-- Mistake 4: SUM OVER with ORDER BY gives running total, not partition total
-- Many beginners expect SUM OVER (PARTITION BY dept ORDER BY ...) to be the
-- department total — but ORDER BY turns it into a cumulative sum.

SELECT
    name,
    dept_id,
    salary,
    -- cumulative (changes per row) — has ORDER BY:
    SUM(salary) OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS cumulative_in_dept,
    -- partition total (same for all rows in dept) — no ORDER BY:
    SUM(salary) OVER (PARTITION BY dept_id)                       AS dept_total
FROM company.employees
ORDER BY dept_id, salary DESC;


-- =============================================================
-- SECTION 8 — Combined: everything together
-- =============================================================

-- Full analytical employee view using LAG, ranking, running totals,
-- FIRST_VALUE, NTILE, and WINDOW clause in one query.

SELECT
    e.name,
    d.dept_name,
    e.salary,
    e.hire_date,

    -- Ranking within department by salary
    RANK()            OVER w_dept          AS rank_in_dept,
    DENSE_RANK()      OVER w_dept          AS dense_rank_in_dept,

    -- Company-wide salary quartile (1=lowest, 4=highest)
    NTILE(4)          OVER (ORDER BY e.salary ASC)   AS salary_quartile,

    -- Department context
    ROUND(AVG(e.salary) OVER (PARTITION BY e.dept_id), 2)  AS dept_avg,
    FIRST_VALUE(e.name) OVER w_dept                        AS dept_top_earner,
    LAST_VALUE(e.name)  OVER (
        PARTITION BY e.dept_id ORDER BY e.salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                       AS dept_bottom_earner,

    -- Running payroll by hire date within department
    SUM(e.salary) OVER (PARTITION BY e.dept_id ORDER BY e.hire_date)  AS running_dept_payroll,

    -- What % of department payroll does this person represent?
    ROUND(e.salary / SUM(e.salary) OVER (PARTITION BY e.dept_id) * 100, 2) AS pct_of_dept

FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
WINDOW w_dept AS (PARTITION BY e.dept_id ORDER BY e.salary DESC)
ORDER BY d.dept_name, rank_in_dept;


-- Month-over-month revenue change using LAG
SELECT
    month_start,
    TO_CHAR(month_start, 'Mon-YYYY')                                          AS month_label,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month_start)                          AS prev_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month_start)        AS change,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month_start), 0) * 100
    , 2)                                                                       AS pct_change
FROM (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month_start,
           SUM(amount) AS monthly_revenue
    FROM company.orders
    GROUP BY DATE_TRUNC('month', order_date)
) monthly
ORDER BY month_start;


-- Daily sales with 3-day moving avg, 7-day rolling sum, cumulative total
SELECT
    sale_date,
    daily_sales,
    ROUND(AVG(daily_sales) OVER (
        ORDER BY sale_date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2)  AS moving_avg_3day,
    SUM(daily_sales) OVER (
        ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )      AS rolling_7day_sum,
    SUM(daily_sales) OVER (ORDER BY sale_date)  AS cumulative_total,
    ROUND(daily_sales / SUM(daily_sales) OVER () * 100, 2) AS pct_of_period
FROM company.sales_daily
ORDER BY sale_date;
