-- =============================================================
-- Problem 6 Solution — Previous and Next Record Comparison
-- *** Instructor use only ***
-- =============================================================
-- Run problem6.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — LAG window function (standard, most readable)
-- =============================================================
-- LAG(revenue) OVER (PARTITION BY dept ORDER BY month) looks at
-- the previous row within each dept partition.
-- First row per dept has no previous → returns NULL by default.

SELECT
    dept,
    month,
    revenue,
    LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS prev_revenue
FROM monthly_revenue
ORDER BY dept, month;


-- =============================================================
-- APPROACH 2 — Self JOIN on previous month
-- =============================================================
-- Join the table to itself: current month joins to month - 1 interval.
-- LEFT JOIN ensures the first month row still appears (no previous row).

SELECT
    curr.dept,
    curr.month,
    curr.revenue,
    prev.revenue AS prev_revenue
FROM monthly_revenue curr
LEFT JOIN monthly_revenue prev
       ON curr.dept = prev.dept
      AND prev.month = curr.month - INTERVAL '1 month'
ORDER BY curr.dept, curr.month;


-- =============================================================
-- APPROACH 3 — LAG with explicit default (NULL replaced by 0)
-- =============================================================
-- Same as Approach 1 but replaces NULL with 0 for the first month.
-- Useful when downstream math would break on NULL.

SELECT
    dept,
    month,
    revenue,
    LAG(revenue, 1, 0) OVER (PARTITION BY dept ORDER BY month) AS prev_revenue
FROM monthly_revenue
ORDER BY dept, month;

-- Note:
--   Approach 1 is the standard — LAG is the go-to for previous-row access.
--   Approach 2 (self JOIN) works in all dialects but only works if data
--   has no gaps in months (the JOIN condition breaks on missing months).
--   Approach 3 replaces NULL with 0 — use when 0 makes more sense than NULL.
