# Day 2 Notes — SQL: Stored Procedures, Materialized Views & Sequences

## Topics Covered
1. Stored Procedures — definition, syntax, vs functions
2. Materialized Views — definition, refresh strategies, vs regular views
3. Sequences — definition, usage, custom sequences

---

## 1. Stored Procedures

### What is a Stored Procedure?
A **named, precompiled block of SQL** stored in the database that performs one or more operations.
Unlike functions, procedures **do not return a value** — they perform actions (INSERT, UPDATE, DELETE, COMMIT, ROLLBACK).

### Procedure vs Function — Key Differences

| Feature | Function | Procedure |
|---------|---------|-----------|
| Returns value | Yes (must) | No (optional OUT params) |
| Used in SELECT | Yes | No |
| Can COMMIT/ROLLBACK | No | Yes |
| Called with | `SELECT func()` | `CALL proc()` |
| Purpose | Compute and return | Perform actions |

### Syntax (PostgreSQL)

```sql
CREATE OR REPLACE PROCEDURE procedure_name(param1 datatype, param2 datatype)
LANGUAGE plpgsql
AS $$
BEGIN
    -- SQL statements here
END;
$$;

-- Call a procedure
CALL procedure_name(arg1, arg2);
```

### Example 1 — Simple Insert Procedure

```sql
CREATE OR REPLACE PROCEDURE company.add_employee(
    p_first_name VARCHAR,
    p_last_name  VARCHAR,
    p_email      VARCHAR,
    p_salary     NUMERIC,
    p_dept_id    INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO company.employees (first_name, last_name, email, salary, dept_id)
    VALUES (p_first_name, p_last_name, p_email, p_salary, p_dept_id);

    RAISE NOTICE 'Employee % % added successfully.', p_first_name, p_last_name;
END;
$$;

-- Call it
CALL company.add_employee('John', 'Doe', 'john.doe@company.com', 72000, 1);
```

### Example 2 — Procedure with Transaction Control

Procedures can COMMIT and ROLLBACK inside them — functions cannot.

```sql
CREATE OR REPLACE PROCEDURE company.transfer_employee(
    p_emp_id     INT,
    p_new_dept   INT,
    p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if employee exists
    IF NOT EXISTS (SELECT 1 FROM company.employees WHERE emp_id = p_emp_id) THEN
        RAISE EXCEPTION 'Employee % not found.', p_emp_id;
    END IF;

    -- Check if department exists
    IF NOT EXISTS (SELECT 1 FROM company.departments WHERE dept_id = p_new_dept) THEN
        RAISE EXCEPTION 'Department % not found.', p_new_dept;
    END IF;

    UPDATE company.employees
    SET dept_id = p_new_dept,
        salary  = p_new_salary
    WHERE emp_id = p_emp_id;

    RAISE NOTICE 'Employee % transferred to dept % with salary %.', p_emp_id, p_new_dept, p_new_salary;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

-- Call it
CALL company.transfer_employee(1, 2, 88000);
```

### Example 3 — Procedure with OUT Parameter

```sql
CREATE OR REPLACE PROCEDURE company.get_dept_headcount(
    p_dept_id  INT,
    OUT p_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*) INTO p_count
    FROM company.employees
    WHERE dept_id = p_dept_id;
END;
$$;

-- Call and capture OUT parameter
DO $$
DECLARE
    v_count INT;
BEGIN
    CALL company.get_dept_headcount(1, v_count);
    RAISE NOTICE 'Headcount: %', v_count;
END;
$$;
```

### Example 4 — Bulk Salary Update Procedure

```sql
CREATE OR REPLACE PROCEDURE company.apply_annual_raise(p_percent NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_updated INT;
BEGIN
    UPDATE company.employees
    SET salary = salary * (1 + p_percent / 100)
    WHERE status = 'active';

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RAISE NOTICE '% employees received a % %% raise.', v_rows_updated, p_percent;

    COMMIT;
END;
$$;

CALL company.apply_annual_raise(10);
```

### When to Use Procedures in Data Engineering
| Use Case | Why Procedure |
|----------|--------------|
| ETL batch loads | Can commit after each batch, handle errors with ROLLBACK |
| Data cleanup jobs | Run DELETE/UPDATE with logging inside one atomic unit |
| Scheduled jobs (pg_cron) | Call procedures on a schedule |
| Audit logging | Wrap business operations with before/after audit inserts |

---

## 2. Materialized Views

### What is a Materialized View?
A **snapshot of a query result stored physically on disk**.

- Regular view: runs the query **every time** you SELECT from it — always fresh, always slow.
- Materialized view: runs the query **once**, stores the result — fast to read, must be **refreshed** manually or on a schedule.

### Regular View vs Materialized View

| Feature | Regular View | Materialized View |
|---------|-------------|-------------------|
| Stores data | No (virtual) | Yes (on disk) |
| Read speed | Slow (re-runs query) | Fast (pre-computed) |
| Always fresh | Yes | No — needs REFRESH |
| Can be indexed | No | Yes |
| Use case | Simple abstraction | Heavy aggregations, reporting |

### Syntax

```sql
-- Create
CREATE MATERIALIZED VIEW view_name AS
SELECT ...
FROM ...
WITH DATA;            -- WITH DATA populates immediately
                      -- WITH NO DATA creates empty, must refresh before use

-- Refresh
REFRESH MATERIALIZED VIEW view_name;

-- Refresh without locking reads (PostgreSQL 9.4+)
REFRESH MATERIALIZED VIEW CONCURRENTLY view_name;

-- Drop
DROP MATERIALIZED VIEW IF EXISTS view_name;
```

> `CONCURRENTLY` requires a **UNIQUE index** on the materialized view. It allows reads during refresh — critical for production.

### Example 1 — Department Salary Summary

```sql
CREATE MATERIALIZED VIEW company.dept_salary_summary AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id)         AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary)           AS min_salary,
    MAX(e.salary)           AS max_salary,
    SUM(e.salary)           AS total_salary_cost
FROM company.departments d
LEFT JOIN company.employees e ON d.dept_id = e.dept_id
WHERE e.status = 'active'
GROUP BY d.dept_id, d.dept_name
WITH DATA;

-- Query it (fast — reads from disk)
SELECT * FROM company.dept_salary_summary ORDER BY total_salary_cost DESC;

-- Refresh after data changes
REFRESH MATERIALIZED VIEW company.dept_salary_summary;
```

### Example 2 — Adding an Index to a Materialized View

```sql
-- Indexes on materialized views speed up queries further
CREATE UNIQUE INDEX ON company.dept_salary_summary (dept_id);

-- Now CONCURRENTLY refresh is possible
REFRESH MATERIALIZED VIEW CONCURRENTLY company.dept_salary_summary;
```

### Example 3 — Monthly Hire Report

```sql
CREATE MATERIALIZED VIEW company.monthly_hire_report AS
SELECT
    DATE_TRUNC('month', hire_date)  AS hire_month,
    d.dept_name,
    COUNT(*)                        AS hires
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
GROUP BY DATE_TRUNC('month', hire_date), d.dept_name
ORDER BY hire_month DESC
WITH DATA;

SELECT * FROM company.monthly_hire_report;
```

### Refresh Strategies in Data Engineering

| Strategy | How | When to use |
|----------|-----|-------------|
| Manual | `REFRESH MATERIALIZED VIEW` | Ad-hoc, triggered by pipeline completion |
| Scheduled (pg_cron) | `SELECT cron.schedule(...)` | Daily/hourly reporting aggregations |
| After ETL load | Call REFRESH at end of load procedure | Keeps reporting layer in sync with loads |
| CONCURRENTLY | With unique index | Production — zero downtime refreshes |

### When to Use Materialized Views in DE
| Use Case | Why |
|----------|-----|
| BI/reporting dashboards | Pre-aggregate millions of rows; dashboards read in ms |
| Data warehouse marts | Replace slow cross-schema joins with cached results |
| End-of-day summaries | Refresh once at midnight, serve reads all day |
| Expensive window functions | Pre-compute rank/lead/lag results for reporting |

---

## 3. Sequences

### What is a Sequence?
A **database object that generates unique integer values** in order.
Used to auto-generate primary keys and any other monotonically increasing numbers.

`SERIAL` / `BIGSERIAL` in PostgreSQL are **syntactic shortcuts** that create a sequence behind the scenes.

### SERIAL vs Explicit Sequence

```sql
-- SERIAL shortcut (implicit sequence)
CREATE TABLE t (id SERIAL PRIMARY KEY);

-- Equivalent explicit sequence
CREATE SEQUENCE t_id_seq START 1 INCREMENT 1;
CREATE TABLE t (id INT DEFAULT nextval('t_id_seq') PRIMARY KEY);
```

### Sequence Functions

| Function | Description |
|----------|-------------|
| `nextval('seq')` | Advance and return the next value |
| `currval('seq')` | Return the current value (within same session) |
| `setval('seq', n)` | Manually set the sequence to value n |
| `lastval()` | Return last value from any sequence in this session |

### Full Sequence Syntax

```sql
CREATE SEQUENCE sequence_name
    START WITH    1          -- first value
    INCREMENT BY  1          -- step
    MINVALUE      1          -- lower bound
    MAXVALUE      9999999    -- upper bound (omit for no limit)
    CYCLE                    -- restart at MINVALUE after MAXVALUE (default: NO CYCLE)
    CACHE         1;         -- number of values pre-allocated in memory
```

### Example 1 — Custom Invoice Number Sequence

```sql
CREATE SEQUENCE company.invoice_number_seq
    START WITH    1001
    INCREMENT BY  1
    NO CYCLE;

-- Use in a table
CREATE TABLE company.invoices (
    invoice_id     INT DEFAULT nextval('company.invoice_number_seq') PRIMARY KEY,
    invoice_number VARCHAR(20) GENERATED ALWAYS AS ('INV-' || nextval('company.invoice_number_seq')::TEXT) STORED,
    customer_name  VARCHAR(200),
    total_amount   NUMERIC(12, 2),
    created_at     TIMESTAMP DEFAULT NOW()
);

-- Or call nextval directly in an INSERT
INSERT INTO company.invoices (invoice_id, customer_name, total_amount)
VALUES (nextval('company.invoice_number_seq'), 'Acme Corp', 15000.00);
```

### Example 2 — Employee ID with Gap-Free Sequence

```sql
CREATE SEQUENCE company.emp_code_seq
    START WITH  1000
    INCREMENT BY 1
    MINVALUE     1000
    NO CYCLE;

-- Generate employee codes like EMP-1000, EMP-1001, ...
SELECT 'EMP-' || nextval('company.emp_code_seq')::TEXT AS employee_code;
```

### Example 3 — Reset / Manipulate a Sequence

```sql
-- Check current value
SELECT last_value FROM company.invoice_number_seq;

-- Jump the sequence to a specific value (useful after bulk inserts)
SELECT setval('company.invoice_number_seq', 5000);

-- Next call will return 5001
SELECT nextval('company.invoice_number_seq');

-- Restart from beginning
ALTER SEQUENCE company.invoice_number_seq RESTART WITH 1001;
```

### Example 4 — Shared Sequence Across Multiple Tables

```sql
-- One sequence for unique IDs across all event tables
CREATE SEQUENCE company.global_event_id_seq START 1;

CREATE TABLE company.login_events (
    event_id   BIGINT DEFAULT nextval('company.global_event_id_seq') PRIMARY KEY,
    user_id    INT,
    event_type VARCHAR(50) DEFAULT 'LOGIN',
    occurred_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE company.purchase_events (
    event_id    BIGINT DEFAULT nextval('company.global_event_id_seq') PRIMARY KEY,
    user_id     INT,
    event_type  VARCHAR(50) DEFAULT 'PURCHASE',
    amount      NUMERIC(10,2),
    occurred_at TIMESTAMP DEFAULT NOW()
);
-- event_ids are globally unique across both tables
```

### Important Sequence Behaviors

| Behavior | Detail |
|----------|--------|
| Never rolls back | `nextval()` increments even if the transaction rolls back — gaps are normal |
| Not transactional | Designed for performance — gaps are expected, not a bug |
| Session-scoped `currval` | `currval()` only works after `nextval()` has been called in the same session |
| Concurrent-safe | Multiple sessions call `nextval()` simultaneously without conflicts |

### Sequences in Data Engineering

| Use Case | How |
|----------|-----|
| Surrogate key generation | `SERIAL`/`BIGSERIAL` for fact/dimension table PKs |
| Batch run IDs | One sequence per pipeline; each run gets a unique batch_id |
| Partition numbering | Sequence drives partition suffix in table names |
| Idempotency keys | Generate unique keys for deduplication in event streams |
| Load watermarks | Sequence value used as a monotonic watermark for incremental loads |

---

## Summary Comparison

| Object | Stores Data | Returnable | Refreshable | Auto-increments |
|--------|------------|-----------|-------------|----------------|
| View | No | Yes (via SELECT) | N/A (always live) | No |
| Materialized View | Yes | Yes (via SELECT) | Yes (manual/scheduled) | No |
| Function | No | Yes (return value) | N/A | No |
| Procedure | No | No (OUT params only) | N/A | No |
| Sequence | Yes (counter) | Yes (nextval) | N/A | Yes |

---

## DE Relevance Summary

| Concept | Data Engineering Application |
|---------|------------------------------|
| Stored Procedures | Encapsulate ETL logic, batch loads with COMMIT/ROLLBACK |
| Materialized Views | Pre-aggregate mart layer; refresh after pipeline completes |
| REFRESH CONCURRENTLY | Zero-downtime refresh in production reporting schemas |
| Sequences | Generate surrogate keys, batch run IDs, idempotency tokens |
| setval() | Re-seed sequences after bulk data migrations |
| Gaps in sequences | Expected behavior — never rely on gap-free for business logic |
