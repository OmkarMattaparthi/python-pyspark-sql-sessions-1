# SQL Pattern Problems — PostgreSQL

Each pattern has:
- Setup: `CREATE TABLE` + `INSERT` statements
- Easy problem with sample input & expected output
- Medium problem with sample input & expected output

---

## Pattern 1 — Top N per Group

### Setup

```sql
CREATE TABLE sales (
    sale_id    SERIAL PRIMARY KEY,
    rep_name   VARCHAR(50),
    region     VARCHAR(50),
    amount     NUMERIC(10,2),
    sale_date  DATE
);

INSERT INTO sales (rep_name, region, amount, sale_date) VALUES
('Alice',   'North', 9500.00,  '2024-01-10'),
('Bob',     'North', 8200.00,  '2024-01-15'),
('Carol',   'North', 7800.00,  '2024-01-20'),
('Dave',    'North', 6100.00,  '2024-01-25'),
('Eve',     'South', 11200.00, '2024-01-11'),
('Frank',   'South', 9800.00,  '2024-01-16'),
('Grace',   'South', 8700.00,  '2024-01-21'),
('Hank',    'South', 7400.00,  '2024-01-26'),
('Ivy',     'East',  10500.00, '2024-01-12'),
('Jack',    'East',  9300.00,  '2024-01-17'),
('Karen',   'East',  8100.00,  '2024-01-22');
```

### Easy — Top 1 rep per region (highest sale)

**Question:** Find the top-earning sales rep in each region.

**Expected Output:**

| region | rep_name | amount   |
|--------|----------|----------|
| East   | Ivy      | 10500.00 |
| North  | Alice    | 9500.00  |
| South  | Eve      | 11200.00 |

---

### Medium — Top 2 reps per region

**Question:** Find the top 2 sales reps by amount in each region. If there is a tie, include both.

**Expected Output:**

| region | rank | rep_name | amount   |
|--------|------|----------|----------|
| East   | 1    | Ivy      | 10500.00 |
| East   | 2    | Jack     | 9300.00  |
| North  | 1    | Alice    | 9500.00  |
| North  | 2    | Bob      | 8200.00  |
| South  | 1    | Eve      | 11200.00 |
| South  | 2    | Frank    | 9800.00  |

---

## Pattern 2 — Gaps and Islands

### Setup

```sql
CREATE TABLE user_logins (
    login_id   SERIAL PRIMARY KEY,
    user_id    INT,
    login_date DATE
);

INSERT INTO user_logins (user_id, login_date) VALUES
(1, '2024-01-01'),
(1, '2024-01-02'),
(1, '2024-01-03'),
(1, '2024-01-07'),
(1, '2024-01-08'),
(1, '2024-01-15'),
(2, '2024-01-01'),
(2, '2024-01-04'),
(2, '2024-01-05'),
(2, '2024-01-06');
```

### Easy — Find gaps (missing dates) for a user

**Question:** For `user_id = 1`, find all dates between `2024-01-01` and `2024-01-10` where the user did NOT log in.

**Expected Output:**

| missing_date |
|--------------|
| 2024-01-04   |
| 2024-01-05   |
| 2024-01-06   |
| 2024-01-09   |
| 2024-01-10   |

---

### Medium — Find continuous login streaks (islands) per user

**Question:** For each user, identify each consecutive login streak — its start date, end date, and length in days.

**Expected Output:**

| user_id | streak_start | streak_end | streak_days |
|---------|--------------|------------|-------------|
| 1       | 2024-01-01   | 2024-01-03 | 3           |
| 1       | 2024-01-07   | 2024-01-08 | 2           |
| 1       | 2024-01-15   | 2024-01-15 | 1           |
| 2       | 2024-01-01   | 2024-01-01 | 1           |
| 2       | 2024-01-04   | 2024-01-06 | 3           |

---

## Pattern 3 — Running Total

### Setup

```sql
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT,
    order_date  DATE,
    amount      NUMERIC(10,2)
);

INSERT INTO orders (customer_id, order_date, amount) VALUES
(1, '2024-01-05', 250.00),
(1, '2024-01-12', 180.00),
(1, '2024-01-20', 320.00),
(1, '2024-02-03', 150.00),
(2, '2024-01-08', 400.00),
(2, '2024-01-22', 275.00),
(2, '2024-02-10', 190.00),
(3, '2024-01-15', 500.00),
(3, '2024-01-30', 225.00);
```

### Easy — Running total across all orders (global, ordered by date)

**Question:** Show each order with a running total of `amount` across all orders ordered by `order_date`.

**Expected Output:**

| order_id | order_date | amount | running_total |
|----------|------------|--------|---------------|
| 1        | 2024-01-05 | 250.00 | 250.00        |
| 5        | 2024-01-08 | 400.00 | 650.00        |
| 2        | 2024-01-12 | 180.00 | 830.00        |
| 8        | 2024-01-15 | 500.00 | 1330.00       |
| 3        | 2024-01-20 | 320.00 | 1650.00       |
| 6        | 2024-01-22 | 275.00 | 1925.00       |
| 9        | 2024-01-30 | 225.00 | 2150.00       |
| 4        | 2024-02-03 | 150.00 | 2300.00       |
| 7        | 2024-02-10 | 190.00 | 2490.00       |

---

### Medium — Running total per customer, reset for each customer

**Question:** Show each order with a running total of `amount` partitioned by `customer_id`, ordered by `order_date`.

**Expected Output:**

| customer_id | order_id | order_date | amount | running_total |
|-------------|----------|------------|--------|---------------|
| 1           | 1        | 2024-01-05 | 250.00 | 250.00        |
| 1           | 2        | 2024-01-12 | 180.00 | 430.00        |
| 1           | 3        | 2024-01-20 | 320.00 | 750.00        |
| 1           | 4        | 2024-02-03 | 150.00 | 900.00        |
| 2           | 5        | 2024-01-08 | 400.00 | 400.00        |
| 2           | 6        | 2024-01-22 | 275.00 | 675.00        |
| 2           | 7        | 2024-02-10 | 190.00 | 865.00        |
| 3           | 8        | 2024-01-15 | 500.00 | 500.00        |
| 3           | 9        | 2024-01-30 | 225.00 | 725.00        |

---

## Pattern 4 — Moving Average

### Setup

```sql
CREATE TABLE stock_prices (
    price_id    SERIAL PRIMARY KEY,
    stock       VARCHAR(10),
    price_date  DATE,
    close_price NUMERIC(10,2)
);

INSERT INTO stock_prices (stock, price_date, close_price) VALUES
('AAPL', '2024-01-01', 185.20),
('AAPL', '2024-01-02', 187.50),
('AAPL', '2024-01-03', 183.80),
('AAPL', '2024-01-04', 189.00),
('AAPL', '2024-01-05', 192.30),
('AAPL', '2024-01-08', 190.10),
('AAPL', '2024-01-09', 194.50),
('MSFT', '2024-01-01', 375.00),
('MSFT', '2024-01-02', 378.20),
('MSFT', '2024-01-03', 372.50),
('MSFT', '2024-01-04', 380.00),
('MSFT', '2024-01-05', 383.70);
```

### Easy — 3-day moving average for one stock

**Question:** Calculate the 3-day moving average of `close_price` for `AAPL` ordered by `price_date`.

**Expected Output:**

| price_date | close_price | moving_avg_3 |
|------------|-------------|--------------|
| 2024-01-01 | 185.20      | 185.20       |
| 2024-01-02 | 187.50      | 186.35       |
| 2024-01-03 | 183.80      | 185.50       |
| 2024-01-04 | 189.00      | 186.77       |
| 2024-01-05 | 192.30      | 188.37       |
| 2024-01-08 | 190.10      | 190.47       |
| 2024-01-09 | 194.50      | 192.30       |

> Use `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` for a 3-row window.

---

### Medium — 3-day moving average per stock (partitioned)

**Question:** Calculate the 3-day moving average of `close_price` for each stock separately, ordered by `price_date`.

**Expected Output:**

| stock | price_date | close_price | moving_avg_3 |
|-------|------------|-------------|--------------|
| AAPL  | 2024-01-01 | 185.20      | 185.20       |
| AAPL  | 2024-01-02 | 187.50      | 186.35       |
| AAPL  | 2024-01-03 | 183.80      | 185.50       |
| AAPL  | 2024-01-04 | 189.00      | 186.77       |
| AAPL  | 2024-01-05 | 192.30      | 188.37       |
| AAPL  | 2024-01-08 | 190.10      | 190.47       |
| AAPL  | 2024-01-09 | 194.50      | 192.30       |
| MSFT  | 2024-01-01 | 375.00      | 375.00       |
| MSFT  | 2024-01-02 | 378.20      | 376.60       |
| MSFT  | 2024-01-03 | 372.50      | 375.23       |
| MSFT  | 2024-01-04 | 380.00      | 376.90       |
| MSFT  | 2024-01-05 | 383.70      | 378.73       |

---

## Pattern 5 — First and Last Event

### Setup

```sql
CREATE TABLE pipeline_runs (
    run_id      SERIAL PRIMARY KEY,
    pipeline    VARCHAR(50),
    status      VARCHAR(20),
    run_at      TIMESTAMP
);

INSERT INTO pipeline_runs (pipeline, status, run_at) VALUES
('etl_orders',    'SUCCESS', '2024-01-10 08:00:00'),
('etl_orders',    'FAILED',  '2024-01-11 08:05:00'),
('etl_orders',    'SUCCESS', '2024-01-12 08:10:00'),
('etl_orders',    'SUCCESS', '2024-01-13 08:00:00'),
('etl_customers', 'SUCCESS', '2024-01-10 09:00:00'),
('etl_customers', 'SUCCESS', '2024-01-11 09:05:00'),
('etl_customers', 'FAILED',  '2024-01-12 09:10:00'),
('etl_products',  'FAILED',  '2024-01-10 10:00:00'),
('etl_products',  'FAILED',  '2024-01-11 10:05:00'),
('etl_products',  'SUCCESS', '2024-01-12 10:10:00');
```

### Easy — First run timestamp per pipeline

**Question:** Find the very first run time for each pipeline.

**Expected Output:**

| pipeline       | first_run           |
|----------------|---------------------|
| etl_customers  | 2024-01-10 09:00:00 |
| etl_orders     | 2024-01-10 08:00:00 |
| etl_products   | 2024-01-10 10:00:00 |

---

### Medium — First and last run, plus last run status per pipeline

**Question:** For each pipeline, show the first run time, last run time, and the status of the most recent run.

**Expected Output:**

| pipeline       | first_run           | last_run            | last_status |
|----------------|---------------------|---------------------|-------------|
| etl_customers  | 2024-01-10 09:00:00 | 2024-01-12 09:10:00 | FAILED      |
| etl_orders     | 2024-01-10 08:00:00 | 2024-01-13 08:00:00 | SUCCESS     |
| etl_products   | 2024-01-10 10:00:00 | 2024-01-12 10:10:00 | SUCCESS     |

---

## Pattern 6 — Previous and Next Record Comparison

### Setup

```sql
CREATE TABLE monthly_revenue (
    rev_id    SERIAL PRIMARY KEY,
    dept      VARCHAR(50),
    month     DATE,
    revenue   NUMERIC(12,2)
);

INSERT INTO monthly_revenue (dept, month, revenue) VALUES
('Engineering', '2024-01-01', 120000.00),
('Engineering', '2024-02-01', 135000.00),
('Engineering', '2024-03-01', 128000.00),
('Engineering', '2024-04-01', 142000.00),
('Sales',       '2024-01-01', 95000.00),
('Sales',       '2024-02-01', 88000.00),
('Sales',       '2024-03-01', 102000.00),
('Sales',       '2024-04-01', 97000.00);
```

### Easy — Show previous month revenue alongside current

**Question:** For each row, show the current month's revenue and the previous month's revenue for the same department.

**Expected Output:**

| dept        | month      | revenue   | prev_revenue |
|-------------|------------|-----------|--------------|
| Engineering | 2024-01-01 | 120000.00 | NULL         |
| Engineering | 2024-02-01 | 135000.00 | 120000.00    |
| Engineering | 2024-03-01 | 128000.00 | 135000.00    |
| Engineering | 2024-04-01 | 142000.00 | 128000.00    |
| Sales       | 2024-01-01 | 95000.00  | NULL         |
| Sales       | 2024-02-01 | 88000.00  | 95000.00     |
| Sales       | 2024-03-01 | 102000.00 | 88000.00     |
| Sales       | 2024-04-01 | 97000.00  | 102000.00    |

---

### Medium — Month-over-month revenue change and trend

**Question:** For each department and month, show the revenue, previous month revenue, the absolute change, and whether it is an `Increase`, `Decrease`, or `No Change`.

**Expected Output:**

| dept        | month      | revenue   | prev_revenue | change    | trend    |
|-------------|------------|-----------|--------------|-----------|----------|
| Engineering | 2024-01-01 | 120000.00 | NULL         | NULL      | NULL     |
| Engineering | 2024-02-01 | 135000.00 | 120000.00    | 15000.00  | Increase |
| Engineering | 2024-03-01 | 128000.00 | 135000.00    | -7000.00  | Decrease |
| Engineering | 2024-04-01 | 142000.00 | 128000.00    | 14000.00  | Increase |
| Sales       | 2024-01-01 | 95000.00  | NULL         | NULL      | NULL     |
| Sales       | 2024-02-01 | 88000.00  | 95000.00     | -7000.00  | Decrease |
| Sales       | 2024-03-01 | 102000.00 | 88000.00     | 14000.00  | Increase |
| Sales       | 2024-04-01 | 97000.00  | 102000.00    | -5000.00  | Decrease |

---

## Pattern 7 — Sessionization

### Setup

```sql
CREATE TABLE page_events (
    event_id   SERIAL PRIMARY KEY,
    user_id    INT,
    page       VARCHAR(100),
    event_time TIMESTAMP
);

INSERT INTO page_events (user_id, page, event_time) VALUES
(1, '/home',     '2024-01-15 10:00:00'),
(1, '/products', '2024-01-15 10:03:00'),
(1, '/cart',     '2024-01-15 10:05:00'),
(1, '/home',     '2024-01-15 10:45:00'),  -- new session: >30 min gap
(1, '/checkout', '2024-01-15 10:47:00'),
(2, '/home',     '2024-01-15 11:00:00'),
(2, '/about',    '2024-01-15 11:02:00'),
(2, '/home',     '2024-01-15 12:05:00'),  -- new session: >30 min gap
(2, '/products', '2024-01-15 12:08:00');
```

> A new session starts when the gap from the previous event for the same user exceeds 30 minutes.

### Easy — Flag where a new session starts

**Question:** For each event, flag whether it is the start of a new session (`1`) or a continuation (`0`). Assume a session boundary = gap > 30 minutes from the previous event for the same user.

**Expected Output:**

| user_id | event_time          | page       | is_new_session |
|---------|---------------------|------------|----------------|
| 1       | 2024-01-15 10:00:00 | /home      | 1              |
| 1       | 2024-01-15 10:03:00 | /products  | 0              |
| 1       | 2024-01-15 10:05:00 | /cart      | 0              |
| 1       | 2024-01-15 10:45:00 | /home      | 1              |
| 1       | 2024-01-15 10:47:00 | /checkout  | 0              |
| 2       | 2024-01-15 11:00:00 | /home      | 1              |
| 2       | 2024-01-15 11:02:00 | /about     | 0              |
| 2       | 2024-01-15 12:05:00 | /home      | 1              |
| 2       | 2024-01-15 12:08:00 | /products  | 0              |

---

### Medium — Assign session IDs and summarize each session

**Question:** Assign a unique session ID to each session per user and produce a session summary: session start time, end time, page count, and pages visited (as a comma-separated list).

**Expected Output:**

| user_id | session_id | session_start       | session_end         | page_count | pages                         |
|---------|------------|---------------------|---------------------|------------|-------------------------------|
| 1       | 1          | 2024-01-15 10:00:00 | 2024-01-15 10:05:00 | 3          | /home,/products,/cart         |
| 1       | 2          | 2024-01-15 10:45:00 | 2024-01-15 10:47:00 | 2          | /home,/checkout               |
| 2       | 1          | 2024-01-15 11:00:00 | 2024-01-15 11:02:00 | 2          | /home,/about                  |
| 2       | 2          | 2024-01-15 12:05:00 | 2024-01-15 12:08:00 | 2          | /home,/products               |

> Hint: use `SUM(is_new_session) OVER (PARTITION BY user_id ORDER BY event_time)` to build session IDs after flagging.

---

## Pattern 8 — Conditional Aggregation

### Setup

```sql
CREATE TABLE support_tickets (
    ticket_id   SERIAL PRIMARY KEY,
    agent       VARCHAR(50),
    category    VARCHAR(50),
    status      VARCHAR(20),
    priority    VARCHAR(10),
    created_at  DATE
);

INSERT INTO support_tickets (agent, category, status, priority, created_at) VALUES
('Alice', 'Billing',   'Resolved', 'High',   '2024-01-05'),
('Alice', 'Technical', 'Open',     'Low',    '2024-01-06'),
('Alice', 'Billing',   'Resolved', 'Medium', '2024-01-07'),
('Alice', 'Technical', 'Resolved', 'High',   '2024-01-08'),
('Bob',   'Billing',   'Open',     'High',   '2024-01-05'),
('Bob',   'Technical', 'Resolved', 'Medium', '2024-01-06'),
('Bob',   'Billing',   'Resolved', 'Low',    '2024-01-07'),
('Bob',   'Technical', 'Open',     'High',   '2024-01-08'),
('Carol', 'Billing',   'Resolved', 'Low',    '2024-01-05'),
('Carol', 'Technical', 'Resolved', 'Medium', '2024-01-06'),
('Carol', 'Billing',   'Open',     'High',   '2024-01-07'),
('Carol', 'Technical', 'Resolved', 'High',   '2024-01-08');
```

### Easy — Count resolved vs open tickets per agent

**Question:** For each agent show total tickets, how many are `Resolved`, and how many are `Open` — all in one row.

**Expected Output:**

| agent | total | resolved | open |
|-------|-------|----------|------|
| Alice | 4     | 3        | 1    |
| Bob   | 4     | 2        | 2    |
| Carol | 4     | 3        | 1    |

---

### Medium — Pivot: ticket counts by category and priority per agent

**Question:** For each agent, show how many `High`, `Medium`, and `Low` priority tickets exist in each category — pivoted into columns.

**Expected Output:**

| agent | category  | high | medium | low |
|-------|-----------|------|--------|-----|
| Alice | Billing   | 1    | 1      | 0   |
| Alice | Technical | 1    | 0      | 1   |
| Bob   | Billing   | 1    | 0      | 1   |
| Bob   | Technical | 1    | 1      | 0   |
| Carol | Billing   | 1    | 0      | 1   |
| Carol | Technical | 1    | 1      | 0   |

> Use `COUNT(CASE WHEN priority = 'High' THEN 1 END)` pattern.

---

## Pattern 9 — Deduplication

### Setup

```sql
CREATE TABLE raw_customers (
    id          SERIAL PRIMARY KEY,
    customer_id INT,
    name        VARCHAR(100),
    email       VARCHAR(100),
    phone       VARCHAR(20),
    updated_at  TIMESTAMP
);

INSERT INTO raw_customers (customer_id, name, email, phone, updated_at) VALUES
(101, 'Alice Smith',  'alice@email.com', '9876543210', '2024-01-10 08:00:00'),
(101, 'Alice Smith',  'alice@email.com', '9876543210', '2024-01-15 10:00:00'),  -- duplicate, newer
(102, 'Bob Jones',   'bob@email.com',   '8765432109', '2024-01-08 09:00:00'),
(102, 'Bob J.',      'bob@email.com',   '8765432109', '2024-01-20 11:00:00'),  -- same customer, name changed
(103, 'Carol White', 'carol@email.com', '7654321098', '2024-01-05 07:00:00'),
(104, 'Dave Brown',  'dave@email.com',  '6543210987', '2024-01-12 06:00:00'),
(104, 'Dave Brown',  'dave@email.com',  '6543210987', '2024-01-12 06:00:00');  -- exact duplicate
```

### Easy — Remove exact duplicate rows, keep one

**Question:** From `raw_customers`, return one row per unique combination of `customer_id`, `email`, and `phone`. When duplicates exist, keep the row with the latest `updated_at`.

**Expected Output:**

| customer_id | name        | email           | phone      | updated_at          |
|-------------|-------------|-----------------|------------|---------------------|
| 101         | Alice Smith | alice@email.com | 9876543210 | 2024-01-15 10:00:00 |
| 102         | Bob J.      | bob@email.com   | 8765432109 | 2024-01-20 11:00:00 |
| 103         | Carol White | carol@email.com | 7654321098 | 2024-01-05 07:00:00 |
| 104         | Dave Brown  | dave@email.com  | 6543210987 | 2024-01-12 06:00:00 |

---

### Medium — Deduplicate and flag which rows are duplicates

**Question:** Add a column `is_duplicate` (`TRUE`/`FALSE`) to every row in `raw_customers`. A row is a duplicate if another row exists with the same `customer_id` and `email` but an earlier `updated_at`. Keep all rows but flag the non-latest ones as duplicates.

**Expected Output:**

| id | customer_id | name        | updated_at          | is_duplicate |
|----|-------------|-------------|---------------------|--------------|
| 1  | 101         | Alice Smith | 2024-01-10 08:00:00 | TRUE         |
| 2  | 101         | Alice Smith | 2024-01-15 10:00:00 | FALSE        |
| 3  | 102         | Bob Jones   | 2024-01-08 09:00:00 | TRUE         |
| 4  | 102         | Bob J.      | 2024-01-20 11:00:00 | FALSE        |
| 5  | 103         | Carol White | 2024-01-05 07:00:00 | FALSE        |
| 6  | 104         | Dave Brown  | 2024-01-12 06:00:00 | FALSE        |
| 7  | 104         | Dave Brown  | 2024-01-12 06:00:00 | TRUE         |

> Hint: use `ROW_NUMBER() OVER (PARTITION BY customer_id, email ORDER BY updated_at DESC)` — rows where `rn > 1` are duplicates.
