-- =============================================================
-- Day 9 — Data Engineering SQL Interview Problems
-- Medium → Advanced Level
-- =============================================================
-- Standalone: run this file top-to-bottom on any PostgreSQL DB.
-- All tables and data are created below.
-- Solutions are in day9_solutions.sql — do NOT open until done.
--
-- Topics tested per problem:
--   P1 — Deduplication with ROW_NUMBER (CDC / late-arriving data)
--   P2 — Running total + % of group (cumulative revenue analysis)
--   P3 — Gap detection with LAG (churn / SLA breach detection)
--   P4 — Top-N per group + conditional aggregation (product performance)
--   P5 — Date spine gap-fill + month-over-month with LAG (reporting)
-- =============================================================


-- =============================================================
-- TABLE SETUP — run this entire block first
-- =============================================================

DROP SCHEMA IF EXISTS de_interview CASCADE;
CREATE SCHEMA de_interview;


-- -------------------------------------------------------
-- Table 1: raw_events
-- Simulates a CDC (Change Data Capture) stream from a source system.
-- The same customer record can appear multiple times with different
-- updated_at timestamps — the latest row is the "true" current state.
-- -------------------------------------------------------
CREATE TABLE de_interview.raw_events (
    event_id    SERIAL PRIMARY KEY,
    customer_id INT,
    name        VARCHAR(100),
    email       VARCHAR(150),
    tier        VARCHAR(20),
    salary      NUMERIC(10,2),
    updated_at  TIMESTAMP
);

INSERT INTO de_interview.raw_events (customer_id, name, email, tier, salary, updated_at) VALUES
    -- customer 1: appeared 3 times — latest is 2024-03-10
    (1, 'Alice',   'alice@old.com',     'Silver', 55000, '2024-01-01 10:00:00'),
    (1, 'Alice',   'alice@new.com',     'Gold',   65000, '2024-03-10 09:00:00'),
    (1, 'Alice',   'alice@new.com',     'Silver', 58000, '2024-02-15 14:00:00'),
    -- customer 2: appeared twice — latest is 2024-02-20
    (2, 'Bob',     'bob@example.com',   'Bronze', 42000, '2024-01-15 08:00:00'),
    (2, 'Bob',     'bob@example.com',   'Silver', 50000, '2024-02-20 11:00:00'),
    -- customer 3: appeared once
    (3, 'Carol',   'carol@example.com', 'Gold',   72000, '2024-01-20 16:00:00'),
    -- customer 4: appeared 4 times — salary keeps changing
    (4, 'David',   'david@example.com', 'Bronze', 30000, '2024-01-05 07:00:00'),
    (4, 'David',   'david@example.com', 'Silver', 38000, '2024-02-01 10:00:00'),
    (4, 'David',   'david@example.com', 'Gold',   45000, '2024-03-15 15:00:00'),
    (4, 'David',   'david@example.com', 'Gold',   48000, '2024-04-02 09:30:00'),
    -- customer 5: appeared twice with conflicting tier
    (5, 'Eva',     'eva@example.com',   'Silver', 60000, '2024-02-10 12:00:00'),
    (5, 'Eva',     'eva@example.com',   'Gold',   60000, '2024-03-01 08:00:00');


-- -------------------------------------------------------
-- Table 2: orders
-- Each row is one order. Used for running total and gap analysis.
-- -------------------------------------------------------
CREATE TABLE de_interview.orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT,
    order_date  DATE,
    amount      NUMERIC(10,2),
    status      VARCHAR(20)
);

INSERT INTO de_interview.orders (customer_id, order_date, amount, status) VALUES
    (1, '2024-01-05',  5000.00, 'delivered'),
    (1, '2024-01-18',  3200.00, 'delivered'),
    (1, '2024-02-10',  7500.00, 'delivered'),
    (1, '2024-04-20',  4100.00, 'delivered'),   -- gap > 30 days from previous
    (1, '2024-06-01',  6200.00, 'delivered'),   -- gap > 30 days
    (2, '2024-01-10',  8000.00, 'delivered'),
    (2, '2024-01-28',  2500.00, 'delivered'),
    (2, '2024-02-14',  4500.00, 'delivered'),
    (2, '2024-03-22',  9000.00, 'delivered'),
    (2, '2024-04-28', 11000.00, 'delivered'),
    (3, '2024-02-01', 12000.00, 'delivered'),
    (3, '2024-05-05',  3500.00, 'delivered'),   -- gap > 30 days
    (4, '2024-01-15',  1500.00, 'delivered'),
    (4, '2024-03-10',  2200.00, 'delivered'),   -- gap > 30 days
    (4, '2024-03-25',  1800.00, 'delivered'),
    (5, '2024-02-08',  6500.00, 'delivered'),
    (5, '2024-02-22',  4300.00, 'delivered'),
    (5, '2024-03-15',  5100.00, 'delivered'),
    (5, '2024-05-01',  7200.00, 'delivered');   -- gap > 30 days


-- -------------------------------------------------------
-- Table 3: product_sales
-- Daily sales by product and category. Used for top-N and pivot.
-- -------------------------------------------------------
CREATE TABLE de_interview.product_sales (
    sale_id      SERIAL PRIMARY KEY,
    sale_date    DATE,
    category     VARCHAR(50),
    product_name VARCHAR(100),
    units_sold   INT,
    revenue      NUMERIC(10,2)
);

INSERT INTO de_interview.product_sales (sale_date, category, product_name, units_sold, revenue) VALUES
    ('2024-01-01', 'Electronics', 'Laptop Pro',    3, 240000),
    ('2024-01-01', 'Electronics', 'Wireless Mouse',10,  15000),
    ('2024-01-01', 'Electronics', 'Monitor 4K',    2,  40000),
    ('2024-01-01', 'Furniture',   'Standing Desk', 4,  88000),
    ('2024-01-01', 'Furniture',   'Office Chair',  6,  72000),
    ('2024-01-01', 'Furniture',   'Desk Lamp',     8,  20000),
    ('2024-01-01', 'Stationery',  'Notebook Pack', 50,  20000),
    ('2024-01-01', 'Stationery',  'Parker Pen Set',20,   5000),
    ('2024-02-01', 'Electronics', 'Laptop Pro',    5, 400000),
    ('2024-02-01', 'Electronics', 'Wireless Mouse',15,  22500),
    ('2024-02-01', 'Electronics', 'Monitor 4K',    3,  60000),
    ('2024-02-01', 'Furniture',   'Standing Desk', 2,  44000),
    ('2024-02-01', 'Furniture',   'Office Chair',  4,  48000),
    ('2024-02-01', 'Furniture',   'Desk Lamp',     12, 30000),
    ('2024-02-01', 'Stationery',  'Notebook Pack', 30,  12000),
    ('2024-02-01', 'Stationery',  'Parker Pen Set',40,  10000),
    ('2024-03-01', 'Electronics', 'Laptop Pro',    2, 160000),
    ('2024-03-01', 'Electronics', 'Wireless Mouse',20,  30000),
    ('2024-03-01', 'Electronics', 'Monitor 4K',    6, 120000),
    ('2024-03-01', 'Furniture',   'Standing Desk', 5, 110000),
    ('2024-03-01', 'Furniture',   'Office Chair',  8,  96000),
    ('2024-03-01', 'Furniture',   'Desk Lamp',     5,  12500),
    ('2024-03-01', 'Stationery',  'Notebook Pack', 70,  28000),
    ('2024-03-01', 'Stationery',  'Parker Pen Set',10,   2500);


-- -------------------------------------------------------
-- Table 4: daily_revenue
-- One row per day. Used for date spine and MoM analysis.
-- Deliberately missing some months (April, July 2024) → gap demo.
-- -------------------------------------------------------
CREATE TABLE de_interview.daily_revenue (
    rev_date DATE PRIMARY KEY,
    revenue  NUMERIC(10,2)
);

INSERT INTO de_interview.daily_revenue (rev_date, revenue) VALUES
    ('2024-01-31', 85000), ('2024-02-29', 72000),
    ('2024-03-31', 98000),
    -- April 2024 MISSING intentionally
    ('2024-05-31', 61000), ('2024-06-30', 74000),
    -- July 2024 MISSING intentionally
    ('2024-08-31', 89000), ('2024-09-30', 95000),
    ('2024-10-31',110000), ('2024-11-30', 92000),
    ('2024-12-31',130000);


-- Sanity check
SELECT 'raw_events'    AS tbl, COUNT(*) AS rows FROM de_interview.raw_events
UNION ALL
SELECT 'orders',       COUNT(*) FROM de_interview.orders
UNION ALL
SELECT 'product_sales',COUNT(*) FROM de_interview.product_sales
UNION ALL
SELECT 'daily_revenue',COUNT(*) FROM de_interview.daily_revenue;


-- =============================================================
-- PROBLEM 1 — Deduplication (CDC / Late-arriving data)
-- =============================================================
-- The raw_events table simulates a CDC stream where the same
-- customer_id can appear multiple times with different updated_at
-- timestamps. Each new row represents an updated state of that customer.
--
-- Task: Write a query that returns ONE row per customer_id —
-- specifically the row with the LATEST updated_at timestamp.
-- Show: customer_id, name, email, tier, salary, updated_at.
--
-- Expected output (5 rows — one per customer):
--
--   customer_id | name  | email              | tier   | salary   | updated_at
--   ------------+-------+--------------------+--------+----------+---------------------
--             1 | Alice | alice@new.com      | Gold   | 65000.00 | 2024-03-10 09:00:00
--             2 | Bob   | bob@example.com    | Silver | 50000.00 | 2024-02-20 11:00:00
--             3 | Carol | carol@example.com  | Gold   | 72000.00 | 2024-01-20 16:00:00
--             4 | David | david@example.com  | Gold   | 48000.00 | 2024-04-02 09:30:00
--             5 | Eva   | eva@example.com    | Gold   | 60000.00 | 2024-03-01 08:00:00
--
-- Hint: Use ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC)
--       in a CTE, then filter WHERE rn = 1.
-- =============================================================

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 2 — Running Total + Cumulative % of Group
-- =============================================================
-- Using the orders table, write a query that shows for each order:
--   - customer_id
--   - order_date
--   - amount
--   - customer_running_total  : cumulative sum of amount for that customer,
--                               ordered by order_date
--   - customer_total          : total amount spent by that customer (all orders)
--   - pct_of_customer_total   : customer_running_total / customer_total * 100,
--                               rounded to 2 decimal places
--
-- This shows at what point each customer hit what % of their total spend.
--
-- Expected output (19 rows, ordered by customer_id, order_date):
--
--   customer_id | order_date | amount   | customer_running_total | customer_total | pct_of_customer_total
--   ------------+------------+----------+------------------------+----------------+----------------------
--             1 | 2024-01-05 |  5000.00 |               5000.00 |       26000.00 |                 19.23
--             1 | 2024-01-18 |  3200.00 |               8200.00 |       26000.00 |                 31.54
--             1 | 2024-02-10 |  7500.00 |              15700.00 |       26000.00 |                 60.38
--             ...
--
-- Hint: Use SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date)
--       for running total, and SUM(amount) OVER (PARTITION BY customer_id)
--       (no ORDER BY) for the full customer total.
-- =============================================================

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 3 — Gap Detection (Churn Signal)
-- =============================================================
-- A data engineering team wants to flag orders where a customer
-- went more than 30 days without placing an order. These represent
-- potential churn events or SLA breach windows.
--
-- Task: Write a query that shows, for each order, the gap in days
-- since that customer's PREVIOUS order. Flag orders where the gap
-- is more than 30 days as a churn signal.
--
-- Show: customer_id, order_date, amount, prev_order_date,
--       gap_days, is_churn_signal ('Yes' if gap > 30, 'No' otherwise,
--       NULL/first order shows 'First Order').
--
-- Expected output (19 rows):
--
--   customer_id | order_date | amount    | prev_order_date | gap_days | is_churn_signal
--   ------------+------------+-----------+-----------------+----------+----------------
--             1 | 2024-01-05 |  5000.00  | NULL            | NULL     | First Order
--             1 | 2024-01-18 |  3200.00  | 2024-01-05      |    13    | No
--             1 | 2024-02-10 |  7500.00  | 2024-01-18      |    23    | No
--             1 | 2024-04-20 |  4100.00  | 2024-02-10      |    70    | Yes
--             1 | 2024-06-01 |  6200.00  | 2024-04-20      |    42    | Yes
--             ...
--
-- Hint: Use LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
--       Then subtract dates and apply CASE.
-- =============================================================

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 4 — Top 2 Products per Category + Conditional Aggregation
-- =============================================================
-- Using product_sales, answer two things in one query block:
--
-- Part A: For each category, show the TOP 2 products by total revenue
--         across all months. Show: category, product_name, total_revenue,
--         total_units, rank_in_category.
--
-- Part B: For each category, show a monthly revenue pivot with these
--         columns: category, jan_revenue, feb_revenue, mar_revenue,
--         total_revenue. Use conditional aggregation (SUM + CASE or FILTER).
--
-- Part A Expected output (6 rows — 2 per category):
--
--   category    | product_name    | total_revenue | total_units | rank_in_category
--   ------------+-----------------+---------------+-------------+-----------------
--   Electronics | Laptop Pro      |    800000.00  |     10      |        1
--   Electronics | Monitor 4K      |    220000.00  |     11      |        2
--   Furniture   | Standing Desk   |    242000.00  |     11      |        1
--   Furniture   | Office Chair    |    216000.00  |     18      |        2
--   Stationery  | Notebook Pack   |     60000.00  |    150      |        1
--   Stationery  | Parker Pen Set  |     17500.00  |     70      |        2
--
-- Part B Expected output (3 rows — one per category):
--
--   category    | jan_revenue | feb_revenue | mar_revenue | total_revenue
--   ------------+-------------+-------------+-------------+--------------
--   Electronics |    295000   |    482500   |    310000   |   1087500
--   Furniture   |    180000   |    122000   |    218500   |    520500
--   Stationery  |     25000   |     22000   |     30500   |     77500
--
-- Hint Part A: Aggregate by category + product first in a CTE,
--             then apply RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC).
--             Filter WHERE rank <= 2 in the outer query.
--
-- Hint Part B: SUM(revenue) FILTER (WHERE EXTRACT(MONTH FROM sale_date) = 1)
--              or SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 1 THEN revenue ELSE 0 END)
-- =============================================================

-- Part A — YOUR ANSWER:


-- Part B — YOUR ANSWER:


-- =============================================================
-- PROBLEM 5 — Date Spine + Month-over-Month Revenue Change
-- =============================================================
-- The daily_revenue table has monthly summary rows but is MISSING
-- April 2024 and July 2024 entirely.
--
-- Task: Write a query that:
--   1. Generates a complete date spine for all 12 months of 2024
--      using generate_series.
--   2. LEFT JOINs daily_revenue onto the spine so missing months
--      show revenue = 0.
--   3. Uses LAG to compute the previous month's revenue.
--   4. Computes month-over-month change and percentage change.
--   5. Labels each month's trend: 'Growth', 'Decline', 'Flat', or 'No Data'
--      (No Data = current month has 0 revenue).
--
-- Show: month_label (e.g. 'Jan-2024'), revenue, prev_revenue,
--       mom_change, mom_pct_change (rounded to 2 dp), trend.
--
-- Expected output (12 rows):
--
--   month_label | revenue   | prev_revenue | mom_change | mom_pct_change | trend
--   ------------+-----------+--------------+------------+----------------+-------
--   Jan-2024    |  85000.00 | NULL         | NULL       | NULL           | Growth
--   Feb-2024    |  72000.00 | 85000.00     | -13000.00  | -15.29         | Decline
--   Mar-2024    |  98000.00 | 72000.00     |  26000.00  |  36.11         | Growth
--   Apr-2024    |      0.00 | 98000.00     | -98000.00  |-100.00         | No Data
--   May-2024    |  61000.00 |      0.00    |  61000.00  | NULL           | Growth
--   Jun-2024    |  74000.00 | 61000.00     |  13000.00  |  21.31         | Growth
--   Jul-2024    |      0.00 | 74000.00     | -74000.00  |-100.00         | No Data
--   Aug-2024    |  89000.00 |      0.00    |  89000.00  | NULL           | Growth
--   Sep-2024    |  95000.00 | 89000.00     |   6000.00  |   6.74         | Growth
--   Oct-2024    | 110000.00 | 95000.00     |  15000.00  |  15.79         | Growth
--   Nov-2024    |  92000.00 |110000.00     | -18000.00  | -16.36         | Decline
--   Dec-2024    | 130000.00 | 92000.00     |  38000.00  |  41.30         | Growth
--
-- Hint: generate_series('2024-01-01'::DATE, '2024-12-01'::DATE, '1 month')
--       LEFT JOIN daily_revenue on DATE_TRUNC('month', rev_date)::DATE = spine.month
--       COALESCE(revenue, 0) for missing months
--       LAG on the spine-joined revenue for prev_revenue
--       NULLIF(prev_revenue, 0) in denominator to avoid division by zero
-- =============================================================

-- YOUR ANSWER:
