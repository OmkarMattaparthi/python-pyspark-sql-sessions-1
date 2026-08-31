-- =============================================================
-- Problem 6 Hard Solution — Per-Dept Summary: Best/Worst Month + MoM Trend
-- *** Instructor use only ***
-- =============================================================


-- =============================================================
-- APPROACH 1 — CTE chain: MoM changes → counts → department summary
-- =============================================================

WITH mom AS (
    SELECT
        dept,
        month,
        revenue,
        LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS prev_revenue,
        revenue - LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS mom_change
    FROM monthly_revenue
),
labeled AS (
    SELECT
        dept,
        month,
        revenue,
        mom_change,
        CASE
            WHEN mom_change > 0  THEN 'Increase'
            WHEN mom_change < 0  THEN 'Decrease'
            WHEN mom_change = 0  THEN 'No Change'
        END AS trend
    FROM mom
    WHERE mom_change IS NOT NULL
),
best_worst AS (
    SELECT
        dept,
        MAX(revenue) AS best_revenue,
        MIN(revenue) AS worst_revenue
    FROM monthly_revenue
    GROUP BY dept
),
best_month AS (
    SELECT DISTINCT ON (mr.dept)
        mr.dept,
        mr.month AS best_month,
        mr.revenue AS best_revenue
    FROM monthly_revenue mr
    JOIN best_worst bw ON mr.dept = bw.dept AND mr.revenue = bw.best_revenue
    ORDER BY mr.dept, mr.month
),
worst_month AS (
    SELECT DISTINCT ON (mr.dept)
        mr.dept,
        mr.month AS worst_month,
        mr.revenue AS worst_revenue
    FROM monthly_revenue mr
    JOIN best_worst bw ON mr.dept = bw.dept AND mr.revenue = bw.worst_revenue
    ORDER BY mr.dept, mr.month
),
trend_counts AS (
    SELECT
        dept,
        ROUND(AVG(mom_change), 2) AS avg_mom_change,
        SUM(CASE WHEN trend = 'Increase'  THEN 1 ELSE 0 END) AS inc_cnt,
        SUM(CASE WHEN trend = 'Decrease'  THEN 1 ELSE 0 END) AS dec_cnt,
        SUM(CASE WHEN trend = 'No Change' THEN 1 ELSE 0 END) AS nc_cnt
    FROM labeled
    GROUP BY dept
)
SELECT
    tc.dept,
    bm.best_month,
    bm.best_revenue,
    wm.worst_month,
    wm.worst_revenue,
    tc.avg_mom_change,
    tc.inc_cnt || ' Increase, ' || tc.dec_cnt || ' Decrease, ' || tc.nc_cnt || ' No Change' AS trend_summary
FROM trend_counts tc
JOIN best_month bm ON tc.dept = bm.dept
JOIN worst_month wm ON tc.dept = wm.dept
ORDER BY tc.dept;


-- =============================================================
-- APPROACH 2 — Using FIRST_VALUE / LAST_VALUE for best/worst
-- =============================================================
-- FIRST_VALUE ordered by revenue DESC gives the best month;
-- FIRST_VALUE ordered by revenue ASC gives the worst.

WITH mom AS (
    SELECT
        dept,
        month,
        revenue,
        revenue - LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS mom_change
    FROM monthly_revenue
),
enriched AS (
    SELECT
        dept,
        month,
        revenue,
        mom_change,
        FIRST_VALUE(month) OVER (PARTITION BY dept ORDER BY revenue DESC) AS best_month,
        FIRST_VALUE(revenue) OVER (PARTITION BY dept ORDER BY revenue DESC) AS best_revenue,
        FIRST_VALUE(month) OVER (PARTITION BY dept ORDER BY revenue ASC)  AS worst_month,
        FIRST_VALUE(revenue) OVER (PARTITION BY dept ORDER BY revenue ASC) AS worst_revenue
    FROM mom
)
SELECT
    dept,
    MAX(best_month)    AS best_month,
    MAX(best_revenue)  AS best_revenue,
    MAX(worst_month)   AS worst_month,
    MAX(worst_revenue) AS worst_revenue,
    ROUND(AVG(mom_change), 2) AS avg_mom_change,
    SUM(CASE WHEN mom_change > 0 THEN 1 ELSE 0 END) || ' Increase, ' ||
    SUM(CASE WHEN mom_change < 0 THEN 1 ELSE 0 END) || ' Decrease, ' ||
    SUM(CASE WHEN mom_change = 0 THEN 1 ELSE 0 END) || ' No Change'  AS trend_summary
FROM enriched
WHERE mom_change IS NOT NULL
GROUP BY dept
ORDER BY dept;


-- =============================================================
-- APPROACH 3 — Aggregation-only (no window for best/worst)
-- =============================================================
-- Use a subquery to find best/worst month from simple GROUP BY + aggregation.

WITH mom AS (
    SELECT
        dept,
        month,
        revenue,
        revenue - LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS mom_change
    FROM monthly_revenue
),
agg AS (
    SELECT
        dept,
        ROUND(AVG(mom_change), 2) AS avg_mom_change,
        SUM(CASE WHEN mom_change > 0 THEN 1 ELSE 0 END) AS inc_cnt,
        SUM(CASE WHEN mom_change < 0 THEN 1 ELSE 0 END) AS dec_cnt,
        SUM(CASE WHEN mom_change = 0 THEN 1 ELSE 0 END) AS nc_cnt
    FROM mom
    WHERE mom_change IS NOT NULL
    GROUP BY dept
),
extremes AS (
    SELECT
        mr.dept,
        MAX(mr.revenue) AS best_revenue,
        MIN(mr.revenue) AS worst_revenue
    FROM monthly_revenue mr
    GROUP BY mr.dept
),
best AS (
    SELECT DISTINCT ON (e.dept)
        e.dept, mr.month AS best_month, e.best_revenue
    FROM extremes e
    JOIN monthly_revenue mr ON e.dept = mr.dept AND mr.revenue = e.best_revenue
    ORDER BY e.dept, mr.month
),
worst AS (
    SELECT DISTINCT ON (e.dept)
        e.dept, mr.month AS worst_month, e.worst_revenue
    FROM extremes e
    JOIN monthly_revenue mr ON e.dept = mr.dept AND mr.revenue = e.worst_revenue
    ORDER BY e.dept, mr.month
)
SELECT
    a.dept,
    b.best_month,
    b.best_revenue,
    w.worst_month,
    w.worst_revenue,
    a.avg_mom_change,
    a.inc_cnt || ' Increase, ' || a.dec_cnt || ' Decrease, ' || a.nc_cnt || ' No Change' AS trend_summary
FROM agg a
JOIN best b ON a.dept = b.dept
JOIN worst w ON a.dept = w.dept
ORDER BY a.dept;

-- Note:
--   avg_mom_change excludes the first month of each dept (no prior month exists →
--   mom_change IS NULL). WHERE mom_change IS NOT NULL handles this consistently.
--   trend_summary format: '<N> Increase, <N> Decrease, <N> No Change'
