# Day 7 Notes — Window Functions Part 1

> **Part 2 continues in `day8_notes.md`**: LAG, LEAD, running totals, ROWS BETWEEN, FIRST_VALUE, LAST_VALUE, WINDOW clause.

## Topics Covered (Day 7)
1. What is a window function and how it differs from GROUP BY
2. The OVER() clause — syntax and structure
3. PARTITION BY — defining the window group
4. ORDER BY inside OVER() — defining row order within the window
5. Ranking functions — ROW_NUMBER, RANK, DENSE_RANK, NTILE

---

## 1. What is a Window Function?

A **window function** computes a value for each row based on a **set of related rows** (the "window") — without collapsing those rows into one like GROUP BY does.

```
employees table                    GROUP BY result         Window function result
-----------------------            ----------------        ----------------------
dept | name   | salary             dept | avg_salary       dept | name  | salary | avg_salary
-----+--------+--------            -----+------------      -----+-------+--------+-----------
  1  | Alice  | 90000       →        1  |  82500           1    | Alice | 90000  |  82500
  1  | Bob    | 75000                2  |  65000           1    | Bob   | 75000  |  82500
  2  | Carol  | 70000                                      2    | Carol | 70000  |  65000
  2  | David  | 60000                                      2    | David | 60000  |  65000
```

GROUP BY collapses 4 rows into 2. The window function keeps all 4 rows AND adds the average per department alongside each row.

### Key rule
> A window function NEVER reduces the number of rows in the result.
> It adds a new computed column alongside existing rows.

---

## 2. The OVER() Clause

Every window function uses `OVER()`. Without `OVER()`, SUM/AVG/COUNT are just regular aggregate functions.

```sql
-- Syntax
function_name(expression) OVER (
    PARTITION BY column(s)   -- optional: divide rows into groups
    ORDER BY    column(s)    -- optional: define order within each group
    ROWS/RANGE  BETWEEN ...  -- optional: limit which rows to include
)
```

```sql
-- Empty OVER() — window = the entire result set
SELECT name, salary, AVG(salary) OVER () AS company_avg
FROM employees;

-- With PARTITION BY — window = each department separately
SELECT name, dept_id, salary, AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg
FROM employees;

-- With ORDER BY — window = rows up to and including current row (running total)
SELECT name, salary, SUM(salary) OVER (ORDER BY emp_id) AS running_total
FROM employees;
```

---

## 3. PARTITION BY — Dividing into Groups

`PARTITION BY` is like GROUP BY but for window functions — it divides rows into partitions and the function is computed independently within each partition.

```sql
-- Average salary per department, shown for every employee row
SELECT
    emp_id,
    name,
    dept_id,
    salary,
    AVG(salary) OVER (PARTITION BY dept_id)          AS dept_avg_salary,
    salary - AVG(salary) OVER (PARTITION BY dept_id) AS diff_from_avg
FROM employees;
```

Without `PARTITION BY`, the window covers ALL rows (the whole table).

---

## 4. ORDER BY inside OVER()

`ORDER BY` inside `OVER()` controls the **order of rows within the window**, not the order of the final result set.

```sql
-- Running total of salary ordered by hire_date
SELECT
    name,
    hire_date,
    salary,
    SUM(salary) OVER (ORDER BY hire_date)   AS running_total
FROM employees;
```

> When you add `ORDER BY` to a window aggregate (SUM, AVG, etc.), PostgreSQL applies a default frame of `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` — meaning "all rows from the start up to and including the current row."

---

## 5. Ranking Functions

Ranking functions assign a rank number to each row based on ORDER BY within the window.

### ROW_NUMBER
Always assigns a unique sequential integer — no ties, no gaps.

```sql
SELECT
    name,
    dept_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS row_num
FROM employees;
-- Each employee within a dept gets 1, 2, 3 … even if salaries are equal
```

### RANK
Same rank for ties, but **skips** the next rank number.

```sql
SELECT
    name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS rnk
FROM employees;
-- If two employees both have salary 80000 they both get rank 1.
-- The next employee gets rank 3 (skips 2).
```

### DENSE_RANK
Same rank for ties, but **no gaps** after ties.

```sql
SELECT
    name,
    salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
FROM employees;
-- Two employees at 80000 both get rank 1.
-- The next employee gets rank 2 (not 3).
```

### Comparing the three

```
salary  | ROW_NUMBER | RANK | DENSE_RANK
--------|-----------|------|----------
 90000  |     1      |  1   |    1
 80000  |     2      |  2   |    2
 80000  |     3      |  2   |    2    ← tie: RANK and DENSE_RANK both 2
 75000  |     4      |  4   |    3    ← RANK skips to 4; DENSE_RANK goes to 3
 60000  |     5      |  5   |    4
```

### NTILE
Divides rows into N equal buckets and assigns the bucket number.

```sql
SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC)  AS quartile
FROM employees;
-- Splits employees into 4 roughly equal groups: 1 = top 25%, 4 = bottom 25%
```

---

## 6. Offset Functions — LAG and LEAD

These look at a **different row** relative to the current row within the window.

### LAG — look at the previous row

```sql
-- LAG(column, offset, default)
-- offset = how many rows back (default 1)
-- default = value to return if there's no previous row (default NULL)

SELECT
    order_date,
    amount,
    LAG(amount)       OVER (ORDER BY order_date)  AS prev_amount,
    LAG(amount, 1, 0) OVER (ORDER BY order_date)  AS prev_amount_or_0
FROM orders;
```

### LEAD — look at the next row

```sql
-- LEAD(column, offset, default)
SELECT
    order_date,
    amount,
    LEAD(amount)       OVER (ORDER BY order_date)  AS next_amount,
    LEAD(amount, 1, 0) OVER (ORDER BY order_date)  AS next_amount_or_0
FROM orders;
```

### Month-over-month comparison using LAG

```sql
SELECT
    order_month,
    revenue,
    LAG(revenue) OVER (ORDER BY order_month)                               AS prev_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY order_month)                     AS change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0) * 100, 2
    )                                                                      AS pct_change
FROM monthly_sales;
```

---

## 7. Aggregate Window Functions

Standard aggregate functions (SUM, AVG, COUNT, MIN, MAX) become window functions when you add `OVER()`.

```sql
SELECT
    name,
    dept_id,
    salary,
    SUM(salary)   OVER (PARTITION BY dept_id)  AS dept_total,
    AVG(salary)   OVER (PARTITION BY dept_id)  AS dept_avg,
    COUNT(*)      OVER (PARTITION BY dept_id)  AS dept_headcount,
    MIN(salary)   OVER (PARTITION BY dept_id)  AS dept_min,
    MAX(salary)   OVER (PARTITION BY dept_id)  AS dept_max
FROM employees;
```

**All in one row** — you see the employee's own salary AND all department-level aggregates on the same row.

---

## 8. Running Totals and Cumulative Aggregates

Add `ORDER BY` inside the aggregate window function to get cumulative / running values.

```sql
-- Running total of salary (ordered by hire date)
SELECT
    name,
    hire_date,
    salary,
    SUM(salary) OVER (ORDER BY hire_date)              AS running_total,
    AVG(salary) OVER (ORDER BY hire_date)              AS running_avg,
    COUNT(*)    OVER (ORDER BY hire_date)              AS running_count
FROM employees;

-- Running total PER DEPARTMENT
SELECT
    name,
    dept_id,
    hire_date,
    salary,
    SUM(salary) OVER (PARTITION BY dept_id ORDER BY hire_date)  AS dept_running_total
FROM employees;
```

---

## 9. Window Frames — ROWS BETWEEN / RANGE BETWEEN

A **frame** limits which rows within the partition are included in the calculation relative to the current row.

```
ROWS  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW   ← from start to current row (running total)
ROWS  BETWEEN 1 PRECEDING AND 1 FOLLOWING           ← previous, current, next row (3-row window)
ROWS  BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING ← all rows in partition
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW   ← same as ROWS but by value, not row position
```

```sql
-- Default frame when ORDER BY is present: RANGE UNBOUNDED PRECEDING to CURRENT ROW
SUM(salary) OVER (ORDER BY salary)         -- cumulative (default frame)

-- Explicit all rows — same as OVER() with no ORDER BY
SUM(salary) OVER (
    PARTITION BY dept_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)

-- 3-row moving average (previous row + current row + next row)
SELECT
    order_date,
    daily_sales,
    AVG(daily_sales) OVER (
        ORDER BY order_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS moving_avg_3day
FROM daily_sales;

-- 7-day rolling sum
SELECT
    order_date,
    daily_sales,
    SUM(daily_sales) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day
FROM daily_sales;
```

### Frame keywords

| Keyword | Meaning |
|---------|---------|
| `UNBOUNDED PRECEDING` | First row of the partition |
| `n PRECEDING` | n rows before the current row |
| `CURRENT ROW` | The current row |
| `n FOLLOWING` | n rows after the current row |
| `UNBOUNDED FOLLOWING` | Last row of the partition |

---

## 10. Named Windows — WINDOW Clause

When you use the same window definition multiple times, name it with a `WINDOW` clause to avoid repetition.

```sql
-- Without named window — repeated OVER() definition
SELECT
    name,
    salary,
    ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS row_num,
    RANK()       OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dense_rnk
FROM employees;

-- With named window — cleaner and less error-prone
SELECT
    name,
    salary,
    ROW_NUMBER() OVER w  AS row_num,
    RANK()       OVER w  AS rnk,
    DENSE_RANK() OVER w  AS dense_rnk
FROM employees
WINDOW w AS (PARTITION BY dept_id ORDER BY salary DESC);
```

---

## 11. FIRST_VALUE, LAST_VALUE, NTH_VALUE

These return specific values from within the window frame.

```sql
-- FIRST_VALUE — value from the first row of the window
SELECT
    name,
    dept_id,
    salary,
    FIRST_VALUE(name)   OVER (PARTITION BY dept_id ORDER BY salary DESC)  AS top_earner,
    LAST_VALUE(name)    OVER (
        PARTITION BY dept_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                                      AS lowest_earner
FROM employees;

-- NTH_VALUE — value from the Nth row of the window
SELECT
    name,
    salary,
    NTH_VALUE(name, 2) OVER (
        PARTITION BY dept_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS second_highest_earner
FROM employees;
```

> `LAST_VALUE` and `NTH_VALUE` require an explicit frame of `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` to see the full partition — otherwise the default frame stops at the current row.

---

## 12. Common Mistakes

### Mistake 1 — Using window function in WHERE
```sql
-- WRONG: window functions are not allowed in WHERE
SELECT * FROM employees
WHERE ROW_NUMBER() OVER (ORDER BY salary DESC) = 1;   -- ERROR

-- RIGHT: wrap in a subquery or CTE
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
    FROM employees
) t
WHERE rn = 1;
```

### Mistake 2 — LAST_VALUE returning current row
```sql
-- WRONG: LAST_VALUE without full frame returns the current row, not the last
SELECT name, LAST_VALUE(name) OVER (PARTITION BY dept_id ORDER BY salary DESC)
-- Returns the current row's name, not the lowest earner

-- RIGHT: extend the frame
SELECT name, LAST_VALUE(name) OVER (
    PARTITION BY dept_id ORDER BY salary DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

### Mistake 3 — Confusing ORDER BY in OVER() with ORDER BY in the query
```sql
-- ORDER BY inside OVER() → controls window computation
-- ORDER BY at the end of SELECT → controls final result order
-- Both can exist and they are independent
SELECT name, salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC)  AS rn  -- window order: high to low
FROM employees
ORDER BY name;   -- final result: alphabetical
```

### Mistake 4 — RANK vs DENSE_RANK vs ROW_NUMBER
```sql
-- Use ROW_NUMBER when you need uniqueness (pagination, deduplication)
-- Use RANK when you want gaps after ties (Olympic-style: 1, 1, 3)
-- Use DENSE_RANK when you want no gaps (1, 1, 2)
```

---

## Window Function Quick Reference

| Function | Category | What it does |
|----------|----------|-------------|
| `ROW_NUMBER()` | Ranking | Unique row number, no ties |
| `RANK()` | Ranking | Rank with gaps after ties |
| `DENSE_RANK()` | Ranking | Rank without gaps |
| `NTILE(n)` | Ranking | Divide into n buckets |
| `LAG(col, n, default)` | Offset | Value n rows before current |
| `LEAD(col, n, default)` | Offset | Value n rows after current |
| `FIRST_VALUE(col)` | Offset | First value in the window frame |
| `LAST_VALUE(col)` | Offset | Last value in the window frame |
| `NTH_VALUE(col, n)` | Offset | Nth value in the window frame |
| `SUM(col) OVER(...)` | Aggregate | Running/partitioned sum |
| `AVG(col) OVER(...)` | Aggregate | Running/partitioned average |
| `COUNT(*) OVER(...)` | Aggregate | Running/partitioned count |
| `MIN(col) OVER(...)` | Aggregate | Running/partitioned minimum |
| `MAX(col) OVER(...)` | Aggregate | Running/partitioned maximum |

---

## DE Relevance Summary

| Concept | Data Engineering Use |
|---------|---------------------|
| `ROW_NUMBER()` | Deduplicating records — pick the latest version of each key |
| `RANK() / DENSE_RANK()` | Top-N per group (top product per category, top customer per region) |
| `LAG / LEAD` | Month-over-month change, detecting sequence gaps in event logs |
| `SUM OVER (PARTITION BY)` | Running totals per group in fact tables without losing row-level detail |
| `AVG OVER (ROWS BETWEEN)` | Moving averages for time-series smoothing |
| `NTILE` | Bucketing users into cohorts (quartiles, deciles) for A/B analysis |
| `FIRST_VALUE / LAST_VALUE` | Finding the first/last event per session (session attribution) |
| `WINDOW clause` | Keeping window definitions DRY in complex analytical queries |
| Window + CTE | The standard pattern: compute window values in CTE, filter in outer query |
