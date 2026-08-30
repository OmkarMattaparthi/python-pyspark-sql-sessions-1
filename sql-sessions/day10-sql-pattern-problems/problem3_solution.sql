-- =============================================================
-- Problem 3 Solution — Running Total
-- *** Instructor use only ***
-- =============================================================
-- Run problem3.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — SUM OVER (ORDER BY) window function (standard)
-- =============================================================
-- Adding ORDER BY inside SUM OVER makes it cumulative by default
-- (frame = UNBOUNDED PRECEDING to CURRENT ROW).

SELECT
    order_id,
    order_date,
    amount,
    SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders
ORDER BY order_date;


-- =============================================================
-- APPROACH 2 — Explicit frame clause (same result, more clear)
-- =============================================================
-- Writing the frame explicitly makes the intent obvious.

SELECT
    order_id,
    order_date,
    amount,
    SUM(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders
ORDER BY order_date;


-- =============================================================
-- APPROACH 3 — Correlated subquery (no window functions)
-- =============================================================
-- For each row, sum all rows with an earlier or equal order_date.
-- Works in older SQL dialects but O(n²) — slow on large tables.

SELECT
    o.order_id,
    o.order_date,
    o.amount,
    (
        SELECT SUM(o2.amount)
        FROM orders o2
        WHERE o2.order_date <= o.order_date
    ) AS running_total
FROM orders o
ORDER BY o.order_date;

-- Note:
--   Approach 1 is the standard — use this in interviews.
--   Approach 2 is identical but shows the frame explicitly — good for teaching.
--   Approach 3 is the pre-window-function workaround — avoid in production.
