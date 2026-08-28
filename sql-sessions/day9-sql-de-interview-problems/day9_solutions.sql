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
-- Key idea:
--   LAG pulls the previous row's values into the current row.
--   We compare BOTH temperature AND date — a date gap means
--   the rows are not consecutive days even if they are adjacent rows.
--
-- Step 1: CTE uses LAG to get previous day's temperature and date.
-- Step 2: Filter WHERE:
--           temperature > prev_temp   (strictly hotter)
--       AND record_date = prev_date + 1  (exactly one calendar day apart)

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
-- Why id=5 is excluded:
--   id=5 is 2015-01-06; the previous row (id=4) is 2015-01-04.
--   2015-01-05 is missing → record_date (1/6) ≠ prev_date (1/4) + 1 → filtered out.
--
-- Why id=7 is excluded:
--   Both id=6 and id=7 have temperature=40 → NOT strictly greater.


-- =============================================================
-- SOLUTION 2 — Restaurant Growth  (Day 32 | LeetCode #1321)
-- Pattern: 7-day rolling window (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
-- =============================================================
--
-- Key idea:
--   Multiple customers can visit on the same day — first aggregate to
--   daily totals. Then apply a rolling 7-day SUM and AVG over those
--   daily totals. Only return dates that have at least 7 days of history.
--
-- Step 1 (daily_totals CTE): SUM(amount) per visited_on date.
-- Step 2 (rolling CTE): apply window functions with frame 6 PRECEDING to CURRENT ROW.
--   - SUM  → rolling 7-day revenue
--   - AVG  → rolling 7-day average
--   - ROW_NUMBER → to filter out the first 6 dates
-- Step 3: outer query filters WHERE rn >= 7.

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
--   2019-01-07 | 860  | 122.86
--   2019-01-08 | 840  | 120.00
--   2019-01-09 | 840  | 120.00
--   2019-01-10 | 1000 | 142.86
--
-- Note on 2019-01-10:
--   Two customers visited (Jhon 130 + Jade 150 = 280 on that day).
--   The 7-day window 1/4 through 1/10 = 130+110+140+150+80+110+280 = 1000.
--
-- Why ROW_NUMBER instead of a date comparison:
--   We could write WHERE visited_on >= MIN(visited_on) + 6, but
--   ROW_NUMBER is simpler and works even if dates have gaps.


-- =============================================================
-- SOLUTION 3 — Biggest Window Between Visits  (Day 34 | LeetCode #1701)
-- Pattern: LAG gap detection — max gap per user
-- =============================================================
--
-- Key idea:
--   For each visit, compute the gap from the PREVIOUS visit using LAG.
--   For the LAST visit of each user, compute the gap to the reference date
--   '2021-01-01' (the day after the observation window closes).
--   Use LEAD to detect whether there's a next visit — if NULL → last visit.
--   Then MAX(gap) per user.
--
-- Step 1 (gaps CTE):
--   - LAG gives the previous visit date within each user's partition.
--   - LEAD gives the next visit date (NULL if this is the last visit).
--   - gap_days =
--       if this is NOT the last visit: current_date - prev_date
--       if this IS the last visit:    '2021-01-01' - current_date
--       (first visit has no prev_date → gap_days = NULL → ignored by MAX)
-- Step 2: GROUP BY user_id, MAX(gap_days).

WITH gaps AS (
    SELECT
        user_id,
        visit_date,
        LAG(visit_date)  OVER (PARTITION BY user_id ORDER BY visit_date) AS prev_date,
        LEAD(visit_date) OVER (PARTITION BY user_id ORDER BY visit_date) AS next_date,
        CASE
            -- Last visit for this user: measure gap to reference date
            WHEN LEAD(visit_date) OVER (PARTITION BY user_id ORDER BY visit_date) IS NULL
                THEN DATE '2021-01-01' - visit_date
            -- Not the first visit: measure gap from previous visit
            WHEN LAG(visit_date) OVER (PARTITION BY user_id ORDER BY visit_date) IS NOT NULL
                THEN visit_date - LAG(visit_date) OVER (PARTITION BY user_id ORDER BY visit_date)
            -- First visit with a next visit → gap to reference not counted here; handled above
            ELSE NULL
        END AS gap_days
    FROM lc.user_visits
)
SELECT
    user_id,
    MAX(gap_days) AS biggest_window
FROM gaps
GROUP BY user_id
ORDER BY user_id;

-- Expected:
--   1 | 39    (Oct 20 → Nov 28 = 39 days; Nov 28 → Dec 3 = 5; Dec 3 → Jan 1 = 29)
--   2 | 65    (Oct 5 → Dec 9 = 65 days; Dec 9 → Jan 1 = 23)
--   3 | 51    (only one visit Nov 11 → Jan 1 = 51 days)
--
-- Tricky part — user 3 has only one visit:
--   LAG = NULL (no prev) → gap_days stays NULL for the from-prev calculation.
--   LEAD = NULL (no next) → it IS the last visit → gap = 2021-01-01 - 2020-11-11 = 51.
--   MAX(51) = 51. Correct.


-- =============================================================
-- SOLUTION 4 — Continuous Ranges (Gaps & Islands)  (Day 47 | LeetCode #1285)
-- Pattern: ROW_NUMBER subtraction trick — the classic gaps & islands
-- =============================================================
--
-- Key idea (the trick):
--   For a perfectly consecutive sequence 1,2,3,4...:
--     row_number also goes 1,2,3,4...
--     so (log_id - row_number) = 0,0,0,0... — constant per island.
--   When there's a gap (e.g. after 3 the next is 7):
--     row_number goes to 4, so (7 - 4) = 3 — a new constant, starting a new island.
--   Any two IDs in the same consecutive run will have the SAME (log_id - row_number).
--   GROUP BY that difference, then MIN = start_id, MAX = end_id.

WITH numbered AS (
    SELECT
        log_id,
        log_id - ROW_NUMBER() OVER (ORDER BY log_id) AS island_key
    FROM lc.logs
)
SELECT
    MIN(log_id) AS start_id,
    MAX(log_id) AS end_id
FROM numbered
GROUP BY island_key
ORDER BY start_id;

-- Expected:
--    1 |  3
--    7 | 10
--   14 | 15
--   20 | 20
--
-- Walk-through of island_key values:
--   log_id | row_num | island_key
--        1 |       1 |  0
--        2 |       2 |  0   ← same island (key=0)
--        3 |       3 |  0
--        7 |       4 |  3   ← gap → new island (key=3)
--        8 |       5 |  3
--        9 |       6 |  3
--       10 |       7 |  3
--       14 |       8 |  6   ← gap → new island (key=6)
--       15 |       9 |  6
--       20 |      10 | 10   ← gap → new island (key=10)


-- =============================================================
-- SOLUTION 5 — Most Recent Three Orders  (Day 27 | LeetCode #1341)
-- Pattern: ROW_NUMBER per partition → Top-N per group filter
-- =============================================================
--
-- Key idea:
--   Use ROW_NUMBER partitioned by customer_id, ordered by order_date DESC
--   (most recent = rank 1). Filter WHERE rn <= 3 to keep at most 3 per customer.
--   If a customer has fewer than 3 orders, all rows have rn <= 3 → all returned.
--   JOIN to customers table to get name and email.
--
-- Step 1 (ranked CTE): assign rank per customer (most recent order = 1).
-- Step 2: filter rn <= 3 and join to customers_p5 for name/email.

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

-- Expected (12 rows — Khaled has only 2 orders):
--   Annabelle | annabelle@example.com | 9  | 2020-08-02 | 80
--   Annabelle | annabelle@example.com | 8  | 2020-08-01 | 20
--   Annabelle | annabelle@example.com | 5  | 2020-07-31 | 20
--   Jonathan  | jonathan@example.com  | 10 | 2020-08-02 | 10
--   Jonathan  | jonathan@example.com  | 7  | 2020-08-01 | 30
--   Jonathan  | jonathan@example.com  | 1  | 2020-07-31 | 30
--   Khaled    | khaled@example.com    | 14 | 2020-08-03 | 50
--   Khaled    | khaled@example.com    | 3  | 2020-07-31 | 50
--   Marwan    | marwan@example.com    | 12 | 2020-08-03 | 40
--   Marwan    | marwan@example.com    | 6  | 2020-08-01 | 20
--   Marwan    | marwan@example.com    | 2  | 2020-07-30 | 40
--   Winston   | winston@example.com   | 13 | 2020-08-03 | 20
--   Winston   | winston@example.com   | 11 | 2020-08-01 | 20
--   Winston   | winston@example.com   | 4  | 2020-07-29 | 100
--
-- Why ROW_NUMBER not RANK:
--   RANK would give ties the same number → two orders on the same date could
--   both get rn=1 and rn=3 would be skipped. ROW_NUMBER always produces a
--   unique rank → exactly N rows per partition (deterministic by order_id tiebreak).
