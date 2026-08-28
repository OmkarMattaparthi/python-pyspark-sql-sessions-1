-- =============================================================
-- Day 9 — Data Engineering SQL Interview Problems
-- Source: 210 Days SQL Interview Questions (LeetCode-based)
-- Window Function patterns: Medium → Hard
-- =============================================================
-- Standalone: run this file top-to-bottom on any PostgreSQL DB.
-- All tables and data are created below.
-- Solutions are in day9_solutions.sql — do NOT open until done.
--
-- Problems selected:
--   P1 (Day 21) — Rising Temperature         LAG — consecutive row comparison
--   P2 (Day 32) — Restaurant Growth          7-day rolling average (ROWS BETWEEN)
--   P3 (Day 34) — Biggest Window Between Visits  LAG gap detection per user
--   P4 (Day 47) — Continuous Ranges          Gaps & Islands (ROW_NUMBER trick)
--   P5 (Day 27) — Most Recent Three Orders   Top-N per group (ROW_NUMBER + filter)
-- =============================================================


-- =============================================================
-- TABLE SETUP — run this entire block first
-- =============================================================

DROP SCHEMA IF EXISTS lc CASCADE;
CREATE SCHEMA lc;


-- -------------------------------------------------------
-- Table for P1: Weather
-- LeetCode #197 — Rising Temperature
-- One row per day with temperature recorded.
-- -------------------------------------------------------
CREATE TABLE lc.weather (
    id           INT PRIMARY KEY,
    record_date  DATE,
    temperature  INT
);

INSERT INTO lc.weather (id, record_date, temperature) VALUES
    (1, '2015-01-01', 10),
    (2, '2015-01-02', 25),   -- hotter than yesterday → should appear
    (3, '2015-01-03', 20),   -- cooler than yesterday → should NOT appear
    (4, '2015-01-04', 30),   -- hotter than yesterday → should appear
    (5, '2015-01-06', 15),   -- gap in dates (1/5 missing) → should NOT appear
    (6, '2015-01-07', 40),   -- hotter than yesterday → should appear
    (7, '2015-01-08', 40),   -- same temp → should NOT appear
    (8, '2015-01-09', 35);   -- cooler → should NOT appear


-- -------------------------------------------------------
-- Table for P2: Customer (Restaurant Growth)
-- LeetCode #1321 — Restaurant Growth
-- Each row is one customer visit with the amount paid.
-- Multiple visits can happen on the same day.
-- -------------------------------------------------------
CREATE TABLE lc.customer (
    customer_id   INT,
    name          VARCHAR(50),
    visited_on    DATE,
    amount        INT
);

INSERT INTO lc.customer (customer_id, name, visited_on, amount) VALUES
    (1,  'Jhon',    '2019-01-01', 100),
    (2,  'Daniel',  '2019-01-02', 110),
    (3,  'Jade',    '2019-01-03', 120),
    (4,  'Khaled',  '2019-01-04', 130),
    (5,  'Winston', '2019-01-05', 110),
    (6,  'Elvis',   '2019-01-06', 140),
    (7,  'Anna',    '2019-01-07', 150),
    (8,  'Maria',   '2019-01-08', 80),
    (9,  'Jaze',    '2019-01-09', 110),
    (1,  'Jhon',    '2019-01-10', 130),
    (3,  'Jade',    '2019-01-10', 150);


-- -------------------------------------------------------
-- Table for P3: UserVisits (Biggest Window Between Visits)
-- LeetCode #1701 — Biggest Window Between Visits
-- Each row is one visit by a user on a specific date.
-- -------------------------------------------------------
CREATE TABLE lc.user_visits (
    user_id     INT,
    visit_date  DATE
);

INSERT INTO lc.user_visits (user_id, visit_date) VALUES
    (1, '2020-11-28'),
    (1, '2020-10-20'),
    (1, '2020-12-03'),
    (2, '2020-10-05'),
    (2, '2020-12-09'),
    (3, '2020-11-11');


-- -------------------------------------------------------
-- Table for P4: logs (Continuous Ranges — Gaps & Islands)
-- LeetCode #1285 — Find the Start and End Number of Continuous Ranges
-- The logs table has integer log_id values.
-- Some IDs are missing — find the start and end of each consecutive range.
-- -------------------------------------------------------
CREATE TABLE lc.logs (
    log_id INT PRIMARY KEY
);

INSERT INTO lc.logs (log_id) VALUES
    (1), (2), (3),        -- range 1: 1-3
    (7), (8), (9), (10),  -- range 2: 7-10
    (14), (15),           -- range 3: 14-15
    (20);                 -- range 4: 20-20


-- -------------------------------------------------------
-- Table for P5: Orders + Customers (Most Recent Three Orders)
-- LeetCode #1341 — The Most Recent Three Orders
-- Show the most recent 3 orders per customer (by order_date).
-- If a customer has fewer than 3, show all of them.
-- -------------------------------------------------------
CREATE TABLE lc.customers_p5 (
    customer_id   INT PRIMARY KEY,
    name          VARCHAR(50),
    email         VARCHAR(100)
);

CREATE TABLE lc.orders_p5 (
    order_id     INT PRIMARY KEY,
    customer_id  INT REFERENCES lc.customers_p5(customer_id),
    order_date   DATE,
    cost         INT
);

INSERT INTO lc.customers_p5 VALUES
    (1, 'Winston', 'winston@example.com'),
    (2, 'Jonathan','jonathan@example.com'),
    (3, 'Annabelle','annabelle@example.com'),
    (4, 'Marwan',  'marwan@example.com'),
    (5, 'Khaled',  'khaled@example.com');

INSERT INTO lc.orders_p5 (order_id, customer_id, order_date, cost) VALUES
    (1,  2, '2020-07-31', 30),
    (2,  4, '2020-07-30', 40),
    (3,  5, '2020-07-31', 50),
    (4,  1, '2020-07-29', 100),
    (5,  3, '2020-07-31', 20),
    (6,  4, '2020-08-01', 20),
    (7,  2, '2020-08-01', 30),
    (8,  3, '2020-08-01', 20),
    (9,  3, '2020-08-02', 80),
    (10, 2, '2020-08-02', 10),
    (11, 1, '2020-08-01', 20),
    (12, 4, '2020-08-03', 40),
    (13, 1, '2020-08-03', 20),
    (14, 5, '2020-08-03', 50);


-- Sanity check
SELECT 'weather'      AS tbl, COUNT(*) AS rows FROM lc.weather
UNION ALL SELECT 'customer',    COUNT(*) FROM lc.customer
UNION ALL SELECT 'user_visits', COUNT(*) FROM lc.user_visits
UNION ALL SELECT 'logs',        COUNT(*) FROM lc.logs
UNION ALL SELECT 'orders_p5',   COUNT(*) FROM lc.orders_p5;


-- =============================================================
-- PROBLEM 1 — Rising Temperature  (Day 21 | LeetCode #197)
-- Pattern: LAG — consecutive row comparison
-- =============================================================
--
-- Find the id of all days where the temperature was HIGHER than
-- the previous day's temperature.
-- The "previous day" means EXACTLY one calendar day before
-- (record_date - 1), NOT just the previous row — there can be
-- gaps in the dates.
--
-- Expected output (3 rows):
--
--   id
--   ---
--    2     (25 > 10 on consecutive day)
--    4     (30 > 20 on consecutive day)
--    6     (40 > 15 on consecutive day)
--
-- Note: id=5 (2015-01-06, 15°) does NOT appear because
--       2015-01-05 is missing — not a consecutive day.
-- Note: id=7 (40°) does NOT appear — same temp as previous day.
--

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 2 — Restaurant Growth  (Day 32 | LeetCode #1321)
-- Pattern: 7-day rolling window (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
-- =============================================================
--
-- The restaurant wants a 7-day moving average of daily revenue
-- to smooth out weekend spikes. First aggregate daily totals
-- (multiple customers can visit the same day), then compute the
-- 7-day rolling average.
--
-- Return: visited_on, amount (7-day rolling sum), average_amount
--         (7-day rolling average, rounded to 2 decimal places).
-- Only return dates where at least 7 days of history exist
-- (i.e., the first 6 dates should be excluded from the output).
--
-- Expected output:
--
--   visited_on  | amount | average_amount
--   ------------+--------+---------------
--   2019-01-07  |  860   |  122.86
--   2019-01-08  |  840   |  120.00
--   2019-01-09  |  840   |  120.00
--   2019-01-10  |  1000  |  142.86
--

-- =============================================================

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 3 — Biggest Window Between Visits  (Day 34 | LeetCode #1701)
-- Pattern: LAG gap detection — max gap per user
-- =============================================================
--
-- For each user, find the LARGEST number of days between any two
-- consecutive visits. Also count the gap from the last visit to
-- '2021-01-01' (treat this as the "reference date" — the day after
-- the observation window ends).
--
-- Return: user_id, biggest_window (maximum gap in days for that user).
-- Sort by user_id.
--
-- Expected output:
--
--   user_id | biggest_window
--   --------+---------------
--         1 |     36          (2020-12-03 → 2021-01-01 = 29 days,
--                              2020-10-20 → 2020-11-28 = 39 days, etc.)
--         2 |     65          (2020-10-05 → 2020-12-09 = 65 days)
--         3 |     51          (2020-11-11 → 2021-01-01 = 51 days)
--

-- =============================================================

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 4 — Continuous Ranges (Gaps & Islands)  (Day 47 | LeetCode #1285)
-- Pattern: ROW_NUMBER subtraction trick — the classic gaps & islands
-- =============================================================
--
-- Find the start and end of each consecutive range of log_id values.
-- Consecutive means no gaps — 1,2,3 is one range; 1,2,5 gives ranges 1-2 and 5-5.
--
-- Return: start_id, end_id for each continuous range.
-- Sort by start_id.
--
-- Expected output (4 rows):
--
--   start_id | end_id
--   ---------+-------
--          1 |      3
--          7 |     10
--         14 |     15
--         20 |     20
--
-- =============================================================

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 5 — Most Recent Three Orders  (Day 27 | LeetCode #1341)
-- Pattern: ROW_NUMBER per partition → Top-N per group filter
-- =============================================================
--
-- For each customer, return their most recent 3 orders.
-- If a customer has fewer than 3 orders, return all of them.
-- Show: customer_name, customer_email, order_id, order_date, cost.
-- Sort by customer_name ascending, then order_date descending.
-- If two orders share the same date, sort by order_id ascending.
--
-- Expected output (12 rows — some customers have < 3 orders):
--
--   customer_name | customer_email           | order_id | order_date  | cost
--   --------------+--------------------------+----------+-------------+------
--   Annabelle     | annabelle@example.com    |       9  | 2020-08-02  |  80
--   Annabelle     | annabelle@example.com    |       5  | 2020-07-31  |  20
--   Annabelle     | annabelle@example.com    |       8  | 2020-08-01  |  20
--   Jonathan      | jonathan@example.com     |      10  | 2020-08-02  |  10
--   Jonathan      | jonathan@example.com     |       7  | 2020-08-01  |  30
--   Jonathan      | jonathan@example.com     |       1  | 2020-07-31  |  30
--   Khaled        | khaled@example.com       |      14  | 2020-08-03  |  50
--   Khaled        | khaled@example.com       |       3  | 2020-07-31  |  50
--   Marwan        | marwan@example.com       |      12  | 2020-08-03  |  40
--   Marwan        | marwan@example.com       |       6  | 2020-08-01  |  20
--   Marwan        | marwan@example.com       |       2  | 2020-07-30  |  40
--   Winston       | winston@example.com      |      13  | 2020-08-03  |  20
--   Winston       | winston@example.com      |      11  | 2020-08-01  |  20
--   Winston       | winston@example.com      |       4  | 2020-07-29  | 100
--

-- =============================================================

-- YOUR ANSWER:
