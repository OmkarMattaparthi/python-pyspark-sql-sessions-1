-- =============================================================
-- Day 9 — Data Engineering SQL Interview Problems
-- Source: 210 Days SQL Interview Questions (LeetCode-based)
-- Window Function patterns: Medium level
-- =============================================================
-- Standalone: run this file top-to-bottom on any PostgreSQL DB.
-- All tables and data are created below.
-- Solutions are in day9_solutions.sql — do NOT open until done.
--
-- Problems selected:
--   P1 (Day 21) — Rising Temperature              LAG — consecutive row comparison
--   P2 (Day 22) — Game Play Analysis III          Running total SUM OVER ORDER BY
--   P3 (Day 25) — Running Total for Genders       SUM per partition (PARTITION BY)
--   P4 (Day 32) — Restaurant Growth               7-day rolling average (ROWS BETWEEN)
--   P5 (Day 27) — Most Recent Three Orders        Top-N per group (ROW_NUMBER + filter)
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
    (2, '2015-01-02', 25),
    (3, '2015-01-03', 20),
    (4, '2015-01-04', 30),
    (5, '2015-01-06', 15),
    (6, '2015-01-07', 40),
    (7, '2015-01-08', 40),
    (8, '2015-01-09', 35);


-- -------------------------------------------------------
-- Table for P2: Activity (Game Play Analysis III)
-- LeetCode #534 — Game Play Analysis III
-- Each row is one session played by a player on a given date.
-- games_played is how many games they played that session.
-- -------------------------------------------------------
CREATE TABLE lc.activity (
    player_id    INT,
    device_id    INT,
    event_date   DATE,
    games_played INT
);

INSERT INTO lc.activity (player_id, device_id, event_date, games_played) VALUES
    (1, 2, '2016-03-01', 5),
    (1, 2, '2016-05-02', 6),
    (1, 3, '2017-06-25', 1),
    (3, 1, '2016-03-02', 0),
    (3, 4, '2018-07-03', 5);


-- -------------------------------------------------------
-- Table for P3: Scores (Running Total for Different Genders)
-- LeetCode #1308 — Running Total for Different Genders
-- Each row is one contest result: player, gender, day, score.
-- -------------------------------------------------------
CREATE TABLE lc.scores (
    player_name  VARCHAR(50),
    gender       CHAR(1),
    day          DATE,
    score_points INT
);

INSERT INTO lc.scores (player_name, gender, day, score_points) VALUES
    ('Aron',  'F', '2020-01-01', 17),
    ('Alice', 'F', '2020-01-07', 23),
    ('Bajrang','M', '2020-01-07', 7),
    ('Khali', 'M', '2020-01-06', 11),
    ('Slaman','M', '2020-01-01', 13),
    ('Joe',   'M', '2020-01-02', 12),
    ('Meredith','F','2020-01-06', 17),
    ('Irina', 'F', '2020-01-05', 13);


-- -------------------------------------------------------
-- Table for P4: Customer (Restaurant Growth)
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
    (1, 'Winston',  'winston@example.com'),
    (2, 'Jonathan', 'jonathan@example.com'),
    (3, 'Annabelle','annabelle@example.com'),
    (4, 'Marwan',   'marwan@example.com'),
    (5, 'Khaled',   'khaled@example.com');

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
UNION ALL SELECT 'activity',    COUNT(*) FROM lc.activity
UNION ALL SELECT 'scores',      COUNT(*) FROM lc.scores
UNION ALL SELECT 'customer',    COUNT(*) FROM lc.customer
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
-- PROBLEM 2 — Game Play Analysis III  (Day 22 | LeetCode #534)
-- Pattern: Running total — SUM OVER (PARTITION BY ORDER BY)
-- =============================================================
--
-- For each player, report the cumulative (running) total of
-- games played up to and including each session date.
--
-- Return: player_id, event_date, games_played_so_far
-- Sort by player_id, event_date.
--
-- Expected output:
--
--   player_id | event_date  | games_played_so_far
--   ----------+-------------+--------------------
--           1 | 2016-03-01  |   5
--           1 | 2016-05-02  |  11
--           1 | 2017-06-25  |  12
--           3 | 2016-03-02  |   0
--           3 | 2018-07-03  |   5
--

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 3 — Running Total for Different Genders  (Day 25 | LeetCode #1308)
-- Pattern: SUM per partition — running total resets per gender
-- =============================================================
--
-- For each gender, compute the running total of score_points
-- ordered by day. The running total resets for each gender group.
--
-- Return: gender, day, total (cumulative score up to that day for that gender).
-- Sort by gender, day.
--
-- Expected output:
--
--   gender | day        | total
--   -------+------------+-------
--   F      | 2020-01-01 |   17
--   F      | 2020-01-05 |   30
--   F      | 2020-01-06 |   47
--   F      | 2020-01-07 |   70
--   M      | 2020-01-01 |   13
--   M      | 2020-01-02 |   25
--   M      | 2020-01-06 |   36
--   M      | 2020-01-07 |   43
--

-- YOUR ANSWER:


-- =============================================================
-- PROBLEM 4 — Restaurant Growth  (Day 32 | LeetCode #1321)
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
-- Expected output (12 rows — Khaled has only 2 orders):
--
--   customer_name | customer_email           | order_id | order_date  | cost
--   --------------+--------------------------+----------+-------------+------
--   Annabelle     | annabelle@example.com    |       9  | 2020-08-02  |  80
--   Annabelle     | annabelle@example.com    |       8  | 2020-08-01  |  20
--   Annabelle     | annabelle@example.com    |       5  | 2020-07-31  |  20
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

-- YOUR ANSWER:
