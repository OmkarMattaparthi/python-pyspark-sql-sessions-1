-- =============================================================
-- Problem 3 Medium Solution — Running Total per Customer
-- *** Instructor use only ***
-- =============================================================
-- Run problem3_medium.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — SUM OVER (PARTITION BY ORDER BY) — standard
-- =============================================================
-- PARTITION BY customer_id resets the running total per customer.
-- ORDER BY order_date makes it cumulative within each customer.

SELECT
    customer_id,
    order_id,
    order_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS running_total
FROM orders
ORDER BY customer_id, order_date;


-- =============================================================
-- APPROACH 2 — Explicit frame clause (same result, more visible)
-- =============================================================

SELECT
    customer_id,
    order_id,
    order_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders
ORDER BY customer_id, order_date;


-- =============================================================
-- APPROACH 3 — Correlated subquery (no window functions)
-- =============================================================
-- For each order, sum all orders of the same customer up to and
-- including that date. Works in any SQL dialect but is O(n²).

SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    o.amount,
    (
        SELECT SUM(o2.amount)
        FROM orders o2
        WHERE o2.customer_id = o.customer_id
          AND o2.order_date <= o.order_date
    ) AS running_total
FROM orders o
ORDER BY o.customer_id, o.order_date;

-- Note:
--   Approach 1 is standard — PARTITION BY is the key difference from the easy problem.
--   Without PARTITION BY: one global running total.
--   With PARTITION BY customer_id: running total resets per customer.
--   Approach 3 works in all dialects but is much slower on large tables.
