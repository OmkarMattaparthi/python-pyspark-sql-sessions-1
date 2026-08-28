# Day 9 Notes — SQL Revision: Data Engineering Interview Concepts

> This is a **revision sheet** — not new theory.
> Use it to quickly recall key patterns before solving `day9_problems.sql`.

---

## Topics That Appear Most in DE SQL Interviews

1. Deduplication with ROW_NUMBER
2. Running totals and cumulative aggregates
3. Gap detection with LAG/LEAD
4. Top-N per group (ranking)
5. Date spine + gap-fill with generate_series
6. FULL OUTER JOIN reconciliation
7. Conditional aggregation with CASE inside SUM/COUNT
8. Self-join for hierarchical or sequential comparisons
9. CTEs for multi-step logic
10. NULL-safe comparisons and COALESCE

---

## 1. Deduplication — ROW_NUMBER Pattern

```sql
-- Keep only the most recent record per key
WITH deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id        -- group by key
            ORDER BY updated_at DESC        -- most recent first
        ) AS rn
    FROM raw_events
)
SELECT * FROM deduped WHERE rn = 1;
```

**When to use:** landing table has duplicates from CDC, re-ingestion, or API retries.

---

## 2. Running Totals

```sql
-- Cumulative revenue per customer over time
SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date)

-- Running % of total
SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date)
    / SUM(amount) OVER (PARTITION BY customer_id) * 100
```

---

## 3. Gap Detection — LAG Pattern

```sql
-- Find orders where gap from previous order > 30 days (churn detection)
WITH gaps AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_date
    FROM orders
)
SELECT *, order_date - prev_date AS gap_days
FROM gaps
WHERE order_date - prev_date > 30;
```

---

## 4. Top-N Per Group — RANK Pattern

```sql
-- Top 2 products per category by revenue
WITH ranked AS (
    SELECT
        category,
        product_name,
        SUM(revenue) AS total_revenue,
        RANK() OVER (PARTITION BY category ORDER BY SUM(revenue) DESC) AS rnk
    FROM sales
    GROUP BY category, product_name
)
SELECT * FROM ranked WHERE rnk <= 2;
```

---

## 5. Date Spine + Gap Fill — generate_series Pattern

```sql
-- Monthly report — every month shows even if no orders
SELECT
    gs.month,
    COALESCE(SUM(o.amount), 0) AS revenue
FROM generate_series('2024-01-01'::DATE, '2024-12-01'::DATE, '1 month') AS gs(month)
LEFT JOIN orders o ON DATE_TRUNC('month', o.order_date)::DATE = gs.month
GROUP BY gs.month
ORDER BY gs.month;
```

---

## 6. Reconciliation — FULL OUTER JOIN Pattern

```sql
-- Compare staging vs production: find inserts, deletes, updates needed
SELECT
    COALESCE(s.id, p.id) AS id,
    CASE
        WHEN p.id IS NULL            THEN 'INSERT'
        WHEN s.id IS NULL            THEN 'DELETE'
        WHEN s.salary <> p.salary    THEN 'UPDATE'
        ELSE                              'MATCH'
    END AS action
FROM staging s
FULL OUTER JOIN production p USING (id);
```

---

## 7. Conditional Aggregation

```sql
-- Pivot-style: count by status without GROUP BY pivot
SELECT
    dept_id,
    COUNT(*)                              AS total,
    COUNT(*) FILTER (WHERE status = 'active')    AS active_count,
    SUM(salary) FILTER (WHERE status = 'active') AS active_payroll
    -- or with CASE:
    -- SUM(CASE WHEN status = 'active' THEN salary ELSE 0 END) AS active_payroll
FROM employees
GROUP BY dept_id;
```

---

## 8. CTE Chaining — Multi-step Logic

```sql
-- Step 1: aggregate → Step 2: rank → Step 3: filter
WITH monthly_revenue AS (
    SELECT DATE_TRUNC('month', order_date) AS month, SUM(amount) AS revenue
    FROM orders GROUP BY 1
),
ranked AS (
    SELECT *, RANK() OVER (ORDER BY revenue DESC) AS rnk
    FROM monthly_revenue
)
SELECT * FROM ranked WHERE rnk <= 3;
```

---

## 9. NULL-Safe Patterns

```sql
-- Never: col1 = NULL   (always returns unknown, never true)
-- Always: col1 IS NULL

-- Safe division (avoid division by zero)
salary / NULLIF(hours_worked, 0)

-- Coalesce chain — first non-null wins
COALESCE(preferred_name, first_name, 'Unknown')

-- NULL-safe string join
CONCAT_WS(', ', city, NULLIF(country, ''))

-- NOT IN with NULLs is a trap
-- If subquery returns even one NULL → NOT IN returns no rows
-- Use NOT EXISTS instead
WHERE NOT EXISTS (SELECT 1 FROM dept_blacklist WHERE dept_blacklist.id = e.dept_id)
```

---

## 10. Key Interview Patterns — One-Liners

| Pattern | SQL approach |
|---------|-------------|
| Latest record per key | `ROW_NUMBER() OVER (PARTITION BY key ORDER BY ts DESC)` → filter rn=1 |
| Rank within group | `DENSE_RANK() OVER (PARTITION BY grp ORDER BY val DESC)` |
| Month-over-month Δ | `LAG(val) OVER (ORDER BY month)` |
| Gap-free date report | `generate_series` + `LEFT JOIN` |
| Staging vs prod diff | `FULL OUTER JOIN` + CASE on NULL sides |
| Running % of total | `SUM(val) OVER (PARTITION BY grp ORDER BY date) / SUM(val) OVER (PARTITION BY grp)` |
| Dedup on load | `ROW_NUMBER` in CTE → `WHERE rn = 1` → INSERT |
| Churn signal | `LEAD(order_date) OVER (...) - order_date > 30` |
| Pivot column | `SUM(CASE WHEN status='x' THEN 1 ELSE 0 END)` |
| Remove empty strings | `NULLIF(col, '')` |

---

## SQL Clause Execution Order (Interview Favourite)

```
1. FROM  / JOIN        — load and join tables
2. WHERE               — filter rows
3. GROUP BY            — group remaining rows
4. HAVING              — filter groups
5. SELECT              — compute output columns (window functions run here)
6. DISTINCT            — remove duplicates
7. ORDER BY            — sort
8. LIMIT / OFFSET      — paginate
```

> Window functions run in step 5 (SELECT), so they **cannot** appear in WHERE or HAVING.
> To filter on a window function result, wrap in a CTE or subquery.
