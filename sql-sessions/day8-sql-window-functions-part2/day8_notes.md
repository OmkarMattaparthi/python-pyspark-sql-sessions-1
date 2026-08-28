# Day 8 Notes — Window Functions Part 2: Quick Revision

> This is a **revision-style** notes sheet. Read this before running `day8_practice.sql`.
> For full theory see `day7_notes.md`.

---

## Recap: The Window Function Mental Model

```
function()  OVER  (  PARTITION BY col   ORDER BY col   ROWS BETWEEN ... )
    ↑                      ↑                  ↑               ↑
what to         divide into       order rows          which rows
compute         groups (like      within the          to include
                GROUP BY but      group               in the calc
                no collapsing)
```

- **No PARTITION BY** → one big group = the entire result set
- **No ORDER BY** → unordered; aggregates see all rows in the partition
- **ORDER BY present** → default frame becomes `RANGE UNBOUNDED PRECEDING TO CURRENT ROW` (running/cumulative)
- **No frame clause** → depends on whether ORDER BY is present (see above)

---

## LAG — Previous Row

```sql
LAG(column, offset, default)  OVER (PARTITION BY ... ORDER BY ...)
```

| Arg | Default | Meaning |
|-----|---------|---------|
| `column` | required | Which value to look back at |
| `offset` | 1 | How many rows back |
| `default` | NULL | Returned for the first row (no prev) |

```sql
-- Previous order amount
LAG(amount) OVER (ORDER BY order_date)

-- Previous order per customer (resets per customer)
LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date)

-- Days since last order
order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
```

**Use for:** month-over-month change, gap detection, comparing row to its predecessor.

---

## LEAD — Next Row

```sql
LEAD(column, offset, default)  OVER (PARTITION BY ... ORDER BY ...)
```

Mirror of LAG — looks **forward** instead of backward. Last row in partition returns NULL or default.

```sql
-- Days until next order (churn detection)
LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) - order_date
```

**Use for:** look-ahead, time-to-next-event, finding the "last known" order (NULL next = most recent).

---

## Running Totals — SUM/AVG/COUNT with ORDER BY

Adding `ORDER BY` inside an aggregate window function creates a **cumulative** result.

```sql
-- Cumulative sum from first row to current row (default frame)
SUM(amount) OVER (ORDER BY order_date)

-- Per-partition cumulative (resets per group)
SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date)

-- Common columns to add alongside
COUNT(*) OVER (ORDER BY order_date)  -- running count
AVG(amount) OVER (ORDER BY order_date)  -- running average
```

> **Gotcha:** `SUM(salary) OVER (PARTITION BY dept_id ORDER BY salary)` is a **cumulative** sum within the dept, NOT the dept total. Remove ORDER BY to get the full partition total.

---

## ROWS BETWEEN — Window Frames

```
ROWS BETWEEN  <start>  AND  <end>
```

| Boundary | Meaning |
|----------|---------|
| `UNBOUNDED PRECEDING` | First row of partition |
| `n PRECEDING` | n rows before current row |
| `CURRENT ROW` | This row |
| `n FOLLOWING` | n rows after current row |
| `UNBOUNDED FOLLOWING` | Last row of partition |

```sql
-- Running total (default when ORDER BY present)
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Full partition total (same result as no ORDER BY)
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- 3-row centered moving average
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING

-- 7-day trailing rolling window
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
```

---

## FIRST_VALUE / LAST_VALUE / NTH_VALUE

```sql
FIRST_VALUE(col) OVER (PARTITION BY ... ORDER BY ...)
-- Returns value from the first row of the frame (safe with default frame)

LAST_VALUE(col) OVER (
    PARTITION BY ... ORDER BY ...
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- ← REQUIRED
)
-- Without full frame → returns CURRENT ROW value (common bug!)

NTH_VALUE(col, 2) OVER (
    PARTITION BY ... ORDER BY ...
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- ← REQUIRED
)
-- Returns value from the 2nd row; NULL if partition has < 2 rows
```

> **Rule of thumb:** Always add the full frame when using `LAST_VALUE` or `NTH_VALUE`.

---

## WINDOW Clause — Named Windows

```sql
SELECT
    name,
    ROW_NUMBER()  OVER w  AS rn,
    RANK()        OVER w  AS rnk,
    DENSE_RANK()  OVER w  AS dense_rnk
FROM employees
WINDOW w AS (PARTITION BY dept_id ORDER BY salary DESC);
```

- Avoids repeating the same `OVER(...)` definition
- Change the window once — all references update
- Can define multiple named windows in one `WINDOW` clause

---

## Common Mistakes — Quick Reference

| Mistake | Wrong | Right |
|---------|-------|-------|
| Window fn in WHERE | `WHERE ROW_NUMBER() OVER (...) = 1` | Wrap in CTE/subquery, then filter |
| LAST_VALUE without frame | `LAST_VALUE(col) OVER (ORDER BY ...)` | Add `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` |
| Running total vs partition total | `SUM(s) OVER (PARTITION BY d ORDER BY ...)` = cumulative | Remove `ORDER BY` for full partition total |
| ORDER BY confusion | Thinking window ORDER BY = output sort order | They are independent; add separate `ORDER BY` at end for display |
| RANK vs ROW_NUMBER | Using RANK for dedup (ties get same number → multiple rows returned) | Use ROW_NUMBER for dedup; RANK for "top N values" |

---

## Frame Behaviour Summary

| OVER() clause | What you get |
|---------------|-------------|
| `OVER ()` | Aggregate of entire result set |
| `OVER (PARTITION BY dept)` | Aggregate of each dept (full partition) |
| `OVER (ORDER BY date)` | Running total — default frame UNBOUNDED PRECEDING to CURRENT ROW |
| `OVER (PARTITION BY dept ORDER BY date)` | Running total within each dept |
| `OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` | 7-day rolling window |
| `OVER (ORDER BY date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)` | 3-row centered moving window |
