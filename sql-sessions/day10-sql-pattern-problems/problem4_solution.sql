-- =============================================================
-- Problem 4 Solution — Moving Average
-- *** Instructor use only ***
-- =============================================================
-- Run problem4.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — AVG OVER with ROWS BETWEEN (standard)
-- =============================================================
-- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = last 3 rows including current.
-- Filter WHERE stock = 'AAPL' to scope to one stock.

SELECT
    price_date,
    close_price,
    ROUND(
        AVG(close_price) OVER (
            ORDER BY price_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_3
FROM stock_prices
WHERE stock = 'AAPL'
ORDER BY price_date;


-- =============================================================
-- APPROACH 2 — CTE to isolate the stock first, then compute
-- =============================================================
-- Extract AAPL rows into a CTE, then apply the window.
-- Useful when you need to reuse the filtered set multiple times.

WITH aapl AS (
    SELECT price_date, close_price
    FROM stock_prices
    WHERE stock = 'AAPL'
)
SELECT
    price_date,
    close_price,
    ROUND(
        AVG(close_price) OVER (
            ORDER BY price_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_3
FROM aapl
ORDER BY price_date;


-- =============================================================
-- APPROACH 3 — Correlated subquery (no window functions)
-- =============================================================
-- For each row, average the current and up to 2 previous rows by date.
-- Works without window functions but is slower on large datasets.

SELECT
    s.price_date,
    s.close_price,
    ROUND(
        (SELECT AVG(s2.close_price)
         FROM stock_prices s2
         WHERE s2.stock = 'AAPL'
           AND s2.price_date <= s.price_date
           AND s2.price_date >= s.price_date - INTERVAL '2 days'
        ), 2
    ) AS moving_avg_3
FROM stock_prices s
WHERE s.stock = 'AAPL'
ORDER BY s.price_date;

-- Note:
--   Approach 1 is the cleanest — ROWS BETWEEN is the key to learn here.
--   Approach 2 (CTE) is the same logic, more organized for larger queries.
--   Approach 3 (correlated subquery) avoids window functions but is slow.
--   The frame keyword: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = 3-row window.
