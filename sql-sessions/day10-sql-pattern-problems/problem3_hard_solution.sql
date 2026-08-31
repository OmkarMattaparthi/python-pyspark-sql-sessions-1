-- =============================================================
-- Problem 3 Hard Solution — Running Total + % of Total + 50% Crossover
-- *** Instructor use only ***
-- =============================================================


-- =============================================================
-- APPROACH 1 — CTE chain: total per customer, then windows
-- =============================================================
-- Step 1: compute the total order value per customer using a window SUM with
--         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING (same partition).
-- Step 2: compute running total with ORDER BY.
-- Step 3: derive pct_of_total and flag the first order that crosses 50%.

WITH with_totals AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        amount,
        SUM(amount) OVER (PARTITION BY customer_id) AS customer_total,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                            AS running_total
    FROM orders
),
with_pct AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        amount,
        running_total,
        ROUND(running_total * 100.0 / customer_total, 1) AS pct_of_total,
        LAG(running_total) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        )                                                  AS prev_running
    FROM with_totals
)
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    running_total,
    pct_of_total,
    CASE
        WHEN pct_of_total >= 50
         AND (prev_running IS NULL OR prev_running * 100.0 / (running_total - amount + running_total - running_total + running_total) < 50)
        THEN 'Yes' ELSE 'No'
    END AS crossed_50pct
FROM with_pct
ORDER BY customer_id, order_date, order_id;


-- =============================================================
-- APPROACH 2 — Cleaner: use RANK to flag first row where pct >= 50
-- =============================================================
-- Compute running total and pct in one CTE, then use ROW_NUMBER to
-- identify the first row per customer where pct_of_total >= 50.

WITH base AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        amount,
        SUM(amount) OVER (PARTITION BY customer_id)                              AS customer_total,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                                         AS running_total
    FROM orders
),
with_pct AS (
    SELECT *,
        ROUND(running_total * 100.0 / customer_total, 1) AS pct_of_total
    FROM base
),
crossover AS (
    SELECT
        customer_id,
        MIN(order_id) AS crossover_order_id
    FROM with_pct
    WHERE pct_of_total >= 50
    GROUP BY customer_id
)
SELECT
    p.order_id,
    p.customer_id,
    p.order_date,
    p.amount,
    p.running_total,
    p.pct_of_total,
    CASE WHEN p.order_id = c.crossover_order_id THEN 'Yes' ELSE 'No' END AS crossed_50pct
FROM with_pct p
LEFT JOIN crossover c ON p.customer_id = c.customer_id
ORDER BY p.customer_id, p.order_date, p.order_id;


-- =============================================================
-- APPROACH 3 — Using ROW_NUMBER to find first-crossover row
-- =============================================================
-- Among rows where pct >= 50, ROW_NUMBER() per customer ordered by date/id
-- gives rn=1 for the earliest crossover row.

WITH base AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        amount,
        SUM(amount) OVER (PARTITION BY customer_id)                              AS customer_total,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                                         AS running_total
    FROM orders
),
with_pct AS (
    SELECT *,
        ROUND(running_total * 100.0 / customer_total, 1) AS pct_of_total,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS rn_all,
        CASE WHEN ROUND(running_total * 100.0 / customer_total, 1) >= 50
             THEN ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY order_date, order_id
             ) END AS rn_over50
    FROM base
)
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    running_total,
    pct_of_total,
    CASE WHEN rn_all = MIN(rn_over50) OVER (PARTITION BY customer_id)
         THEN 'Yes' ELSE 'No' END AS crossed_50pct
FROM with_pct
ORDER BY customer_id, order_date, order_id;

-- Note:
--   order_id is used as a tiebreaker alongside order_date to make window ORDER BY
--   deterministic when two orders fall on the same date.
--   pct_of_total is rounded to 1 dp; >= 50 check happens on the rounded value.
