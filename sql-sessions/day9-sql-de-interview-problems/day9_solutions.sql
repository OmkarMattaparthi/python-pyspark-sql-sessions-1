-- =============================================================
-- Day 9 — SOLUTION SHEET
-- *** For instructor use only — do not share with students ***
-- =============================================================


-- =============================================================
-- SOLUTION 1 — Deduplication with ROW_NUMBER
-- =============================================================
-- Pattern: CTE assigns row number per customer ordered by updated_at DESC.
-- Outer query filters rn = 1 → one row per customer, the most recent one.

WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY updated_at DESC
        ) AS rn
    FROM de_interview.raw_events
)
SELECT
    customer_id,
    name,
    email,
    tier,
    salary,
    updated_at
FROM deduped
WHERE rn = 1
ORDER BY customer_id;


-- =============================================================
-- SOLUTION 2 — Running Total + Cumulative % of Group
-- =============================================================
-- Two window functions on the same partition:
--   SUM with ORDER BY → running total (cumulative)
--   SUM without ORDER BY → full customer total (constant per partition)
-- Dividing the two gives the running percentage.

SELECT
    customer_id,
    order_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    )                                                          AS customer_running_total,
    SUM(amount) OVER (
        PARTITION BY customer_id
    )                                                          AS customer_total,
    ROUND(
        SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date)
        / SUM(amount) OVER (PARTITION BY customer_id) * 100
    , 2)                                                       AS pct_of_customer_total
FROM de_interview.orders
ORDER BY customer_id, order_date;


-- =============================================================
-- SOLUTION 3 — Gap Detection (Churn Signal)
-- =============================================================
-- LAG retrieves each customer's previous order date within their partition.
-- Subtracting dates gives gap_days. CASE labels based on the gap.

SELECT
    customer_id,
    order_date,
    amount,
    LAG(order_date) OVER (
        PARTITION BY customer_id ORDER BY order_date
    )                    AS prev_order_date,
    order_date - LAG(order_date) OVER (
        PARTITION BY customer_id ORDER BY order_date
    )                    AS gap_days,
    CASE
        WHEN LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) IS NULL
            THEN 'First Order'
        WHEN order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) > 30
            THEN 'Yes'
        ELSE 'No'
    END                  AS is_churn_signal
FROM de_interview.orders
ORDER BY customer_id, order_date;


-- =============================================================
-- SOLUTION 4A — Top 2 Products per Category by Revenue
-- =============================================================
-- Step 1 (CTE): aggregate to product level (sum across all months)
-- Step 2: RANK within each category by descending revenue
-- Step 3: filter WHERE rank <= 2

WITH product_totals AS (
    SELECT
        category,
        product_name,
        SUM(revenue)    AS total_revenue,
        SUM(units_sold) AS total_units
    FROM de_interview.product_sales
    GROUP BY category, product_name
),
ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY category
            ORDER BY total_revenue DESC
        ) AS rank_in_category
    FROM product_totals
)
SELECT
    category,
    product_name,
    total_revenue,
    total_units,
    rank_in_category
FROM ranked
WHERE rank_in_category <= 2
ORDER BY category, rank_in_category;


-- =============================================================
-- SOLUTION 4B — Monthly Revenue Pivot per Category
-- =============================================================
-- Conditional aggregation: SUM with FILTER (or CASE) per month column.

SELECT
    category,
    SUM(revenue) FILTER (WHERE EXTRACT(MONTH FROM sale_date) = 1)   AS jan_revenue,
    SUM(revenue) FILTER (WHERE EXTRACT(MONTH FROM sale_date) = 2)   AS feb_revenue,
    SUM(revenue) FILTER (WHERE EXTRACT(MONTH FROM sale_date) = 3)   AS mar_revenue,
    SUM(revenue)                                                     AS total_revenue
FROM de_interview.product_sales
GROUP BY category
ORDER BY category;

-- Alternative using CASE (same result, works in all SQL dialects):
SELECT
    category,
    SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 1 THEN revenue ELSE 0 END) AS jan_revenue,
    SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 2 THEN revenue ELSE 0 END) AS feb_revenue,
    SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 3 THEN revenue ELSE 0 END) AS mar_revenue,
    SUM(revenue)                                                              AS total_revenue
FROM de_interview.product_sales
GROUP BY category
ORDER BY category;


-- =============================================================
-- SOLUTION 5 — Date Spine + Month-over-Month Revenue Change
-- =============================================================
-- Step 1: generate_series builds the 12-month spine for 2024.
-- Step 2: LEFT JOIN daily_revenue → missing months get NULL revenue.
-- Step 3: COALESCE turns NULL revenue to 0.
-- Step 4: LAG looks at the previous month's revenue.
-- Step 5: Compute change and pct_change; NULLIF avoids division-by-zero
--         (prev = 0 when a previous month had no data).
-- Step 6: CASE labels the trend.
-- All window functions must go in an outer query — cannot LAG on a
-- computed COALESCE column in the same SELECT level.

WITH spine AS (
    SELECT
        gs::DATE                                            AS month_start,
        TO_CHAR(gs, 'Mon-YYYY')                            AS month_label
    FROM generate_series(
        '2024-01-01'::DATE,
        '2024-12-01'::DATE,
        '1 month'::INTERVAL
    ) AS gs
),
joined AS (
    SELECT
        s.month_start,
        s.month_label,
        COALESCE(dr.revenue, 0)                            AS revenue
    FROM spine s
    LEFT JOIN de_interview.daily_revenue dr
        ON DATE_TRUNC('month', dr.rev_date)::DATE = s.month_start
),
with_lag AS (
    SELECT
        month_start,
        month_label,
        revenue,
        LAG(revenue) OVER (ORDER BY month_start)           AS prev_revenue,
        revenue - LAG(revenue) OVER (ORDER BY month_start) AS mom_change
    FROM joined
)
SELECT
    month_label,
    revenue,
    prev_revenue,
    mom_change,
    ROUND(
        mom_change / NULLIF(prev_revenue, 0) * 100
    , 2)                                                   AS mom_pct_change,
    CASE
        WHEN revenue = 0          THEN 'No Data'
        WHEN prev_revenue IS NULL THEN 'Growth'
        WHEN revenue > prev_revenue THEN 'Growth'
        WHEN revenue < prev_revenue THEN 'Decline'
        ELSE 'Flat'
    END                                                    AS trend
FROM with_lag
ORDER BY month_start;
