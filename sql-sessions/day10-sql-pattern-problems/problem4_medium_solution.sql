-- =============================================================
-- Problem 4 Medium Solution — Moving Average per Stock
-- *** Instructor use only ***
-- =============================================================
-- Run problem4_medium.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — AVG OVER (PARTITION BY ROWS BETWEEN) — standard
-- =============================================================
-- PARTITION BY stock resets the window per stock.
-- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = 3-row rolling window.
-- The window never crosses the stock boundary.

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
ORDER BY stock, price_date;


-- =============================================================
-- APPROACH 2 — CTE per stock then UNION ALL
-- =============================================================
-- Process each stock separately in its own CTE, then combine.
-- More verbose but very readable when stocks need different logic.

WITH aapl AS (
    SELECT stock, price_date, close_price,
           ROUND(AVG(close_price) OVER (ORDER BY price_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3
    FROM stock_prices WHERE stock = 'AAPL'
),
msft AS (
    SELECT stock, price_date, close_price,
           ROUND(AVG(close_price) OVER (ORDER BY price_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3
    FROM stock_prices WHERE stock = 'MSFT'
)
SELECT * FROM aapl
UNION ALL
SELECT * FROM msft
ORDER BY stock, price_date;

-- Note:
--   Approach 1 is the preferred solution — PARTITION BY handles all stocks in one pass.
--   Approach 2 shows the UNION ALL pattern — useful if each stock needs different logic.
--   Key difference from easy: adding PARTITION BY stock keeps windows independent.
--   Without PARTITION BY, the window would bleed across stock boundaries.
