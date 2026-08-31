-- =============================================================
-- Problem 4 Hard — Moving Average
-- Pattern: 3-day moving avg + deviation from avg + flag outliers
-- =============================================================
-- Question:
--   For each stock and date, calculate:
--     - moving_avg_3   : 3-day moving average of close_price (rounded to 2 dp)
--     - deviation      : close_price - moving_avg_3 (rounded to 2 dp)
--     - is_outlier     : 'Yes' if |deviation| > 5, else 'No'
--   Order by stock, price_date.
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

-- Expected output:
--
--   stock | price_date | close_price | moving_avg_3 | deviation | is_outlier
--   ------+------------+-------------+--------------+-----------+-----------
--   AAPL  | 2024-01-01 |      185.20 |       185.20 |      0.00 | No
--   AAPL  | 2024-01-02 |      187.50 |       186.35 |      1.15 | No
--   AAPL  | 2024-01-03 |      183.80 |       185.50 |     -1.70 | No
--   AAPL  | 2024-01-04 |      189.00 |       186.77 |      2.23 | No
--   AAPL  | 2024-01-05 |      192.30 |       188.37 |      3.93 | No
--   AAPL  | 2024-01-08 |      190.10 |       190.47 |     -0.37 | No
--   AAPL  | 2024-01-09 |      194.50 |       192.30 |      2.20 | No
--   MSFT  | 2024-01-01 |      375.00 |       375.00 |      0.00 | No
--   MSFT  | 2024-01-02 |      378.20 |       376.60 |      1.60 | No
--   MSFT  | 2024-01-03 |      372.50 |       375.23 |     -2.73 | No
--   MSFT  | 2024-01-04 |      380.00 |       376.90 |      3.10 | No
--   MSFT  | 2024-01-05 |      383.70 |       378.73 |      4.97 | No
--
-- Note: With this dataset no outliers exist (all deviations < 5).
--       The logic must still correctly flag any row where |deviation| > 5.

-- YOUR ANSWER:
