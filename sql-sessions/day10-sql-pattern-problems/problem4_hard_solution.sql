-- =============================================================
-- Problem 4 Hard Solution — Moving Average + Deviation + Outlier Flag
-- *** Instructor use only ***
-- =============================================================


-- =============================================================
-- APPROACH 1 — Window SUM/COUNT for avg, derive deviation + flag
-- =============================================================
-- Use AVG() OVER with ROWS BETWEEN 2 PRECEDING AND CURRENT ROW for a
-- true 3-row moving window per stock.  Deviation = close_price - avg.
-- |deviation| > 5 → 'Yes'.

SELECT
    stock,
    price_date,
    close_price,
    ROUND(
        AVG(close_price) OVER (
            PARTITION BY stock
            ORDER BY price_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    )                                                      AS moving_avg_3,
    ROUND(
        close_price - AVG(close_price) OVER (
            PARTITION BY stock
            ORDER BY price_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    )                                                      AS deviation,
    CASE
        WHEN ABS(
            close_price - AVG(close_price) OVER (
                PARTITION BY stock
                ORDER BY price_date
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            )
        ) > 5 THEN 'Yes'
        ELSE 'No'
    END                                                    AS is_outlier
FROM stock_prices
ORDER BY stock, price_date;


-- =============================================================
-- APPROACH 2 — CTE to compute avg once, reuse for deviation + flag
-- =============================================================
-- Avoid repeating the window expression three times by computing
-- moving_avg_3 in a CTE, then deriving deviation and is_outlier in outer query.

WITH with_avg AS (
    SELECT
        stock,
        price_date,
        close_price,
        ROUND(
            AVG(close_price) OVER (
                PARTITION BY stock
                ORDER BY price_date
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 2
        ) AS moving_avg_3
    FROM stock_prices
)
SELECT
    stock,
    price_date,
    close_price,
    moving_avg_3,
    ROUND(close_price - moving_avg_3, 2)                   AS deviation,
    CASE WHEN ABS(close_price - moving_avg_3) > 5
         THEN 'Yes' ELSE 'No' END                          AS is_outlier
FROM with_avg
ORDER BY stock, price_date;


-- =============================================================
-- APPROACH 3 — Subquery style (no CTE) for environments that avoid CTEs
-- =============================================================

SELECT
    stock,
    price_date,
    close_price,
    moving_avg_3,
    ROUND(close_price - moving_avg_3, 2)                   AS deviation,
    CASE WHEN ABS(close_price - moving_avg_3) > 5
         THEN 'Yes' ELSE 'No' END                          AS is_outlier
FROM (
    SELECT
        stock,
        price_date,
        close_price,
        ROUND(
            AVG(close_price) OVER (
                PARTITION BY stock
                ORDER BY price_date
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 2
        ) AS moving_avg_3
    FROM stock_prices
) sub
ORDER BY stock, price_date;

-- Note:
--   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW gives a window of at most 3 rows.
--   For the first row the avg is over 1 row, for the second row over 2 rows —
--   this is the standard "expanding then fixed" behaviour, matching the easy/medium
--   versions of this problem.
--   The threshold |deviation| > 5 is intentionally set so no row in this dataset
--   triggers it — students must still write the logic correctly for the flag to work.
