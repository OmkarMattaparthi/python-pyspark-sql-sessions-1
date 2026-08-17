# SQL Pattern Solutions — PostgreSQL

Solutions for every problem in `sql_pattern_problems.md`.

---

## Pattern 1 — Top N per Group

### Easy — Top 1 rep per region

```sql
SELECT DISTINCT ON (region)
    region,
    rep_name,
    amount
FROM sales
ORDER BY region, amount DESC;
```

> `DISTINCT ON (region)` keeps the first row per region after `ORDER BY`. Since we order by `amount DESC`, the first row is always the highest earner.

Alternative using window function:

```sql
SELECT region, rep_name, amount
FROM (
    SELECT
        region,
        rep_name,
        amount,
        RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS rnk
    FROM sales
) ranked
WHERE rnk = 1
ORDER BY region;
```

---

### Medium — Top 2 reps per region

```sql
SELECT region, rnk AS rank, rep_name, amount
FROM (
    SELECT
        region,
        rep_name,
        amount,
        RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS rnk
    FROM sales
) ranked
WHERE rnk <= 2
ORDER BY region, rnk;
```

> `RANK()` is used (not `ROW_NUMBER()`) so ties both get rank 1 and are both included.
> `ROW_NUMBER()` would arbitrarily pick one in a tie — wrong for this requirement.

---

## Pattern 2 — Gaps and Islands

### Easy — Find gaps for user_id = 1

```sql
SELECT generate_series::DATE AS missing_date
FROM generate_series(
    '2024-01-01'::DATE,
    '2024-01-10'::DATE,
    INTERVAL '1 day'
) gs
WHERE gs::DATE NOT IN (
    SELECT login_date
    FROM user_logins
    WHERE user_id = 1
)
ORDER BY missing_date;
```

> `generate_series` produces every date in the range. Subtracting the actual login dates with `NOT IN` gives the gaps.

---

### Medium — Continuous login streaks (islands) per user

```sql
WITH numbered AS (
    SELECT
        user_id,
        login_date,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) AS rn
    FROM user_logins
),
grouped AS (
    SELECT
        user_id,
        login_date,
        login_date - (rn * INTERVAL '1 day') AS grp
    FROM numbered
)
SELECT
    user_id,
    MIN(login_date)                          AS streak_start,
    MAX(login_date)                          AS streak_end,
    MAX(login_date) - MIN(login_date) + 1    AS streak_days
FROM grouped
GROUP BY user_id, grp
ORDER BY user_id, streak_start;
```

> **Key insight:** If dates are consecutive, `login_date - ROW_NUMBER()` produces the same constant value for all dates in a streak. When a gap breaks the sequence, the constant shifts — creating a new group. `GROUP BY grp` then groups each island together.

---

## Pattern 3 — Running Total

### Easy — Global running total ordered by date

```sql
SELECT
    order_id,
    order_date,
    amount,
    SUM(amount) OVER (ORDER BY order_date, order_id) AS running_total
FROM orders
ORDER BY order_date, order_id;
```

> `order_id` is added as a tiebreaker in `ORDER BY` to make the running total deterministic when two orders share the same date.

---

### Medium — Running total per customer

```sql
SELECT
    customer_id,
    order_id,
    order_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date, order_id
    ) AS running_total
FROM orders
ORDER BY customer_id, order_date, order_id;
```

> `PARTITION BY customer_id` resets the running total for each new customer. Without `PARTITION BY`, the sum would continue across all customers.

---

## Pattern 4 — Moving Average

### Easy — 3-day moving average for AAPL

```sql
SELECT
    price_date,
    close_price,
    ROUND(
        AVG(close_price) OVER (
            ORDER BY price_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_3
FROM stock_prices
WHERE stock = 'AAPL'
ORDER BY price_date;
```

> `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` = current row + 2 rows before it = 3-row window.
> For the first row, only 1 value exists so avg = that value. For the second, 2 values are averaged.

---

### Medium — 3-day moving average per stock

```sql
SELECT
    stock,
    price_date,
    close_price,
    ROUND(
        AVG(close_price) OVER (
            PARTITION BY stock
            ORDER BY price_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_3
FROM stock_prices
ORDER BY stock, price_date;
```

> Adding `PARTITION BY stock` resets the window for each stock independently, so MSFT's first row isn't influenced by AAPL's data.

---

## Pattern 5 — First and Last Event

### Easy — First run timestamp per pipeline

```sql
SELECT
    pipeline,
    MIN(run_at) AS first_run
FROM pipeline_runs
GROUP BY pipeline
ORDER BY pipeline;
```

---

### Medium — First run, last run, and last run status

```sql
SELECT
    pipeline,
    MIN(run_at)                                              AS first_run,
    MAX(run_at)                                              AS last_run,
    FIRST_VALUE(status) OVER (
        PARTITION BY pipeline ORDER BY run_at DESC
    )                                                        AS last_status
FROM pipeline_runs
GROUP BY pipeline, status, run_at
ORDER BY pipeline;
```

Cleaner approach using `DISTINCT ON`:

```sql
WITH summary AS (
    SELECT
        pipeline,
        MIN(run_at) AS first_run,
        MAX(run_at) AS last_run
    FROM pipeline_runs
    GROUP BY pipeline
),
last_status AS (
    SELECT DISTINCT ON (pipeline)
        pipeline,
        status AS last_status
    FROM pipeline_runs
    ORDER BY pipeline, run_at DESC
)
SELECT
    s.pipeline,
    s.first_run,
    s.last_run,
    l.last_status
FROM summary s
JOIN last_status l ON s.pipeline = l.pipeline
ORDER BY s.pipeline;
```

> `DISTINCT ON (pipeline) ... ORDER BY pipeline, run_at DESC` picks the most recent row per pipeline efficiently.

---

## Pattern 6 — Previous and Next Record Comparison

### Easy — Previous month revenue

```sql
SELECT
    dept,
    month,
    revenue,
    LAG(revenue) OVER (
        PARTITION BY dept
        ORDER BY month
    ) AS prev_revenue
FROM monthly_revenue
ORDER BY dept, month;
```

> `LAG(revenue)` looks back 1 row within the same `dept` partition ordered by `month`. The first row of each dept gets `NULL` because there is no prior row.

---

### Medium — MoM change and trend

```sql
SELECT
    dept,
    month,
    revenue,
    LAG(revenue) OVER (PARTITION BY dept ORDER BY month)          AS prev_revenue,
    revenue - LAG(revenue) OVER (PARTITION BY dept ORDER BY month) AS change,
    CASE
        WHEN LAG(revenue) OVER (PARTITION BY dept ORDER BY month) IS NULL THEN NULL
        WHEN revenue > LAG(revenue) OVER (PARTITION BY dept ORDER BY month) THEN 'Increase'
        WHEN revenue < LAG(revenue) OVER (PARTITION BY dept ORDER BY month) THEN 'Decrease'
        ELSE 'No Change'
    END AS trend
FROM monthly_revenue
ORDER BY dept, month;
```

Cleaner with a CTE to avoid repeating the window expression:

```sql
WITH with_prev AS (
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
        WHEN prev_revenue IS NULL THEN NULL
        WHEN revenue > prev_revenue THEN 'Increase'
        WHEN revenue < prev_revenue THEN 'Decrease'
        ELSE 'No Change'
    END AS trend
FROM with_prev
ORDER BY dept, month;
```

---

## Pattern 7 — Sessionization

### Easy — Flag new session starts

```sql
SELECT
    user_id,
    event_time,
    page,
    CASE
        WHEN LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) IS NULL
          OR EXTRACT(EPOCH FROM (
                event_time - LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time)
             )) / 60 > 30
        THEN 1
        ELSE 0
    END AS is_new_session
FROM page_events
ORDER BY user_id, event_time;
```

> `EXTRACT(EPOCH FROM ...)` converts the interval to seconds, dividing by 60 gives minutes. The first event per user has no previous row (`LAG` returns NULL), so it is always a new session.

---

### Medium — Assign session IDs and summarize

```sql
WITH flagged AS (
    SELECT
        user_id,
        event_time,
        page,
        CASE
            WHEN LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) IS NULL
              OR EXTRACT(EPOCH FROM (
                    event_time - LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time)
                 )) / 60 > 30
            THEN 1
            ELSE 0
        END AS is_new_session
    FROM page_events
),
with_session_id AS (
    SELECT
        user_id,
        event_time,
        page,
        SUM(is_new_session) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS session_id
    FROM flagged
)
SELECT
    user_id,
    session_id,
    MIN(event_time)                        AS session_start,
    MAX(event_time)                        AS session_end,
    COUNT(*)                               AS page_count,
    STRING_AGG(page, ',' ORDER BY event_time) AS pages
FROM with_session_id
GROUP BY user_id, session_id
ORDER BY user_id, session_id;
```

> `SUM(is_new_session) OVER (PARTITION BY user_id ORDER BY event_time)` is a cumulative sum — it increments by 1 each time a new session starts, acting as a natural session counter per user.

---

## Pattern 8 — Conditional Aggregation

### Easy — Resolved vs Open count per agent

```sql
SELECT
    agent,
    COUNT(*)                                          AS total,
    COUNT(CASE WHEN status = 'Resolved' THEN 1 END)  AS resolved,
    COUNT(CASE WHEN status = 'Open'     THEN 1 END)  AS open
FROM support_tickets
GROUP BY agent
ORDER BY agent;
```

> `COUNT(CASE WHEN ... THEN 1 END)` counts only the rows matching the condition. `NULL`s are ignored by `COUNT`, so non-matching rows contribute 0.

Alternative using `FILTER`:

```sql
SELECT
    agent,
    COUNT(*)                                    AS total,
    COUNT(*) FILTER (WHERE status = 'Resolved') AS resolved,
    COUNT(*) FILTER (WHERE status = 'Open')     AS open
FROM support_tickets
GROUP BY agent
ORDER BY agent;
```

---

### Medium — Pivot by category and priority

```sql
SELECT
    agent,
    category,
    COUNT(CASE WHEN priority = 'High'   THEN 1 END) AS high,
    COUNT(CASE WHEN priority = 'Medium' THEN 1 END) AS medium,
    COUNT(CASE WHEN priority = 'Low'    THEN 1 END) AS low
FROM support_tickets
GROUP BY agent, category
ORDER BY agent, category;
```

---

## Pattern 9 — Deduplication

### Easy — Keep latest row per customer

```sql
SELECT DISTINCT ON (customer_id, email, phone)
    customer_id,
    name,
    email,
    phone,
    updated_at
FROM raw_customers
ORDER BY customer_id, email, phone, updated_at DESC;
```

Alternative using `ROW_NUMBER`:

```sql
SELECT customer_id, name, email, phone, updated_at
FROM (
    SELECT
        customer_id,
        name,
        email,
        phone,
        updated_at,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, email, phone
            ORDER BY updated_at DESC
        ) AS rn
    FROM raw_customers
) deduped
WHERE rn = 1
ORDER BY customer_id;
```

> `ROW_NUMBER()` assigns 1 to the latest row per group. Filtering `WHERE rn = 1` keeps only the most recent record.

---

### Medium — Flag duplicate rows

```sql
SELECT
    id,
    customer_id,
    name,
    updated_at,
    CASE
        WHEN ROW_NUMBER() OVER (
            PARTITION BY customer_id, email
            ORDER BY updated_at DESC, id DESC
        ) > 1 THEN TRUE
        ELSE FALSE
    END AS is_duplicate
FROM raw_customers
ORDER BY id;
```

> Rows with `ROW_NUMBER() = 1` (the latest per `customer_id + email`) are `FALSE` (not duplicates). All older or identical rows get `TRUE`.
> `id DESC` as a tiebreaker handles the exact-duplicate case (Dave, same `updated_at`) — the higher `id` is kept as the canonical record.
