-- =============================================================
-- Problem 4 — Moving Average
-- Pattern: AVG OVER (ROWS BETWEEN n PRECEDING AND CURRENT ROW)
-- =============================================================
-- Question:
--   Calculate the 3-day moving average of close_price for AAPL
--   ordered by price_date.
--   Round to 2 decimal places.
--   Return: price_date, close_price, moving_avg_3.
-- =============================================================

DROP TABLE IF EXISTS stock_prices;

CREATE TABLE stock_prices (
    price_id    SERIAL PRIMARY KEY,
    stock       VARCHAR(10),
    price_date  DATE,
    close_price NUMERIC(10,2)
);

INSERT INTO stock_prices (stock, price_date, close_price) VALUES
    ('AAPL', '2024-01-01', 185.20),
    ('AAPL', '2024-01-02', 187.50),
    ('AAPL', '2024-01-03', 183.80),
    ('AAPL', '2024-01-04', 189.00),
    ('AAPL', '2024-01-05', 192.30),
    ('AAPL', '2024-01-08', 190.10),
    ('AAPL', '2024-01-09', 194.50),
    ('MSFT', '2024-01-01', 375.00),
    ('MSFT', '2024-01-02', 378.20),
    ('MSFT', '2024-01-03', 372.50),
    ('MSFT', '2024-01-04', 380.00),
    ('MSFT', '2024-01-05', 383.70);

-- Expected output (AAPL only):
--
--   price_date | close_price | moving_avg_3
--   -----------+-------------+-------------
--   2024-01-01 |      185.20 |       185.20
--   2024-01-02 |      187.50 |       186.35
--   2024-01-03 |      183.80 |       185.50
--   2024-01-04 |      189.00 |       186.77
--   2024-01-05 |      192.30 |       188.37
--   2024-01-08 |      190.10 |       190.47
--   2024-01-09 |      194.50 |       192.30

-- YOUR ANSWER:
