-- =============================================================
-- Day 9 Practice — UNION, UNION ALL, INTERSECT, EXCEPT
-- =============================================================
-- Standalone: no dependency on any previous day's file.
-- Run this file top-to-bottom on any clean PostgreSQL database.
--
-- Tables created here:
--   company.employees_india   — emp_id, name, department, salary
--   company.employees_us      — emp_id, name, department, salary
--   company.online_orders     — order_id, customer_id, product, amount, order_date
--   company.offline_orders    — order_id, customer_id, product, amount, order_date
--   company.this_year_sales   — product, revenue, category
--   company.last_year_sales   — product, revenue, category
-- =============================================================


-- =============================================================
-- DATA SETUP
-- =============================================================

DROP SCHEMA IF EXISTS company CASCADE;
CREATE SCHEMA company;


-- India office employees
CREATE TABLE company.employees_india (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      INT
);

INSERT INTO company.employees_india (emp_id, name, department, salary) VALUES
    (1,  'Alice',   'Engineering', 90000),
    (2,  'Bob',     'Marketing',   60000),
    (3,  'Carol',   'Engineering', 85000),
    (4,  'David',   'HR',          55000),
    (5,  'Eva',     'Marketing',   62000);


-- US office employees (some overlap in names/dept, different emp_ids)
CREATE TABLE company.employees_us (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      INT
);

INSERT INTO company.employees_us (emp_id, name, department, salary) VALUES
    (6,  'Frank',   'Engineering', 110000),
    (7,  'Alice',   'Engineering',  95000),  -- same name+dept as India Alice
    (8,  'Grace',   'HR',           70000),
    (9,  'Bob',     'Marketing',    65000),  -- same name+dept as India Bob
    (10, 'Heidi',   'Finance',      80000);


-- Online orders
CREATE TABLE company.online_orders (
    order_id    INT PRIMARY KEY,
    customer_id INT,
    product     VARCHAR(50),
    amount      INT,
    order_date  DATE
);

INSERT INTO company.online_orders (order_id, customer_id, product, amount, order_date) VALUES
    (1, 101, 'Laptop',  75000, '2024-01-05'),
    (2, 102, 'Phone',   30000, '2024-01-10'),
    (3, 103, 'Tablet',  20000, '2024-02-01'),
    (4, 101, 'Laptop',  75000, '2024-02-15'),  -- duplicate of order 1 (same customer+product)
    (5, 104, 'Headset',  5000, '2024-03-01');


-- Offline (store) orders — some products overlap
CREATE TABLE company.offline_orders (
    order_id    INT PRIMARY KEY,
    customer_id INT,
    product     VARCHAR(50),
    amount      INT,
    order_date  DATE
);

INSERT INTO company.offline_orders (order_id, customer_id, product, amount, order_date) VALUES
    (101, 201, 'Phone',   32000, '2024-01-12'),
    (102, 202, 'Laptop',  75000, '2024-01-20'),
    (103, 203, 'Monitor', 15000, '2024-02-05'),
    (104, 101, 'Laptop',  75000, '2024-02-15'),  -- same customer+product+amount+date as online order 4
    (105, 204, 'Keyboard', 3000, '2024-03-10');


-- This year sales
CREATE TABLE company.this_year_sales (
    product   VARCHAR(50),
    revenue   INT,
    category  VARCHAR(50)
);

INSERT INTO company.this_year_sales (product, revenue, category) VALUES
    ('Laptop',   500000, 'Electronics'),
    ('Phone',    300000, 'Electronics'),
    ('Tablet',   150000, 'Electronics'),
    ('Desk',      80000, 'Furniture'),
    ('Chair',     60000, 'Furniture');


-- Last year sales
CREATE TABLE company.last_year_sales (
    product   VARCHAR(50),
    revenue   INT,
    category  VARCHAR(50)
);

INSERT INTO company.last_year_sales (product, revenue, category) VALUES
    ('Laptop',   450000, 'Electronics'),
    ('Phone',    280000, 'Electronics'),
    ('Monitor',  120000, 'Electronics'),  -- sold last year, not this year
    ('Desk',      80000, 'Furniture'),    -- same revenue as this year
    ('Sofa',      90000, 'Furniture');    -- sold last year, not this year


-- Sanity check
SELECT 'employees_india'  AS tbl, COUNT(*) AS rows FROM company.employees_india
UNION ALL SELECT 'employees_us',    COUNT(*) FROM company.employees_us
UNION ALL SELECT 'online_orders',   COUNT(*) FROM company.online_orders
UNION ALL SELECT 'offline_orders',  COUNT(*) FROM company.offline_orders
UNION ALL SELECT 'this_year_sales', COUNT(*) FROM company.this_year_sales
UNION ALL SELECT 'last_year_sales', COUNT(*) FROM company.last_year_sales;


-- =============================================================
-- SECTION 1 — UNION vs UNION ALL: the key difference
-- =============================================================

-- UNION ALL: keep every row from both tables, duplicates included
SELECT name, department FROM company.employees_india
UNION ALL
SELECT name, department FROM company.employees_us;
-- 10 rows — 5 from each office, Alice+Engineering and Bob+Marketing appear twice

-- UNION: same but removes duplicate rows
SELECT name, department FROM company.employees_india
UNION
SELECT name, department FROM company.employees_us;
-- 8 rows — Alice+Engineering and Bob+Marketing appear only once

-- Rule of thumb:
--   UNION ALL is faster (no dedup step) — use when duplicates are expected or don't matter
--   UNION   is slower (sorts + dedup)  — use when you need distinct rows across sources


-- =============================================================
-- SECTION 2 — UNION ALL: combine two order channels
-- =============================================================

-- Combined order feed from both channels (keep all records)
SELECT
    'Online'   AS channel,
    order_id,
    customer_id,
    product,
    amount,
    order_date
FROM company.online_orders

UNION ALL

SELECT
    'Offline'  AS channel,
    order_id,
    customer_id,
    product,
    amount,
    order_date
FROM company.offline_orders

ORDER BY order_date, channel;
-- 10 rows total — both tables fully merged with a source tag


-- =============================================================
-- SECTION 3 — UNION: deduplicate across channels
-- =============================================================

-- Find unique (customer_id, product, amount, order_date) combinations
-- that appear in either channel — remove cross-channel duplicates
SELECT customer_id, product, amount, order_date FROM company.online_orders
UNION
SELECT customer_id, product, amount, order_date FROM company.offline_orders
ORDER BY order_date;
-- customer 101's Laptop order on 2024-02-15 appears only once
-- even though it exists in both tables


-- =============================================================
-- SECTION 4 — UNION ALL for aggregation across sources
-- =============================================================

-- Total revenue per category across both years
SELECT category, SUM(revenue) AS total_revenue
FROM (
    SELECT category, revenue FROM company.this_year_sales
    UNION ALL
    SELECT category, revenue FROM company.last_year_sales
) combined
GROUP BY category
ORDER BY total_revenue DESC;
-- Aggregates treat both years as one combined dataset


-- =============================================================
-- SECTION 5 — UNION for a report with section headers
-- =============================================================

-- Produce a formatted report: India employees first, then US
-- Add a blank separator row between the two groups
SELECT emp_id, name, department, salary, 'India' AS office
FROM company.employees_india

UNION ALL

SELECT NULL, '--- US OFFICE ---', '', NULL, ''

UNION ALL

SELECT emp_id, name, department, salary, 'US'
FROM company.employees_us
ORDER BY office DESC, emp_id;


-- =============================================================
-- SECTION 6 — INTERSECT: rows that exist in BOTH sets
-- =============================================================

-- Which products were sold BOTH this year and last year?
SELECT product FROM company.this_year_sales
INTERSECT
SELECT product FROM company.last_year_sales
ORDER BY product;
-- Laptop, Phone, Desk — Monitor and Sofa only in last year; Tablet, Chair only this year


-- =============================================================
-- SECTION 7 — EXCEPT: rows in first set but NOT in second
-- =============================================================

-- Products sold this year that were NOT sold last year (new additions)
SELECT product FROM company.this_year_sales
EXCEPT
SELECT product FROM company.last_year_sales
ORDER BY product;
-- Tablet, Chair — new products this year

-- Products sold last year that are NOT sold this year (discontinued)
SELECT product FROM company.last_year_sales
EXCEPT
SELECT product FROM company.this_year_sales
ORDER BY product;
-- Monitor, Sofa — dropped from this year's catalogue


-- =============================================================
-- SECTION 8 — UNION ALL with ROW_NUMBER (dedup pattern)
-- =============================================================

-- Combine both order channels then deduplicate by
-- (customer_id, product, amount, order_date) keeping the online version first
WITH combined AS (
    SELECT 1 AS priority, order_id, customer_id, product, amount, order_date
    FROM company.online_orders
    UNION ALL
    SELECT 2 AS priority, order_id, customer_id, product, amount, order_date
    FROM company.offline_orders
),
deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, product, amount, order_date
            ORDER BY priority
        ) AS rn
    FROM combined
)
SELECT order_id, customer_id, product, amount, order_date
FROM deduped
WHERE rn = 1
ORDER BY order_date;
-- 9 rows — the cross-channel duplicate kept only the online version


-- =============================================================
-- SECTION 9 — Column count and type must match
-- =============================================================

-- WRONG — different number of columns (will error)
-- SELECT emp_id, name FROM company.employees_india
-- UNION ALL
-- SELECT emp_id, name, department FROM company.employees_us;  -- ERROR

-- WRONG — incompatible types (will error)
-- SELECT emp_id, salary  FROM company.employees_india   -- INT, INT
-- UNION ALL
-- SELECT name,  department FROM company.employees_us;   -- VARCHAR, VARCHAR → type mismatch

-- RIGHT — cast to make types compatible when needed
SELECT emp_id::TEXT AS id_or_name FROM company.employees_india
UNION ALL
SELECT name         AS id_or_name FROM company.employees_us;


-- =============================================================
-- SECTION 10 — Column names come from the FIRST SELECT
-- =============================================================

-- The column aliases in the result are always taken from the first query
SELECT name AS employee_name, salary AS annual_salary FROM company.employees_india
UNION ALL
SELECT name,                  salary                  FROM company.employees_us;
-- Result columns are named: employee_name, annual_salary
-- even though the second SELECT has no aliases


-- =============================================================
-- SECTION 11 — ORDER BY applies to the full result, not one part
-- =============================================================

-- Sort the combined employee list by salary descending
SELECT name, department, salary, 'India' AS office FROM company.employees_india
UNION ALL
SELECT name, department, salary, 'US'    AS office FROM company.employees_us
ORDER BY salary DESC;
-- ORDER BY goes ONCE at the very end — applies to the entire combined result
-- You CANNOT put ORDER BY inside individual SELECT parts of a UNION


-- =============================================================
-- SECTION 12 — Quick reference comparison
-- =============================================================

-- Same data, four operators side by side for contrast:
-- (Products only, to keep output small)

-- All products from both years (with duplicates)
SELECT 'UNION ALL'  AS operator, product FROM company.this_year_sales UNION ALL SELECT 'UNION ALL',  product FROM company.last_year_sales
UNION ALL
-- Distinct products from both years
SELECT 'UNION',     product FROM company.this_year_sales UNION     SELECT 'UNION',     product FROM company.last_year_sales
UNION ALL
-- Products in both years
SELECT 'INTERSECT', product FROM company.this_year_sales INTERSECT SELECT 'INTERSECT', product FROM company.last_year_sales
UNION ALL
-- Products only in this year
SELECT 'EXCEPT',    product FROM company.this_year_sales EXCEPT    SELECT 'EXCEPT',    product FROM company.last_year_sales
ORDER BY operator, product;
