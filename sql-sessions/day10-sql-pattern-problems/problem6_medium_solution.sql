-- =============================================================
-- Problem 6 Medium Solution — MoM Change and Trend
-- *** Instructor use only ***
-- =============================================================
-- Run problem6_medium.sql first to create and populate the table.
-- =============================================================


-- =============================================================
-- APPROACH 1 — LAG in CTE, then CASE for change and trend
-- =============================================================
-- Step 1: CTE computes prev_revenue using LAG.
-- Step 2: Outer query computes change and trend from those values.
-- Window functions cannot reference each other in the same SELECT —
-- that is why we need the CTE (or subquery) as an intermediate step.

WITH lagged AS (
    SELECT
        dept,
        month,
        revenue,
        LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS prev_revenue
    FROM monthly_revenue
)
SELECT
    dept,
    month,
    revenue,
    prev_revenue,
    revenue - prev_revenue AS change,
    CASE
        WHEN prev_revenue IS NULL        THEN NULL
        WHEN revenue > prev_revenue      THEN 'Increase'
        WHEN revenue < prev_revenue      THEN 'Decrease'
        ELSE                                  'No Change'
    END AS trend
FROM lagged
ORDER BY dept, month;


-- =============================================================
-- APPROACH 2 — Inline subquery instead of CTE (same logic)
-- =============================================================

SELECT
    dept,
    month,
    revenue,
    prev_revenue,
    revenue - prev_revenue AS change,
    CASE
        WHEN prev_revenue IS NULL   THEN NULL
        WHEN revenue > prev_revenue THEN 'Increase'
        WHEN revenue < prev_revenue THEN 'Decrease'
        ELSE                             'No Change'
    END AS trend
FROM (
    SELECT
        dept,
        month,
        revenue,
        LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS prev_revenue
    FROM monthly_revenue
) sub
ORDER BY dept, month;


-- =============================================================
-- APPROACH 3 — Self JOIN for previous month
-- =============================================================
-- Join each row to the row from the previous month (month - 1 month interval).
-- Compute change and trend directly on the joined columns.

SELECT
    curr.dept,
    curr.month,
    curr.revenue,
    prev.revenue                    AS prev_revenue,
    curr.revenue - prev.revenue     AS change,
    CASE
        WHEN prev.revenue IS NULL           THEN NULL
        WHEN curr.revenue > prev.revenue    THEN 'Increase'
        WHEN curr.revenue < prev.revenue    THEN 'Decrease'
        ELSE                                     'No Change'
    END                             AS trend
FROM monthly_revenue curr
LEFT JOIN monthly_revenue prev
       ON curr.dept = prev.dept
      AND prev.month = curr.month - INTERVAL '1 month'
ORDER BY curr.dept, curr.month;

-- Note:
--   Approach 1 (CTE + LAG) is the cleanest and most interview-standard.
--   Approach 2 is identical to Approach 1 but uses a subquery — same performance.
--   Approach 3 (self JOIN) works but breaks if there are missing months in the data.
--   Key rule: you CANNOT use a window function result in the same SELECT — always wrap in CTE/subquery first.
