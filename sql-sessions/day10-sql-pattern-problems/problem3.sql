-- =============================================================
-- Problem 3 — Running Total
-- Pattern: SUM OVER (ORDER BY) — cumulative aggregate
-- =============================================================
-- Question:
--   Show each order with a running total of amount across ALL orders,
--   ordered by order_date.
--   Return: order_id, order_date, amount, running_total.
-- =============================================================

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT,
    order_date  DATE,
    amount      NUMERIC(10,2)
);

INSERT INTO orders (customer_id, order_date, amount) VALUES
    (1, '2024-01-05', 250.00),
    (1, '2024-01-12', 180.00),
    (1, '2024-01-20', 320.00),
    (1, '2024-02-03', 150.00),
    (2, '2024-01-08', 400.00),
    (2, '2024-01-22', 275.00),
    (2, '2024-02-10', 190.00),
    (3, '2024-01-15', 500.00),
    (3, '2024-01-30', 225.00);

-- Expected output:
--
--   order_id | order_date | amount | running_total
--   ---------+------------+--------+--------------
--          1 | 2024-01-05 | 250.00 |       250.00
--          5 | 2024-01-08 | 400.00 |       650.00
--          2 | 2024-01-12 | 180.00 |       830.00
--          8 | 2024-01-15 | 500.00 |      1330.00
--          3 | 2024-01-20 | 320.00 |      1650.00
--          6 | 2024-01-22 | 275.00 |      1925.00
--          9 | 2024-01-30 | 225.00 |      2150.00
--          4 | 2024-02-03 | 150.00 |      2300.00
--          7 | 2024-02-10 | 190.00 |      2490.00

-- YOUR ANSWER:
