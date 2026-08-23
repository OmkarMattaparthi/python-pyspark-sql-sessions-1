# Day 5 Notes — SQL DateTime: Functions, GROUP BY Time, generate_series, Epoch

## Topics Covered
1. Date and time data types in PostgreSQL
2. Getting the current date and time
3. Extracting parts of a date — EXTRACT, DATE_PART
4. Truncating dates — DATE_TRUNC
5. Formatting dates — TO_CHAR
6. Arithmetic on dates — adding/subtracting intervals
7. Calculating differences between dates — AGE, date subtraction
8. Casting and converting date strings
9. GROUP BY with time — grouping by month, quarter, year, week
10. generate_series — generating date/time sequences
11. Epoch — storing and converting Unix timestamps
12. Common mistakes and NULL behavior with dates

---

## 1. Date and Time Data Types

PostgreSQL has several date/time types:

| Type | What it stores | Example |
|------|---------------|---------|
| `DATE` | Calendar date only | `'2024-03-15'` |
| `TIME` | Time of day only (no timezone) | `'14:30:00'` |
| `TIMESTAMP` | Date + time (no timezone) | `'2024-03-15 14:30:00'` |
| `TIMESTAMPTZ` | Date + time with timezone | `'2024-03-15 14:30:00+05:30'` |
| `INTERVAL` | A span of time | `'3 months'`, `'7 days'` |

```sql
-- Literal values — always wrap in single quotes
SELECT '2024-03-15'::DATE;
SELECT '14:30:00'::TIME;
SELECT '2024-03-15 14:30:00'::TIMESTAMP;
SELECT '3 months 10 days'::INTERVAL;
```

---

## 2. Getting the Current Date and Time

```sql
SELECT CURRENT_DATE;           -- today's date (DATE)
SELECT CURRENT_TIME;           -- current time with timezone (TIMETZ)
SELECT CURRENT_TIMESTAMP;      -- date + time with timezone (TIMESTAMPTZ)
SELECT NOW();                  -- same as CURRENT_TIMESTAMP
SELECT LOCALTIME;              -- time without timezone
SELECT LOCALTIMESTAMP;         -- date + time without timezone
```

> `NOW()` and `CURRENT_TIMESTAMP` are equivalent — both return the start time of the current transaction.

---

## 3. Extracting Parts — EXTRACT and DATE_PART

`EXTRACT` and `DATE_PART` do the same thing. `EXTRACT` is the SQL standard.

```sql
-- Syntax: EXTRACT(field FROM source)
SELECT EXTRACT(YEAR    FROM '2024-03-15'::DATE);  -- 2024
SELECT EXTRACT(MONTH   FROM '2024-03-15'::DATE);  -- 3
SELECT EXTRACT(DAY     FROM '2024-03-15'::DATE);  -- 15
SELECT EXTRACT(QUARTER FROM '2024-03-15'::DATE);  -- 1
SELECT EXTRACT(WEEK    FROM '2024-03-15'::DATE);  -- 11  (ISO week number)
SELECT EXTRACT(DOW     FROM '2024-03-15'::DATE);  -- 5   (0=Sunday … 6=Saturday)
SELECT EXTRACT(DOY     FROM '2024-03-15'::DATE);  -- 75  (day of year)
SELECT EXTRACT(HOUR    FROM '14:30:45'::TIME);    -- 14
SELECT EXTRACT(MINUTE  FROM '14:30:45'::TIME);    -- 30
SELECT EXTRACT(SECOND  FROM '14:30:45'::TIME);    -- 45

-- DATE_PART — identical result, older syntax
SELECT DATE_PART('month', '2024-03-15'::DATE);    -- 3
SELECT DATE_PART('hour',  NOW());                 -- current hour
```

### Fields summary

| Field | Returns |
|-------|---------|
| `YEAR` | Full 4-digit year |
| `MONTH` | 1–12 |
| `DAY` | 1–31 |
| `QUARTER` | 1–4 |
| `WEEK` | ISO week 1–53 |
| `DOW` | Day of week 0 (Sun) – 6 (Sat) |
| `DOY` | Day of year 1–366 |
| `HOUR` | 0–23 |
| `MINUTE` | 0–59 |
| `SECOND` | 0–59 (with fractional for timestamps) |
| `EPOCH` | Seconds since 1970-01-01 00:00:00 UTC |

---

## 4. Truncating Dates — DATE_TRUNC

`DATE_TRUNC` rounds a date/timestamp DOWN to the start of a given unit.
This is the most important function for time-based GROUP BY.

```sql
-- Syntax: DATE_TRUNC('unit', value)

SELECT DATE_TRUNC('year',    '2024-08-15'::DATE);  -- 2024-01-01
SELECT DATE_TRUNC('quarter', '2024-08-15'::DATE);  -- 2024-07-01
SELECT DATE_TRUNC('month',   '2024-08-15'::DATE);  -- 2024-08-01
SELECT DATE_TRUNC('week',    '2024-08-15'::DATE);  -- 2024-08-12 (Monday)
SELECT DATE_TRUNC('day',     '2024-08-15 14:35:22'::TIMESTAMP);  -- 2024-08-15 00:00:00
SELECT DATE_TRUNC('hour',    '2024-08-15 14:35:22'::TIMESTAMP);  -- 2024-08-15 14:00:00
```

> Use `DATE_TRUNC` in GROUP BY when you want to group by month/week/quarter
> without writing three separate EXTRACT calls.

---

## 5. Formatting Dates — TO_CHAR

`TO_CHAR` converts a date or timestamp to a formatted string.
Useful for display, reports, and readable labels.

```sql
-- Syntax: TO_CHAR(value, 'format')

SELECT TO_CHAR('2024-08-15'::DATE, 'DD-MM-YYYY');      -- '15-08-2024'
SELECT TO_CHAR('2024-08-15'::DATE, 'Month YYYY');       -- 'August    2024'
SELECT TO_CHAR('2024-08-15'::DATE, 'Mon-YY');           -- 'Aug-24'
SELECT TO_CHAR('2024-08-15'::DATE, 'YYYY-"Q"Q');        -- '2024-Q3'
SELECT TO_CHAR('2024-08-15'::DATE, 'Day, DD Month YYYY');-- 'Thursday , 15 August   2024'
SELECT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS');         -- '2024-08-15 14:30:22'
```

### Common format codes

| Code | Meaning | Example |
|------|---------|---------|
| `YYYY` | 4-digit year | `2024` |
| `YY` | 2-digit year | `24` |
| `MM` | Month number 01–12 | `08` |
| `Mon` | Abbreviated month | `Aug` |
| `Month` | Full month name | `August` |
| `DD` | Day 01–31 | `15` |
| `Day` | Full day name | `Thursday` |
| `HH24` | Hour 00–23 | `14` |
| `MI` | Minutes 00–59 | `30` |
| `SS` | Seconds 00–59 | `22` |
| `Q` | Quarter 1–4 | `3` |
| `IW` | ISO week number | `33` |

---

## 6. Date Arithmetic — Adding and Subtracting

```sql
-- Add/subtract INTERVALs
SELECT '2024-01-15'::DATE + INTERVAL '3 months';    -- 2024-04-15
SELECT '2024-01-15'::DATE + INTERVAL '10 days';     -- 2024-01-25
SELECT '2024-01-15'::DATE - INTERVAL '1 year';      -- 2023-01-15
SELECT NOW()              + INTERVAL '2 hours';     -- 2 hours from now
SELECT NOW()              - INTERVAL '30 minutes';  -- 30 minutes ago

-- Shorthand: add integer days directly to a DATE
SELECT '2024-01-15'::DATE + 10;   -- 2024-01-25  (adds 10 days)
SELECT '2024-01-15'::DATE - 5;    -- 2024-01-10  (subtracts 5 days)

-- Interval components
SELECT INTERVAL '1 year 2 months 15 days 3 hours';
```

---

## 7. Calculating Differences Between Dates

```sql
-- Subtract two DATEs → returns integer (number of days)
SELECT '2024-08-15'::DATE - '2024-01-01'::DATE;   -- 227 (days)

-- AGE function → returns a human-readable INTERVAL
SELECT AGE('2024-08-15'::DATE, '2000-03-10'::DATE);
-- Result: 24 years 5 months 5 days

SELECT AGE(NOW(), '1990-06-15'::DATE);             -- age from a birth date to now

-- Difference in specific units
SELECT EXTRACT(DAY FROM AGE('2024-08-15', '2024-01-01'));          -- 14 (days component)
SELECT EXTRACT(EPOCH FROM AGE('2024-08-15', '2024-01-01')) / 86400 -- 227.0 (total days as decimal)
                                                                    -- 86400 = seconds in a day
```

---

## 8. Casting and Converting Date Strings

```sql
-- Cast string to date using ::
SELECT '2024-08-15'::DATE;
SELECT '2024-08-15 14:30:00'::TIMESTAMP;

-- Cast using CAST()
SELECT CAST('2024-08-15' AS DATE);

-- Parse a non-standard format using TO_DATE / TO_TIMESTAMP
SELECT TO_DATE('15-08-2024', 'DD-MM-YYYY');
SELECT TO_DATE('August 15, 2024', 'Month DD, YYYY');
SELECT TO_TIMESTAMP('15-08-2024 14:30:00', 'DD-MM-YYYY HH24:MI:SS');
```

---

## 9. GROUP BY with Time

The key pattern: use `DATE_TRUNC` or `EXTRACT` in both SELECT and GROUP BY.

```sql
-- Group sales by month
SELECT
    DATE_TRUNC('month', order_date)     AS order_month,
    COUNT(*)                            AS total_orders,
    SUM(amount)                         AS total_revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;

-- Group by year
SELECT
    EXTRACT(YEAR FROM order_date)       AS order_year,
    COUNT(*)                            AS total_orders
FROM orders
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY order_year;

-- Group by quarter with a readable label
SELECT
    TO_CHAR(order_date, 'YYYY-"Q"Q')   AS quarter,
    SUM(amount)                         AS revenue
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-"Q"Q')
ORDER BY quarter;

-- Group by day of week (find busiest day)
SELECT
    TO_CHAR(order_date, 'Day')          AS weekday,
    EXTRACT(DOW FROM order_date)        AS dow_num,
    COUNT(*)                            AS order_count
FROM orders
GROUP BY TO_CHAR(order_date, 'Day'), EXTRACT(DOW FROM order_date)
ORDER BY dow_num;
```

---

## 10. generate_series — Generating Date Sequences

`generate_series` produces a set of rows between a start and end value with a given step.
Critical for creating date spines — a complete list of dates/months even when there are no events on some dates.

```sql
-- Syntax: generate_series(start, stop, step)

-- Generate every day in January 2024
SELECT generate_series(
    '2024-01-01'::DATE,
    '2024-01-07'::DATE,
    '1 day'::INTERVAL
) AS day;

-- Generate every month in 2024
SELECT generate_series(
    '2024-01-01'::DATE,
    '2024-12-01'::DATE,
    '1 month'::INTERVAL
)::DATE AS month_start;

-- Generate every quarter in 2024–2025
SELECT generate_series(
    '2024-01-01'::DATE,
    '2025-12-01'::DATE,
    '3 months'::INTERVAL
)::DATE AS quarter_start;
```

### Why generate_series matters — filling gaps in reports

Without a date spine, months with no orders simply disappear from your result.
With a date spine you LEFT JOIN events onto the full calendar, so every month appears.

```sql
-- Date spine: every month of 2024
-- LEFT JOIN to orders so months with 0 orders still appear
SELECT
    gs.month_start,
    COUNT(o.order_id)   AS order_count,
    COALESCE(SUM(o.amount), 0) AS revenue
FROM generate_series(
    '2024-01-01'::DATE,
    '2024-12-01'::DATE,
    '1 month'::INTERVAL
) AS gs(month_start)
LEFT JOIN orders o
    ON DATE_TRUNC('month', o.order_date) = gs.month_start
GROUP BY gs.month_start
ORDER BY gs.month_start;
```

---

## 11. Epoch — Unix Timestamps

**Epoch** (Unix time) = number of seconds elapsed since `1970-01-01 00:00:00 UTC`.
Used heavily in logs, APIs, event systems, and big-data pipelines.

```sql
-- Get epoch value of a timestamp
SELECT EXTRACT(EPOCH FROM NOW());                         -- e.g. 1723718422.123456
SELECT EXTRACT(EPOCH FROM '2024-08-15 00:00:00'::TIMESTAMP); -- 1723680000

-- Convert epoch (seconds) back to timestamp
SELECT TO_TIMESTAMP(1723680000);                          -- 2024-08-15 00:00:00+00

-- Store epoch as BIGINT (common in data pipelines)
SELECT EXTRACT(EPOCH FROM NOW())::BIGINT;                 -- integer seconds

-- Difference in seconds between two timestamps
SELECT EXTRACT(EPOCH FROM (NOW() - '2024-01-01'::TIMESTAMP));

-- Difference in days using epoch
SELECT EXTRACT(EPOCH FROM ('2024-08-15'::TIMESTAMP - '2024-01-01'::TIMESTAMP)) / 86400;
-- 86400 = 60 seconds × 60 minutes × 24 hours
```

### Epoch use in data engineering

```sql
-- Event log table using epoch
CREATE TABLE events (
    event_id    SERIAL PRIMARY KEY,
    event_type  VARCHAR(50),
    occurred_at BIGINT    -- epoch seconds from source system
);

-- Query: convert epoch to readable timestamp at query time
SELECT
    event_type,
    TO_TIMESTAMP(occurred_at)                          AS event_time,
    TO_CHAR(TO_TIMESTAMP(occurred_at), 'YYYY-MM-DD')  AS event_date
FROM events;
```

---

## 12. Common Mistakes and NULL Behavior

### Mistake 1 — Comparing dates as strings

```sql
-- WRONG: string comparison — '2024-09-01' > '2024-10-01' is FALSE because '0' < '1' lexically
WHERE order_date > '2024-10-01'   -- works only if the column IS a DATE type

-- RIGHT: cast explicitly if column type is uncertain
WHERE order_date > '2024-10-01'::DATE
```

### Mistake 2 — GROUP BY EXTRACT vs DATE_TRUNC

```sql
-- WRONG: grouping by month number loses the year distinction
-- January 2023 and January 2024 both show as month = 1
GROUP BY EXTRACT(MONTH FROM order_date)

-- RIGHT: include year too, or use DATE_TRUNC which keeps both
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
-- OR
GROUP BY DATE_TRUNC('month', order_date)   -- preferred
```

### Mistake 3 — DATE_TRUNC on DATE vs TIMESTAMP

```sql
-- DATE_TRUNC returns a TIMESTAMP even when input is DATE
SELECT DATE_TRUNC('month', '2024-08-15'::DATE);
-- Returns: 2024-08-01 00:00:00  (TIMESTAMP)
-- Cast back to DATE if needed:
SELECT DATE_TRUNC('month', '2024-08-15'::DATE)::DATE;  -- 2024-08-01
```

### Mistake 4 — NULL dates in calculations

```sql
-- Any arithmetic with NULL returns NULL
SELECT NULL::DATE + INTERVAL '1 day';   -- NULL

-- NULL dates pass through EXTRACT as NULL
SELECT EXTRACT(YEAR FROM NULL::DATE);   -- NULL

-- Use COALESCE or IS NOT NULL filter
WHERE hire_date IS NOT NULL
```

### Mistake 5 — generate_series gaps not appearing without LEFT JOIN

```sql
-- WRONG: joining generate_series with INNER JOIN hides empty months
SELECT gs.month, COUNT(o.order_id)
FROM orders o
JOIN generate_series(...) gs ON ...
-- Months with no orders vanish

-- RIGHT: generate_series on the LEFT, orders on the RIGHT
SELECT gs.month, COUNT(o.order_id)
FROM generate_series(...) gs
LEFT JOIN orders o ON ...
```

---

## DateTime Function Quick Reference

| Function | Purpose | Example result |
|----------|---------|---------------|
| `CURRENT_DATE` | Today's date | `2024-08-15` |
| `NOW()` | Current timestamp with TZ | `2024-08-15 14:30:22+05:30` |
| `EXTRACT(field FROM val)` | Get one part of date | `EXTRACT(MONTH FROM d)` → `8` |
| `DATE_PART('field', val)` | Same as EXTRACT | `DATE_PART('year', d)` → `2024` |
| `DATE_TRUNC('unit', val)` | Truncate to unit start | `DATE_TRUNC('month', d)` → `2024-08-01` |
| `TO_CHAR(val, fmt)` | Format as string | `TO_CHAR(d, 'Mon-YY')` → `'Aug-24'` |
| `TO_DATE(str, fmt)` | Parse string to DATE | `TO_DATE('15-08-2024', 'DD-MM-YYYY')` |
| `TO_TIMESTAMP(epoch)` | Epoch → timestamp | `TO_TIMESTAMP(1723680000)` |
| `AGE(end, start)` | Human-readable interval | `24 years 5 months` |
| `INTERVAL '...'` | Time span literal | `INTERVAL '3 months 10 days'` |
| `EXTRACT(EPOCH FROM val)` | Timestamp → epoch seconds | `1723680000` |
| `generate_series(s, e, step)` | Sequence of dates | every month in a range |

---

## DE Relevance Summary

| Concept | Data Engineering Use |
|---------|---------------------|
| `DATE_TRUNC` | Partitioning event data by month/day in warehouse loads |
| `EXTRACT(EPOCH ...)` | Converting source-system timestamps to epoch for Kafka/Spark |
| `TO_TIMESTAMP(epoch)` | Reading epoch columns from logs, click-streams, API payloads |
| `generate_series` | Building date spines for gap-free time-series reports |
| `AGE / date subtraction` | SLA calculations, TTL detection, late-arrival detection |
| `GROUP BY DATE_TRUNC` | Monthly/quarterly aggregation in fact table queries |
| `TO_CHAR` | Formatting partition keys (e.g. `YYYY/MM/DD` folder paths in S3) |
| `INTERVAL arithmetic` | Rolling windows — last 30 days, last 7 days, look-back periods |
| `TIMESTAMPTZ vs TIMESTAMP` | Handling multi-timezone ingestion correctly |
