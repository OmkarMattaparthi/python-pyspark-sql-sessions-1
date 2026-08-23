# Day 5 Problems — SQL DateTime: Functions, GROUP BY Time, generate_series, Epoch

> Use the `sales` schema created in `day5_practice.sql`.
> Tables: `customers`, `products`, `orders`, `order_items`, `events`.

---

## Section 1: Current Date and Extraction

**Q1.** Write a query that returns today's date, the current timestamp (with timezone), and the current time. Use `CURRENT_DATE`, `NOW()`, and `CURRENT_TIME`.

---

**Q2.** From the `orders` table, extract the `year`, `month`, `day`, `quarter`, and `day of week` from `order_date`. Show `order_id`, `order_date`, and all five extracted values.

---

**Q3.** From the `orders` table, find all orders placed on a **Monday**. Use `EXTRACT(DOW ...)` — Sunday = 0, Monday = 1.

---

**Q4.** From the `orders` table, find all orders placed in **Q1** (January–March) of any year. Use `EXTRACT(QUARTER ...)`.

---

## Section 2: DATE_TRUNC

**Q5.** Write a query that shows each order's `order_id`, `order_date`, and:
- `month_start` — the first day of the month the order was placed
- `quarter_start` — the first day of the quarter
- `year_start` — the first day of the year

Use `DATE_TRUNC`.

---

**Q6.** How many orders were placed per **month**? Show `order_month` (as `DATE`) and `order_count`. Sort by month ascending. Use `DATE_TRUNC`.

---

**Q7.** What is the total revenue per **quarter**? Show `quarter_start` and `total_revenue`. Include only delivered orders. Use `DATE_TRUNC` on `order_date` from the `orders` table joined to `order_items`.

---

## Section 3: TO_CHAR — Formatting

**Q8.** Format each order's `order_date` in three different ways:
- `fmt1` — `'DD-Mon-YYYY'` (e.g. `'05-Jan-2024'`)
- `fmt2` — `'Month YYYY'` (e.g. `'January  2024'`)
- `fmt3` — `'YYYY-"Q"Q'` (e.g. `'2024-Q1'`)

Show `order_id`, `order_date`, `fmt1`, `fmt2`, `fmt3`.

---

**Q9.** Write a query that returns total revenue per month, displayed with a **readable month label** like `'Jan-2024'`. Use `TO_CHAR` for the label and `DATE_TRUNC` for grouping. Sort by month ascending.

---

## Section 4: Date Arithmetic and Differences

**Q10.** For each customer, calculate how many **days** have passed since they signed up (use `CURRENT_DATE - signup_date`). Show `name`, `signup_date`, and `days_since_signup`. Sort by `days_since_signup` descending.

---

**Q11.** Write a query that returns orders placed in the **last 6 months** from today. Use `CURRENT_DATE - INTERVAL '6 months'` in the WHERE clause.

---

**Q12.** For each customer, use `AGE()` to show how long ago they signed up in a human-readable format (e.g. `'2 years 3 months 10 days'`). Show `name`, `signup_date`, `tenure`.

---

**Q13.** Find the **earliest** and **latest** order dates in the table. Then calculate the total number of days the data spans. Show `first_order`, `last_order`, `span_days`.

---

## Section 5: Casting and Parsing

**Q14.** Write a query that takes these string literals and casts them to the correct type using `::` or `TO_DATE`/`TO_TIMESTAMP`:
- `'2024-08-15'` → `DATE`
- `'15/08/2024'` → `DATE` using `TO_DATE`
- `'August 15 2024'` → `DATE` using `TO_DATE`
- `'2024-08-15 14:30:00'` → `TIMESTAMP`

Show all four as separate columns in a single SELECT.

---

**Q15.** The `events` table stores `occurred_at` as a `BIGINT` (epoch seconds). Write a query that converts it to a readable timestamp and extracts the date. Show `event_id`, `event_type`, `occurred_at`, `event_timestamp`, `event_date`.

---

## Section 6: GROUP BY with Time

**Q16.** Count the number of orders per **day of the week** across all orders. Show the weekday name (e.g. `'Monday'`) and `order_count`. Sort by day number (0=Sunday to 6=Saturday).

---

**Q17.** What is the total revenue per **year**? Show `order_year` and `total_revenue`. Use `EXTRACT(YEAR ...)`.

---

**Q18.** Write a query that returns the **busiest month** (most orders) for each year. Show `year`, `month`, `order_count`.

---

## Section 7: generate_series

**Q19.** Generate a list of every day from `'2024-01-01'` to `'2024-01-10'` using `generate_series`. Show each date as a single column `day`.

---

**Q20.** Generate every **month** of 2024 as a date spine. Then LEFT JOIN to `orders` so every month appears even if there were no orders that month. Show `month_start`, `order_count`, `revenue` (0 if no orders).

---

**Q21.** Generate every **quarter** from 2023 Q1 to 2024 Q4 using `generate_series`. Label each row `'YYYY-QN'` format using `TO_CHAR`. Show `quarter_label` and `quarter_start`.

---

**Q22.** Using `generate_series`, generate a sequence of timestamps for every **hour** on `'2024-01-15'` (00:00 to 23:00). Show each timestamp as a column `hour_slot`.

---

## Section 8: Epoch

**Q23.** Write a query that returns the current epoch (seconds since 1970-01-01). Also show `CURRENT_TIMESTAMP` alongside it so you can see both representations of "now".

---

**Q24.** Write a query that converts these epoch values back to timestamps using `TO_TIMESTAMP`:
- `0` → should be `1970-01-01 00:00:00`
- `86400` → should be `1970-01-02 00:00:00`
- `1704067200` → should be `2024-01-01 00:00:00`

---

**Q25.** From the `events` table, write a query that:
- Converts `occurred_at` (epoch) to a timestamp
- Groups events by **date** (not full timestamp)
- Shows `event_date`, `event_count`, and `first_event_time` (earliest timestamp that day)
Sort by `event_date`.

---

## Section 9: Combined Problems

**Q26.** Write a query using `generate_series` to create a **monthly revenue report for 2024**. Show:
- `month_label` (e.g. `'Jan-2024'`)
- `order_count`
- `total_revenue` (0 if no orders that month)
- `prev_month_revenue` — revenue of the previous month (use LAG or a self-join — use self-join for now)

---

**Q27.** Find all customers whose `signup_date` was more than **1 year before** their first order. Show `name`, `signup_date`, `first_order_date`, `gap_days`.

---

**Q28.** Write a query that identifies whether each order was placed on a **weekday** or **weekend**. Show `order_id`, `order_date`, `day_name`, and `day_type` (`'Weekday'` or `'Weekend'`). Use `EXTRACT(DOW ...)` and `CASE`.

---

## Section 10: NULL Behavior and Mistakes

**Q29.** This query is supposed to return monthly order counts for 2024, but it groups January 2023 and January 2024 together. Explain why and fix it:
```sql
SELECT EXTRACT(MONTH FROM order_date) AS month, COUNT(*) AS order_count
FROM sales.orders
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;
```

---

**Q30.** This query should return all orders from the last 30 days, but it never returns any rows even though recent orders exist. Find the bug:
```sql
SELECT * FROM sales.orders
WHERE order_date > CURRENT_DATE - '30';
```

---

## Bonus Challenges

**B1.** Build a complete **date-spine report** for 2024 showing every week (Monday to Sunday). For each week show:
- `week_start` (Monday)
- `week_end` (Sunday = week_start + 6 days)
- `order_count`
- `revenue`

Use `generate_series` with `'1 week'` step and LEFT JOIN to orders.

---

**B2.** Write a query that finds the **month-over-month revenue growth rate** for 2024:
- `month_label`
- `revenue`
- `prev_revenue`
- `growth_pct` — `ROUND(((revenue - prev_revenue) / prev_revenue) * 100, 2)` — show NULL for first month

Use `generate_series` for the date spine so months with 0 orders appear.

---

**B3.** The `events` table stores clickstream events with epoch timestamps. Write a query that:
- Converts epoch to timestamp
- Groups by **hour of day** (0–23) across all events
- Shows `hour`, `event_count`, and labels each hour as `'Peak'` (count > 5), `'Normal'` (count > 2), or `'Quiet'` otherwise
- Sort by hour
