-- =============================================================
-- Problem 3 Hard — Running Total
-- Pattern: Running total + % of customer total + flag when 50% crossed
-- =============================================================
-- Question:
--   For each customer, show each order with:
--     - running_total     : cumulative amount so far for that customer
--     - pct_of_total      : running_total as % of the customer's overall total (rounded to 2 dp)
--     - crossed_50pct     : 'Yes' for the FIRST order where running_total >= 50% of total, else 'No'
--   Order by customer_id, order_date.
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
--   customer_id | order_id | order_date | amount | running_total | pct_of_total | crossed_50pct
--   ------------+----------+------------+--------+---------------+--------------+--------------
--             1 |        1 | 2024-01-05 | 250.00 |        250.00 |        27.78 | No
--             1 |        2 | 2024-01-12 | 180.00 |        430.00 |        47.78 | No
--             1 |        3 | 2024-01-20 | 320.00 |        750.00 |        83.33 | Yes   ← first to cross 50%
--             1 |        4 | 2024-02-03 | 150.00 |        900.00 |       100.00 | No
--             2 |        5 | 2024-01-08 | 400.00 |        400.00 |        46.07 | No
--             2 |        6 | 2024-01-22 | 275.00 |        675.00 |        77.75 | Yes   ← first to cross 50%
--             2 |        7 | 2024-02-10 | 190.00 |        865.00 |       100.00 | No    (after 50% already flagged)
--             3 |        8 | 2024-01-15 | 500.00 |        500.00 |        68.97 | Yes   ← first to cross 50%
--             3 |        9 | 2024-01-30 | 225.00 |        725.00 |       100.00 | No

-- YOUR ANSWER:
