-- =============================================================
-- Day 5 Practice — DateTime: Functions, GROUP BY Time,
--                  generate_series, Epoch
-- =============================================================
-- Standalone: no dependency on any previous day's file.
-- Run this file top-to-bottom on any clean PostgreSQL database.
--
-- Tables created here:
--   sales.customers   — customer_id, name, city, tier, signup_date
--   sales.products    — product_id, product_name, category, price
--   sales.orders      — order_id, customer_id, order_date, status
--   sales.order_items — order_item_id, order_id, product_id, quantity, unit_price
--   sales.events      — event_id, event_type, occurred_at (epoch BIGINT)


-- =============================================================
-- DATA SETUP — schema + purposeful data for all DateTime demos
-- =============================================================
--
-- What the data is designed to show:
--   DATE extraction   → orders across multiple years/months/quarters
--   DATE_TRUNC        → grouping orders by month, quarter, year
--   generate_series   → some months have 0 orders (gap-fill demo)
--   Epoch             → events table stores BIGINT timestamps
--   AGE / difference  → customers signed up long before their first order
--   Weekday pattern   → orders on different days of the week
-- -------------------------------------------------------------


-- Step 1: Drop and recreate schema cleanly
DROP SCHEMA IF EXISTS sales CASCADE;
CREATE SCHEMA sales;


-- Step 2: Customers
--
--   customer_id | name    | city      | tier   | signup_date
--   ------------+---------+-----------+--------+------------
--           1   | Alice   | Mumbai    | Gold   | 2021-03-15   ← signed up 3 years before orders
--           2   | Bob     | Pune      | Silver | 2022-07-01
--           3   | Carol   | Mumbai    | Bronze | 2023-01-20
--           4   | David   | Bangalore | Gold   | 2020-11-10   ← earliest signup
--           5   | Eva     | Pune      | Silver | 2023-06-05
--           6   | Frank   | Hyderabad | Bronze | 2024-01-01
--           7   | Grace   | Delhi     | Gold   | 2022-09-18

CREATE TABLE sales.customers (
    customer_id  SERIAL       PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    city         VARCHAR(50),
    tier         VARCHAR(20),
    signup_date  DATE
);

INSERT INTO sales.customers (name, city, tier, signup_date) VALUES
    ('Alice',  'Mumbai',    'Gold',   '2021-03-15'),  -- customer_id = 1
    ('Bob',    'Pune',      'Silver', '2022-07-01'),  -- customer_id = 2
    ('Carol',  'Mumbai',    'Bronze', '2023-01-20'),  -- customer_id = 3
    ('David',  'Bangalore', 'Gold',   '2020-11-10'),  -- customer_id = 4
    ('Eva',    'Pune',      'Silver', '2023-06-05'),  -- customer_id = 5
    ('Frank',  'Hyderabad', 'Bronze', '2024-01-01'),  -- customer_id = 6
    ('Grace',  'Delhi',     'Gold',   '2022-09-18');  -- customer_id = 7


-- Step 3: Products
CREATE TABLE sales.products (
    product_id    SERIAL       PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category      VARCHAR(50),
    price         NUMERIC(10,2)
);

INSERT INTO sales.products (product_name, category, price) VALUES
    ('Laptop Pro',    'Electronics', 80000.00),  -- product_id = 1
    ('Wireless Mouse','Electronics',  1500.00),  -- product_id = 2
    ('Office Chair',  'Furniture',   12000.00),  -- product_id = 3
    ('Standing Desk', 'Furniture',   22000.00),  -- product_id = 4
    ('Notebook Pack', 'Stationery',    400.00),  -- product_id = 5
    ('Monitor 27"',   'Electronics', 20000.00),  -- product_id = 6
    ('Desk Lamp',     'Furniture',    2500.00);  -- product_id = 7


-- Step 4: Orders — spread across 2023 and 2024 to demonstrate time-based grouping
--
-- Deliberate gaps:
--   No orders in Feb 2024 or May 2024 → generate_series gap-fill demo
--   Orders in multiple years → year/quarter grouping demo
--   Orders on different weekdays → day-of-week pattern demo

CREATE TABLE sales.orders (
    order_id     SERIAL      PRIMARY KEY,
    customer_id  INT         REFERENCES sales.customers(customer_id),
    order_date   DATE        NOT NULL,
    status       VARCHAR(20)
);

INSERT INTO sales.orders (customer_id, order_date, status) VALUES
    -- 2023 orders
    (1, '2023-01-10', 'delivered'),   -- order_id = 1   Q1 2023  Tuesday
    (2, '2023-02-14', 'delivered'),   -- order_id = 2   Q1 2023  Tuesday
    (3, '2023-03-22', 'delivered'),   -- order_id = 3   Q1 2023  Wednesday
    (4, '2023-05-05', 'delivered'),   -- order_id = 4   Q2 2023  Friday
    (1, '2023-07-19', 'delivered'),   -- order_id = 5   Q3 2023  Wednesday
    (5, '2023-08-30', 'shipped'),     -- order_id = 6   Q3 2023  Wednesday
    (2, '2023-10-11', 'delivered'),   -- order_id = 7   Q4 2023  Wednesday
    (7, '2023-11-25', 'delivered'),   -- order_id = 8   Q4 2023  Saturday
    (3, '2023-12-03', 'cancelled'),   -- order_id = 9   Q4 2023  Sunday
    -- 2024 orders — intentional gaps in Feb and May
    (4, '2024-01-08', 'delivered'),   -- order_id = 10  Q1 2024  Monday
    (6, '2024-01-22', 'delivered'),   -- order_id = 11  Q1 2024  Monday
    (1, '2024-03-15', 'delivered'),   -- order_id = 12  Q1 2024  Friday
    (5, '2024-04-02', 'pending'),     -- order_id = 13  Q2 2024  Tuesday
    (7, '2024-06-10', 'delivered'),   -- order_id = 14  Q2 2024  Monday
    (2, '2024-07-04', 'delivered'),   -- order_id = 15  Q3 2024  Thursday
    (4, '2024-08-20', 'delivered'),   -- order_id = 16  Q3 2024  Tuesday
    (6, '2024-09-13', 'shipped'),     -- order_id = 17  Q3 2024  Friday
    (3, '2024-10-28', 'delivered'),   -- order_id = 18  Q4 2024  Monday
    (1, '2024-11-11', 'delivered'),   -- order_id = 19  Q4 2024  Monday
    (7, '2024-12-05', 'delivered');   -- order_id = 20  Q4 2024  Thursday


-- Step 5: Order items
CREATE TABLE sales.order_items (
    order_item_id  SERIAL       PRIMARY KEY,
    order_id       INT          REFERENCES sales.orders(order_id),
    product_id     INT          REFERENCES sales.products(product_id),
    quantity       INT          NOT NULL,
    unit_price     NUMERIC(10,2) NOT NULL
);

INSERT INTO sales.order_items (order_id, product_id, quantity, unit_price) VALUES
    (1,  1, 1, 80000.00),
    (2,  2, 2,  1500.00),
    (3,  3, 1, 12000.00),
    (4,  6, 1, 20000.00),
    (5,  4, 1, 22000.00),
    (6,  5, 5,   400.00),
    (7,  2, 1,  1500.00),
    (8,  7, 2,  2500.00),
    (9,  5, 3,   400.00),
    (10, 1, 1, 80000.00),
    (10, 2, 1,  1500.00),
    (11, 6, 1, 20000.00),
    (12, 3, 1, 12000.00),
    (13, 4, 1, 22000.00),
    (14, 1, 1, 80000.00),
    (15, 6, 2, 20000.00),
    (16, 1, 1, 80000.00),
    (17, 7, 3,  2500.00),
    (18, 3, 1, 12000.00),
    (19, 2, 4,  1500.00),
    (20, 1, 1, 80000.00);


-- Step 6: Events table — epoch-based timestamps (clickstream / log data)
--
-- occurred_at stores Unix epoch seconds (BIGINT)
-- Deliberate spread: events across Jan–Mar 2024 at various hours

CREATE TABLE sales.events (
    event_id    SERIAL       PRIMARY KEY,
    event_type  VARCHAR(50),
    user_id     INT,
    occurred_at BIGINT       -- Unix epoch seconds
);

INSERT INTO sales.events (event_type, user_id, occurred_at) VALUES
    -- 2024-01-15 events (various hours)
    ('page_view',   1, 1705276800),   -- 2024-01-15 00:00:00
    ('page_view',   2, 1705284000),   -- 2024-01-15 02:00:00
    ('add_to_cart', 1, 1705309200),   -- 2024-01-15 09:00:00
    ('add_to_cart', 3, 1705312800),   -- 2024-01-15 10:00:00
    ('purchase',    1, 1705316400),   -- 2024-01-15 11:00:00
    ('page_view',   4, 1705320000),   -- 2024-01-15 12:00:00
    ('add_to_cart', 2, 1705323600),   -- 2024-01-15 13:00:00
    ('purchase',    3, 1705327200),   -- 2024-01-15 14:00:00
    ('page_view',   5, 1705330800),   -- 2024-01-15 15:00:00
    ('page_view',   1, 1705334400),   -- 2024-01-15 16:00:00
    -- 2024-02-20 events
    ('page_view',   2, 1708387200),   -- 2024-02-20 00:00:00
    ('add_to_cart', 4, 1708416000),   -- 2024-02-20 08:00:00
    ('purchase',    2, 1708419600),   -- 2024-02-20 09:00:00
    ('page_view',   6, 1708423200),   -- 2024-02-20 10:00:00
    ('add_to_cart', 5, 1708430400),   -- 2024-02-20 12:00:00
    -- 2024-03-10 events
    ('page_view',   7, 1710028800),   -- 2024-03-10 00:00:00
    ('purchase',    6, 1710064800),   -- 2024-03-10 10:00:00
    ('page_view',   3, 1710072000),   -- 2024-03-10 12:00:00
    ('add_to_cart', 7, 1710079200),   -- 2024-03-10 14:00:00
    ('purchase',    4, 1710086400);   -- 2024-03-10 16:00:00


-- Sanity check: row counts
-- Expected: customers=7, products=7, orders=20, order_items=21, events=20
SELECT 'customers'   AS tbl, COUNT(*) AS rows FROM sales.customers
UNION ALL
SELECT 'products',   COUNT(*) FROM sales.products
UNION ALL
SELECT 'orders',     COUNT(*) FROM sales.orders
UNION ALL
SELECT 'order_items',COUNT(*) FROM sales.order_items
UNION ALL
SELECT 'events',     COUNT(*) FROM sales.events;


-- =============================================================
-- SECTION 1 — Current Date and Time Functions
-- =============================================================

-- Getting the current date and time — four equivalent ways
-- CURRENT_DATE returns only the date (no time component)
-- NOW() and CURRENT_TIMESTAMP return timestamp with timezone
-- LOCALTIME / LOCALTIMESTAMP return without timezone

SELECT
    CURRENT_DATE                         AS today,
    NOW()                                AS now_with_tz,
    CURRENT_TIMESTAMP                    AS current_ts,
    LOCALTIME                            AS local_time,
    LOCALTIMESTAMP                       AS local_ts;


-- =============================================================
-- SECTION 2 — EXTRACT: pulling parts out of a date
-- =============================================================

-- EXTRACT returns a numeric value for the requested field.
-- DATE_PART does the same thing — different syntax, identical result.
-- Useful for filtering by month/year/quarter without string formatting.

SELECT
    order_id,
    order_date,
    EXTRACT(YEAR    FROM order_date)  AS order_year,
    EXTRACT(MONTH   FROM order_date)  AS order_month,
    EXTRACT(DAY     FROM order_date)  AS order_day,
    EXTRACT(QUARTER FROM order_date)  AS order_quarter,
    EXTRACT(WEEK    FROM order_date)  AS iso_week,
    EXTRACT(DOW     FROM order_date)  AS day_of_week,   -- 0=Sun, 1=Mon … 6=Sat
    EXTRACT(DOY     FROM order_date)  AS day_of_year
FROM sales.orders
ORDER BY order_date;


-- DATE_PART — identical to EXTRACT, older syntax
-- Shown here so you recognise both in real-world queries

SELECT
    order_id,
    order_date,
    DATE_PART('year',  order_date)  AS order_year,
    DATE_PART('month', order_date)  AS order_month,
    DATE_PART('dow',   order_date)  AS day_of_week
FROM sales.orders
ORDER BY order_date;


-- Filter: orders placed in Q1 (months 1, 2, 3) of any year
SELECT order_id, order_date
FROM sales.orders
WHERE EXTRACT(QUARTER FROM order_date) = 1
ORDER BY order_date;


-- Filter: orders placed on a Monday (DOW = 1)
SELECT order_id, order_date
FROM sales.orders
WHERE EXTRACT(DOW FROM order_date) = 1
ORDER BY order_date;


-- =============================================================
-- SECTION 3 — DATE_TRUNC: snap a date to the start of a unit
-- =============================================================

-- DATE_TRUNC rounds a date DOWN to the beginning of the given unit.
-- This is the preferred way to group by month/quarter/year because
-- it keeps the full date context (year + month + day = 1).
-- Grouping by EXTRACT(MONTH) alone would merge Jan-2023 with Jan-2024.

SELECT
    order_id,
    order_date,
    DATE_TRUNC('year',    order_date)::DATE  AS year_start,
    DATE_TRUNC('quarter', order_date)::DATE  AS quarter_start,
    DATE_TRUNC('month',   order_date)::DATE  AS month_start,
    DATE_TRUNC('week',    order_date)::DATE  AS week_start    -- Monday
FROM sales.orders
ORDER BY order_date;


-- Group by month — how many orders per month?
-- DATE_TRUNC preserves year+month so 2023-01 and 2024-01 stay separate.

SELECT
    DATE_TRUNC('month', order_date)::DATE  AS order_month,
    COUNT(*)                               AS order_count
FROM sales.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;


-- Group by quarter — total revenue per quarter (delivered orders only)
SELECT
    DATE_TRUNC('quarter', o.order_date)::DATE  AS quarter_start,
    SUM(oi.quantity * oi.unit_price)           AS total_revenue
FROM sales.orders      o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'delivered'
GROUP BY DATE_TRUNC('quarter', o.order_date)
ORDER BY quarter_start;


-- =============================================================
-- SECTION 4 — TO_CHAR: formatting dates as strings
-- =============================================================

-- TO_CHAR converts a date/timestamp to a formatted string.
-- Use for human-readable labels in reports.
-- Do NOT use TO_CHAR in GROUP BY — it returns a string and loses sort order.
-- Use DATE_TRUNC for grouping; use TO_CHAR only in SELECT for display.

SELECT
    order_id,
    order_date,
    TO_CHAR(order_date, 'DD-Mon-YYYY')        AS fmt_dmy,       -- '10-Jan-2024'
    TO_CHAR(order_date, 'Month YYYY')         AS fmt_month_year, -- 'January  2024'
    TO_CHAR(order_date, 'Mon-YY')             AS fmt_mon_yy,    -- 'Jan-24'
    TO_CHAR(order_date, 'YYYY-"Q"Q')          AS fmt_quarter,   -- '2024-Q1'
    TO_CHAR(order_date, 'Day')                AS fmt_day_name   -- 'Monday   '
FROM sales.orders
ORDER BY order_date;


-- Monthly revenue report with a readable label
-- Pattern: DATE_TRUNC for grouping, TO_CHAR for display label

SELECT
    DATE_TRUNC('month', o.order_date)::DATE          AS month_start,
    TO_CHAR(o.order_date, 'Mon-YYYY')                AS month_label,
    COUNT(DISTINCT o.order_id)                       AS order_count,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)    AS revenue
FROM sales.orders      o
JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_date), TO_CHAR(o.order_date, 'Mon-YYYY')
ORDER BY month_start;


-- =============================================================
-- SECTION 5 — Date Arithmetic: adding and subtracting intervals
-- =============================================================

-- Add/subtract INTERVAL to get a new date or timestamp.
-- INTERVAL can be written as a string: '3 months', '10 days', '1 year 6 months'

SELECT
    '2024-01-15'::DATE + INTERVAL '3 months'   AS plus_3_months,   -- 2024-04-15
    '2024-01-15'::DATE + INTERVAL '10 days'    AS plus_10_days,    -- 2024-01-25
    '2024-01-15'::DATE - INTERVAL '1 year'     AS minus_1_year,    -- 2023-01-15
    '2024-01-15'::DATE + 10                    AS plus_10_int,     -- 2024-01-25 (integer = days)
    NOW()              + INTERVAL '2 hours'    AS two_hours_later,
    NOW()              - INTERVAL '30 minutes' AS half_hour_ago;


-- Filter: orders placed in the last 6 months from today
-- INTERVAL arithmetic on CURRENT_DATE gives a dynamic date boundary

SELECT order_id, order_date, status
FROM sales.orders
WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY order_date DESC;


-- =============================================================
-- SECTION 6 — Date Differences: AGE and subtraction
-- =============================================================

-- Subtracting two DATE values returns an INTEGER (number of days).
-- AGE() returns a human-readable INTERVAL (years, months, days).

-- Days since each customer signed up
SELECT
    name,
    signup_date,
    CURRENT_DATE - signup_date                         AS days_since_signup,
    AGE(CURRENT_DATE, signup_date)                     AS tenure_readable
FROM sales.customers
ORDER BY days_since_signup DESC;


-- Span of data in the orders table
SELECT
    MIN(order_date)                          AS first_order,
    MAX(order_date)                          AS last_order,
    MAX(order_date) - MIN(order_date)        AS span_days,
    AGE(MAX(order_date), MIN(order_date))    AS span_readable
FROM sales.orders;


-- How long between customer signup and their first order?
-- Customers who signed up early but ordered late — large gap

SELECT
    c.name,
    c.signup_date,
    MIN(o.order_date)                        AS first_order_date,
    MIN(o.order_date) - c.signup_date        AS gap_days,
    AGE(MIN(o.order_date), c.signup_date)    AS gap_readable
FROM sales.customers  c
JOIN sales.orders     o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.signup_date
ORDER BY gap_days DESC;


-- =============================================================
-- SECTION 7 — Casting and Parsing date strings
-- =============================================================

-- :: operator casts a string literal to a date type (PostgreSQL shorthand)
-- TO_DATE parses a string using a format pattern — useful for non-ISO formats
-- TO_TIMESTAMP parses a string into a full timestamp

SELECT
    '2024-08-15'::DATE                                         AS cast_iso,
    CAST('2024-08-15' AS DATE)                                 AS cast_standard,
    TO_DATE('15/08/2024',       'DD/MM/YYYY')                  AS parse_slash,
    TO_DATE('August 15, 2024',  'Month DD, YYYY')              AS parse_long,
    TO_TIMESTAMP('15-08-2024 14:30:00', 'DD-MM-YYYY HH24:MI:SS') AS parse_ts;


-- =============================================================
-- SECTION 8 — GROUP BY with Time: month, quarter, year, weekday
-- =============================================================

-- Grouping by year — compare 2023 vs 2024
SELECT
    EXTRACT(YEAR FROM order_date)  AS order_year,
    COUNT(*)                       AS order_count,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM sales.orders      o
JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY order_year;


-- Grouping by day of week — which day gets the most orders?
-- TO_CHAR gives the day name; EXTRACT(DOW) gives the number for sorting.

SELECT
    EXTRACT(DOW FROM order_date)   AS dow_num,
    TO_CHAR(order_date, 'Day')     AS day_name,
    COUNT(*)                       AS order_count
FROM sales.orders
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Day')
ORDER BY dow_num;


-- Grouping by quarter with readable label
SELECT
    TO_CHAR(order_date, 'YYYY-"Q"Q')  AS quarter_label,
    COUNT(*)                           AS order_count,
    SUM(oi.quantity * oi.unit_price)   AS revenue
FROM sales.orders      o
JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY TO_CHAR(order_date, 'YYYY-"Q"Q')
ORDER BY quarter_label;


-- Weekday vs Weekend breakdown using CASE + EXTRACT
SELECT
    order_id,
    order_date,
    TO_CHAR(order_date, 'Day')  AS day_name,
    CASE
        WHEN EXTRACT(DOW FROM order_date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type
FROM sales.orders
ORDER BY order_date;


-- =============================================================
-- SECTION 9 — generate_series: generating date sequences
-- =============================================================

-- generate_series(start, stop, step) produces a set of rows.
-- Step is an INTERVAL for date/timestamp series.
-- This is the foundation of "date spine" — a complete list of dates
-- so that months/days with no data still appear in reports.

-- Every day from 2024-01-01 to 2024-01-10
SELECT
    generate_series(
        '2024-01-01'::DATE,
        '2024-01-10'::DATE,
        '1 day'::INTERVAL
    )::DATE AS day;


-- Every month of 2024
SELECT
    generate_series(
        '2024-01-01'::DATE,
        '2024-12-01'::DATE,
        '1 month'::INTERVAL
    )::DATE AS month_start;


-- Every quarter from 2023 Q1 to 2024 Q4 with label
SELECT
    gs::DATE                             AS quarter_start,
    TO_CHAR(gs, 'YYYY-"Q"Q')            AS quarter_label
FROM generate_series(
    '2023-01-01'::DATE,
    '2024-10-01'::DATE,
    '3 months'::INTERVAL
) AS gs;


-- Every hour on 2024-01-15 (00:00 to 23:00)
SELECT
    generate_series(
        '2024-01-15 00:00:00'::TIMESTAMP,
        '2024-01-15 23:00:00'::TIMESTAMP,
        '1 hour'::INTERVAL
    ) AS hour_slot;


-- =============================================================
-- SECTION 10 — Date spine: gap-filling with generate_series + LEFT JOIN
-- =============================================================

-- Why this matters:
-- If no orders were placed in February 2024, a plain GROUP BY query
-- simply skips that month. In a report you want every month to show
-- even with 0 orders.
-- Solution: generate the complete list of months first, then LEFT JOIN
-- actual orders onto it. Months with no orders get NULLs → COALESCE to 0.

-- Monthly report for full year 2024 — every month appears including gaps
SELECT
    gs.month_start,
    TO_CHAR(gs.month_start, 'Mon-YYYY')              AS month_label,
    COUNT(o.order_id)                                AS order_count,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)    AS revenue
FROM generate_series(
    '2024-01-01'::DATE,
    '2024-12-01'::DATE,
    '1 month'::INTERVAL
) AS gs(month_start)
LEFT JOIN sales.orders o
    ON DATE_TRUNC('month', o.order_date)::DATE = gs.month_start
LEFT JOIN sales.order_items oi
    ON o.order_id = oi.order_id
GROUP BY gs.month_start
ORDER BY gs.month_start;

-- Notice: February 2024 and May 2024 appear with order_count = 0
-- because those months have no orders in the data — gap-fill working.


-- Weekly date spine for Q1 2024 — every week (Monday) appears
SELECT
    gs::DATE                                         AS week_start,
    (gs::DATE + 6)                                   AS week_end,
    COUNT(o.order_id)                                AS order_count,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)    AS revenue
FROM generate_series(
    '2024-01-01'::DATE,
    '2024-03-25'::DATE,
    '1 week'::INTERVAL
) AS gs
LEFT JOIN sales.orders o
    ON o.order_date >= gs::DATE
   AND o.order_date <  gs::DATE + 7
LEFT JOIN sales.order_items oi
    ON o.order_id = oi.order_id
GROUP BY gs
ORDER BY gs;


-- =============================================================
-- SECTION 11 — Epoch: Unix timestamps
-- =============================================================

-- Epoch = number of seconds since 1970-01-01 00:00:00 UTC.
-- Used heavily in logs, APIs, Kafka events, Spark pipelines.
-- PostgreSQL stores it as BIGINT or NUMERIC in source systems.

-- Get the current epoch
SELECT
    CURRENT_TIMESTAMP                            AS now_readable,
    EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)        AS now_epoch,
    EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT AS now_epoch_int;


-- Convert epoch back to timestamp using TO_TIMESTAMP
SELECT
    0          AS epoch_value, TO_TIMESTAMP(0)           AS ts  -- 1970-01-01
UNION ALL
SELECT
    86400,                     TO_TIMESTAMP(86400)             -- 1970-01-02
UNION ALL
SELECT
    1704067200,                TO_TIMESTAMP(1704067200);       -- 2024-01-01


-- Get epoch of specific dates
SELECT
    '2024-01-01'::TIMESTAMP                          AS dt,
    EXTRACT(EPOCH FROM '2024-01-01'::TIMESTAMP)      AS epoch;


-- Difference between two timestamps in seconds using epoch
SELECT
    EXTRACT(EPOCH FROM ('2024-08-15'::TIMESTAMP - '2024-01-01'::TIMESTAMP))        AS diff_seconds,
    EXTRACT(EPOCH FROM ('2024-08-15'::TIMESTAMP - '2024-01-01'::TIMESTAMP)) / 3600  AS diff_hours,
    EXTRACT(EPOCH FROM ('2024-08-15'::TIMESTAMP - '2024-01-01'::TIMESTAMP)) / 86400 AS diff_days;


-- =============================================================
-- SECTION 12 — events table: epoch-based queries
-- =============================================================

-- The events table stores occurred_at as BIGINT (epoch seconds).
-- Convert to timestamp at query time using TO_TIMESTAMP.
-- This is the standard pattern for clickstream / log data.

-- Basic view: convert epoch to readable timestamp
SELECT
    event_id,
    event_type,
    user_id,
    occurred_at                                          AS epoch_raw,
    TO_TIMESTAMP(occurred_at)                            AS event_timestamp,
    TO_TIMESTAMP(occurred_at)::DATE                      AS event_date,
    TO_CHAR(TO_TIMESTAMP(occurred_at), 'YYYY-MM-DD HH24:MI:SS') AS event_formatted
FROM sales.events
ORDER BY occurred_at;


-- Group events by date — how many events per day?
SELECT
    TO_TIMESTAMP(occurred_at)::DATE   AS event_date,
    COUNT(*)                          AS event_count,
    COUNT(DISTINCT user_id)           AS unique_users
FROM sales.events
GROUP BY TO_TIMESTAMP(occurred_at)::DATE
ORDER BY event_date;


-- Group events by hour of day — find peak activity hours
SELECT
    EXTRACT(HOUR FROM TO_TIMESTAMP(occurred_at))  AS hour_of_day,
    COUNT(*)                                       AS event_count,
    CASE
        WHEN COUNT(*) >= 3 THEN 'Peak'
        WHEN COUNT(*) >= 2 THEN 'Normal'
        ELSE 'Quiet'
    END AS activity_level
FROM sales.events
GROUP BY EXTRACT(HOUR FROM TO_TIMESTAMP(occurred_at))
ORDER BY hour_of_day;


-- Group events by event_type and date
SELECT
    TO_TIMESTAMP(occurred_at)::DATE   AS event_date,
    event_type,
    COUNT(*)                          AS event_count
FROM sales.events
GROUP BY TO_TIMESTAMP(occurred_at)::DATE, event_type
ORDER BY event_date, event_type;


-- Events within a specific epoch range (Jan 15 to Feb 20 2024)
-- Filter on raw epoch is faster than converting every row
SELECT
    event_id,
    event_type,
    TO_TIMESTAMP(occurred_at)  AS event_timestamp
FROM sales.events
WHERE occurred_at BETWEEN
    EXTRACT(EPOCH FROM '2024-01-15'::TIMESTAMP)::BIGINT
    AND
    EXTRACT(EPOCH FROM '2024-02-20 23:59:59'::TIMESTAMP)::BIGINT
ORDER BY occurred_at;


-- =============================================================
-- SECTION 13 — Common mistakes and NULL behavior
-- =============================================================

-- Mistake 1: GROUP BY EXTRACT(MONTH) loses year
-- January 2023 and January 2024 both appear as month = 1 → merged
-- WRONG:
SELECT
    EXTRACT(MONTH FROM order_date)  AS month_num,
    COUNT(*)                        AS order_count
FROM sales.orders
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month_num;

-- RIGHT: include YEAR, or use DATE_TRUNC (preferred)
SELECT
    DATE_TRUNC('month', order_date)::DATE  AS order_month,
    COUNT(*)                               AS order_count
FROM sales.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;


-- Mistake 2: subtracting date from string without explicit cast
-- The subtraction '2024-01-01' - order_date may fail or give wrong type
-- RIGHT: always cast explicitly
SELECT
    order_id,
    order_date,
    CURRENT_DATE - order_date   AS days_ago   -- DATE - DATE = integer (days)
FROM sales.orders
ORDER BY days_ago;


-- Mistake 3: NULL date in arithmetic — result is NULL
-- Any calculation involving NULL returns NULL
SELECT
    NULL::DATE + INTERVAL '1 day'          AS null_plus_interval,  -- NULL
    EXTRACT(YEAR FROM NULL::DATE)          AS extract_from_null;   -- NULL


-- Mistake 4: DATE_TRUNC returns TIMESTAMP, not DATE
-- Cast to DATE if you need a plain date (no time component)
SELECT
    DATE_TRUNC('month', CURRENT_DATE)         AS trunc_returns_ts,    -- timestamp
    DATE_TRUNC('month', CURRENT_DATE)::DATE   AS trunc_cast_to_date;  -- date


-- Mistake 5: generate_series gap-fill needs LEFT JOIN, not INNER JOIN
-- If you use JOIN instead of LEFT JOIN, months with 0 orders vanish
-- (Shown in Section 10 — the gap-fill query uses LEFT JOIN correctly)


-- =============================================================
-- SECTION 14 — Combined: generate_series + GROUP BY + CASE
-- =============================================================

-- Month-over-month report for 2024 with revenue and a tier label
-- Date spine ensures Feb 2024 and May 2024 appear with 0 revenue

SELECT
    gs.month_start,
    TO_CHAR(gs.month_start, 'Mon-YYYY')             AS month_label,
    COUNT(DISTINCT o.order_id)                      AS order_count,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)   AS revenue,
    CASE
        WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) > 100000 THEN 'High'
        WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) > 20000  THEN 'Medium'
        ELSE 'Low'
    END AS revenue_tier
FROM generate_series(
    '2024-01-01'::DATE,
    '2024-12-01'::DATE,
    '1 month'::INTERVAL
) AS gs(month_start)
LEFT JOIN sales.orders o
    ON DATE_TRUNC('month', o.order_date)::DATE = gs.month_start
   AND o.status = 'delivered'
LEFT JOIN sales.order_items oi
    ON o.order_id = oi.order_id
GROUP BY gs.month_start
ORDER BY gs.month_start;
