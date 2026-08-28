-- =============================================================
-- Day 9 — SOLUTION SHEET
-- *** For instructor use only — do not share with students ***
-- Source: 210 Days SQL Interview Questions (LeetCode-based)
-- =============================================================
-- Run day9_problems.sql first to create all tables and data.
-- =============================================================


-- =============================================================
-- SOLUTION 1 — Rising Temperature  (Day 21 | LeetCode #197)
-- Pattern: LAG — consecutive row comparison
-- =============================================================
--
-- LAG pulls the previous row's temperature and date into the current row.
-- Filter on BOTH: temperature strictly higher AND exactly one calendar day apart.

WITH lagged AS (
    SELECT
        id,
        record_date,
        temperature,
        LAG(temperature) OVER (ORDER BY record_date) AS prev_temp,
        LAG(record_date)  OVER (ORDER BY record_date) AS prev_date
    FROM lc.weather
)
SELECT id
FROM lagged
WHERE temperature > prev_temp
  AND record_date = prev_date + INTERVAL '1 day'
ORDER BY id;

-- Expected: 2, 4, 6
--
-- id=5 excluded: 2015-01-06 prev row is 2015-01-04 → not consecutive.
-- id=7 excluded: temp 40 = prev temp 40 → not strictly greater.


-- =============================================================
-- SOLUTION 2 — Game Play Analysis III  (Day 22 | LeetCode #534)
-- Pattern: Running total — SUM OVER (PARTITION BY ORDER BY)
-- =============================================================
--
-- SUM with PARTITION BY player_id and ORDER BY event_date gives a
-- cumulative sum that resets per player and grows with each session.

SELECT
    player_id,
    event_date,
    SUM(games_played) OVER (
        PARTITION BY player_id
        ORDER BY event_date
    ) AS games_played_so_far
FROM lc.activity
ORDER BY player_id, event_date;

-- Expected:
--   1 | 2016-03-01 |  5
--   1 | 2016-05-02 | 11
--   1 | 2017-06-25 | 12
--   3 | 2016-03-02 |  0
--   3 | 2018-07-03 |  5
--
-- No CTE needed — one window function does it all.
-- The key: ORDER BY inside OVER() makes SUM cumulative (running), not total.


-- =============================================================
-- SOLUTION 3 — Running Total for Different Genders  (Day 25 | LeetCode #1308)
-- Pattern: SUM per partition — running total resets per gender
-- =============================================================
--
-- PARTITION BY gender means the running total resets for each gender group.
-- ORDER BY day inside the window makes it cumulative within each gender.

SELECT
    gender,
    day,
    SUM(score_points) OVER (
        PARTITION BY gender
        ORDER BY day
    ) AS total
FROM lc.scores
ORDER BY gender, day;

-- Expected:
--   F | 2020-01-01 | 17
--   F | 2020-01-05 | 30
--   F | 2020-01-06 | 47
--   F | 2020-01-07 | 70
--   M | 2020-01-01 | 13
--   M | 2020-01-02 | 25
--   M | 2020-01-06 | 36
--   M | 2020-01-07 | 43
--
-- Same pattern as Solution 2 — PARTITION BY changes what "resets."
-- Without PARTITION BY it would be one running total across all genders.


-- =============================================================
-- SOLUTION 4 — Restaurant Growth  (Day 32 | LeetCode #1321)
-- Pattern: 7-day rolling window (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
-- =============================================================
--
-- Two steps:
--   1. Aggregate multiple same-day visits into one daily total.
--   2. Apply rolling 7-day SUM and AVG using ROWS BETWEEN 6 PRECEDING AND CURRENT ROW.
-- ROW_NUMBER >= 7 filters out the first 6 dates that lack a full 7-day history.

WITH daily_totals AS (
    SELECT
        visited_on,
        SUM(amount) AS daily_amount
    FROM lc.customer
    GROUP BY visited_on
),
rolling AS (
    SELECT
        visited_on,
        SUM(daily_amount) OVER (
            ORDER BY visited_on
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )                          AS amount,
        ROUND(
            AVG(daily_amount) OVER (
                ORDER BY visited_on
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 2
        )                          AS average_amount,
        ROW_NUMBER() OVER (ORDER BY visited_on) AS rn
    FROM daily_totals
)
SELECT
    visited_on,
    amount,
    average_amount
FROM rolling
WHERE rn >= 7
ORDER BY visited_on;

-- Expected:
--   2019-01-07 |  860 | 122.86
--   2019-01-08 |  840 | 120.00
--   2019-01-09 |  840 | 120.00
--   2019-01-10 | 1000 | 142.86
--
-- 2019-01-10: two customers visited (130 + 150 = 280 that day).
-- 7-day window 1/4 → 1/10: 130+110+140+150+80+110+280 = 1000.


-- =============================================================
-- SOLUTION 5 — Most Recent Three Orders  (Day 27 | LeetCode #1341)
-- Pattern: ROW_NUMBER per partition → Top-N per group filter
-- =============================================================
--
-- ROW_NUMBER partitioned by customer_id, ordered by order_date DESC
-- gives rank 1 = most recent order. Filter rn <= 3 keeps at most 3 per customer.
-- Customers with fewer than 3 orders all have rn <= 3 — all rows returned.

WITH ranked AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.cost,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date DESC, o.order_id ASC
        ) AS rn
    FROM lc.orders_p5 o
)
SELECT
    c.name          AS customer_name,
    c.email         AS customer_email,
    r.order_id,
    r.order_date,
    r.cost
FROM ranked r
JOIN lc.customers_p5 c ON c.customer_id = r.customer_id
WHERE r.rn <= 3
ORDER BY c.name ASC, r.order_date DESC, r.order_id ASC;

-- Expected (12 rows):
--   Annabelle | annabelle@example.com |  9 | 2020-08-02 |  80
--   Annabelle | annabelle@example.com |  8 | 2020-08-01 |  20
--   Annabelle | annabelle@example.com |  5 | 2020-07-31 |  20
--   Jonathan  | jonathan@example.com  | 10 | 2020-08-02 |  10
--   Jonathan  | jonathan@example.com  |  7 | 2020-08-01 |  30
--   Jonathan  | jonathan@example.com  |  1 | 2020-07-31 |  30
--   Khaled    | khaled@example.com    | 14 | 2020-08-03 |  50
--   Khaled    | khaled@example.com    |  3 | 2020-07-31 |  50
--   Marwan    | marwan@example.com    | 12 | 2020-08-03 |  40
--   Marwan    | marwan@example.com    |  6 | 2020-08-01 |  20
--   Marwan    | marwan@example.com    |  2 | 2020-07-30 |  40
--   Winston   | winston@example.com   | 13 | 2020-08-03 |  20
--   Winston   | winston@example.com   | 11 | 2020-08-01 |  20
--   Winston   | winston@example.com   |  4 | 2020-07-29 | 100
--
-- Use ROW_NUMBER not RANK: RANK gives tied rows the same number,
-- meaning rn <= 3 could return more than 3 rows per customer.
