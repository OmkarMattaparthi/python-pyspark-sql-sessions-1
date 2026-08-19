-- =============================================================
-- Day 2 Practice — Stored Procedures, Materialized Views & Sequences
-- =============================================================
-- Prerequisite: run day1_practice.sql first to create company schema & tables


-- ===============================================================
-- SECTION 1: STORED PROCEDURES
-- ===============================================================
--
-- A stored procedure is a named block of SQL saved inside the database.
-- It performs actions (INSERT, UPDATE, DELETE, COMMIT, ROLLBACK).
-- Unlike a function, a procedure does NOT return a value directly —
-- instead it performs work, and optionally returns data through OUT parameters.
--
-- Syntax:
--   CREATE OR REPLACE PROCEDURE schema.proc_name(param datatype, ...)
--   LANGUAGE plpgsql
--   AS $$
--   BEGIN
--       -- statements
--   END;
--   $$;
--
--   CALL schema.proc_name(arg1, arg2);
--
-- Key rules:
--   - Parameters can be IN (default), OUT, or INOUT.
--   - A procedure CAN contain COMMIT and ROLLBACK (functions cannot).
--   - Called with CALL, never used inside a SELECT.
-- ---------------------------------------------------------------


-- 1a. SIMPLE INSERT PROCEDURE
-- ----------------------------
-- Wraps an INSERT into a procedure so callers don't need to know the table structure.
-- p_location has DEFAULT NULL — caller can omit it and location will be stored as NULL.
-- RAISE NOTICE prints a message to the client (like a print statement — does not stop execution).

CREATE OR REPLACE PROCEDURE company.add_department(
    p_dept_name VARCHAR,
    p_location  VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO company.departments (dept_name, location)
    VALUES (p_dept_name, p_location);

    RAISE NOTICE 'Department "%" added.', p_dept_name;
END;
$$;

-- Call with both arguments
CALL company.add_department('Data Engineering', 'Hyderabad');

-- Call with only dept_name — location defaults to NULL
CALL company.add_department('Legal');


-- 1b. PROCEDURE WITH EXISTENCE CHECK AND EXCEPTION
-- --------------------------------------------------
-- Before performing an UPDATE, we validate the employee exists.
-- IF NOT EXISTS (...) checks the table for a matching row.
-- RAISE EXCEPTION stops execution and returns an error to the caller —
-- unlike RAISE NOTICE (informational), EXCEPTION aborts the current transaction.

CREATE OR REPLACE PROCEDURE company.deactivate_employee(p_emp_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Guard clause: fail fast if the employee doesn't exist
    IF NOT EXISTS (SELECT 1 FROM company.employees WHERE emp_id = p_emp_id) THEN
        RAISE EXCEPTION 'Employee with ID % does not exist.', p_emp_id;
    END IF;

    UPDATE company.employees
    SET status = 'inactive'
    WHERE emp_id = p_emp_id;

    RAISE NOTICE 'Employee % deactivated.', p_emp_id;
END;
$$;

-- Deactivate employee 3 — succeeds
CALL company.deactivate_employee(3);

-- Uncomment to see the exception in action:
-- CALL company.deactivate_employee(9999);


-- 1c. PROCEDURE WITH GET DIAGNOSTICS + COMMIT / ROLLBACK
-- -------------------------------------------------------
-- GET DIAGNOSTICS v_rows = ROW_COUNT captures how many rows the last DML affected.
-- COMMIT inside a procedure permanently saves the changes.
-- EXCEPTION ... WHEN OTHERS catches any runtime error, rolls back, and re-raises.
-- This pattern ensures the procedure is atomic: all rows update or none do.
-- Note: %% in RAISE NOTICE produces a literal % character (escaping).

CREATE OR REPLACE PROCEDURE company.bulk_salary_update(
    p_dept_id   INT,
    p_raise_pct NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INT;  -- will hold the count of updated rows
BEGIN
    UPDATE company.employees
    SET salary = salary * (1 + p_raise_pct / 100)
    WHERE dept_id = p_dept_id
      AND status  = 'active';

    -- Capture how many rows the UPDATE just affected
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    -- %% prints a literal percent sign in the output
    RAISE NOTICE '% employees in dept % received a % %% raise.', v_rows, p_dept_id, p_raise_pct;

    COMMIT;  -- persist changes
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- undo everything if any error occurred
        RAISE;     -- re-raise the original error so the caller sees it
END;
$$;

-- Give dept 1 (Engineering) a 10% raise
CALL company.bulk_salary_update(1, 10);


-- 1d. TRANSFER PROCEDURE — TWO UPDATES IN ONE ATOMIC TRANSACTION
-- ---------------------------------------------------------------
-- Both the department change and the salary change must succeed together.
-- If either fails (e.g. bad dept_id), the EXCEPTION block rolls back both.
-- Two guard clauses run first so we fail with a clear message before touching data.

CREATE OR REPLACE PROCEDURE company.move_employee(
    p_emp_id     INT,
    p_new_dept   INT,
    p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate employee exists
    IF NOT EXISTS (SELECT 1 FROM company.employees WHERE emp_id = p_emp_id) THEN
        RAISE EXCEPTION 'Employee % not found.', p_emp_id;
    END IF;

    -- Validate target department exists
    IF NOT EXISTS (SELECT 1 FROM company.departments WHERE dept_id = p_new_dept) THEN
        RAISE EXCEPTION 'Department % not found.', p_new_dept;
    END IF;

    -- Both columns update in one statement — atomic by nature
    UPDATE company.employees
    SET dept_id = p_new_dept,
        salary  = p_new_salary
    WHERE emp_id = p_emp_id;

    RAISE NOTICE 'Employee % moved to dept % with salary %.', p_emp_id, p_new_dept, p_new_salary;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

-- Move employee 2 to dept 1 with a new salary of 90,000
CALL company.move_employee(2, 1, 90000);


-- 1e. PROCEDURE WITH OUT PARAMETER
-- ---------------------------------
-- OUT parameters let a procedure pass a value back to the caller
-- without using a RETURN statement.
-- The caller declares a variable, passes it in, and reads it after CALL.
-- SELECT ... INTO p_count assigns the query result directly to the OUT parameter.
-- DO $$ ... $$ is an anonymous block — runs once, not saved as a named object.

CREATE OR REPLACE PROCEDURE company.get_dept_headcount(
    p_dept_id  INT,
    OUT p_count INT       -- caller receives this value after CALL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*)
    INTO p_count           -- write result into the OUT parameter
    FROM company.employees
    WHERE dept_id = p_dept_id
      AND status  = 'active';
END;
$$;

-- Anonymous block to call the procedure and read the OUT value
DO $$
DECLARE v_count INT;      -- local variable to receive the OUT value
BEGIN
    CALL company.get_dept_headcount(1, v_count);
    RAISE NOTICE 'Dept 1 active headcount: %', v_count;
END;
$$;


-- 1f. ARCHIVE + DELETE IN ONE TRANSACTION
-- -----------------------------------------
-- LIKE company.employees INCLUDING ALL copies the column definitions and constraints.
-- We add an extra column archived_at to track when the row was moved.
-- GET DIAGNOSTICS after the INSERT tells us how many rows were archived.
-- The DELETE runs only after the INSERT succeeds — both inside one transaction.
-- If the INSERT fails, ROLLBACK undoes nothing was deleted either.

CREATE TABLE IF NOT EXISTS company.employees_archive (
    LIKE company.employees INCLUDING ALL,   -- copies all columns + constraints from employees
    archived_at TIMESTAMP DEFAULT NOW()     -- extra column: when was this row archived
);

CREATE OR REPLACE PROCEDURE company.archive_inactive_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INT;
BEGIN
    -- Copy inactive employees into the archive table
    INSERT INTO company.employees_archive
    SELECT *, NOW()                          -- * = all employees columns; NOW() = archived_at
    FROM company.employees
    WHERE status = 'inactive';

    GET DIAGNOSTICS v_rows = ROW_COUNT;      -- how many rows were just inserted

    -- Remove them from the live table only after archive insert succeeds
    DELETE FROM company.employees WHERE status = 'inactive';

    RAISE NOTICE '% inactive employees archived and removed.', v_rows;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;   -- archive insert or delete failed — nothing changes
        RAISE;
END;
$$;

CALL company.archive_inactive_employees();


-- ===============================================================
-- SECTION 2: MATERIALIZED VIEWS
-- ===============================================================
--
-- A materialized view (MV) is a query whose result is physically stored on disk.
-- Unlike a regular view (which re-runs the query every time you SELECT from it),
-- an MV reads from its stored snapshot — much faster for heavy aggregations.
--
-- The tradeoff: the data goes stale as the underlying tables change.
-- You must REFRESH the MV to pull in the latest data.
--
-- Syntax:
--   CREATE MATERIALIZED VIEW schema.mv_name AS
--   SELECT ...
--   WITH DATA;            -- executes the query immediately and stores results
--                         -- use WITH NO DATA to create empty (must REFRESH before reading)
--
--   REFRESH MATERIALIZED VIEW schema.mv_name;            -- locks the view during refresh
--   REFRESH MATERIALIZED VIEW CONCURRENTLY schema.mv_name; -- no lock, needs UNIQUE index
-- ---------------------------------------------------------------


-- 2a. DEPARTMENT SALARY SUMMARY MATERIALIZED VIEW
-- -------------------------------------------------
-- LEFT JOIN ensures departments with no employees still appear (headcount = 0).
-- The join condition includes e.status = 'active' inside the ON clause (not WHERE)
-- so inactive employees are excluded from the count but the department row is kept.
-- WITH DATA runs the query immediately and stores the result.

CREATE MATERIALIZED VIEW company.dept_salary_summary AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id)         AS headcount,       -- NULL emp_ids (no employees) count as 0
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary)           AS min_salary,
    MAX(e.salary)           AS max_salary,
    SUM(e.salary)           AS total_salary_cost
FROM company.departments d
LEFT JOIN company.employees e
    ON d.dept_id = e.dept_id AND e.status = 'active'   -- filter inside JOIN, not WHERE
GROUP BY d.dept_id, d.dept_name
WITH DATA;

-- Query the MV — reads from disk, not from the live tables
SELECT * FROM company.dept_salary_summary ORDER BY total_salary_cost DESC NULLS LAST;


-- 2b. UNIQUE INDEX + CONCURRENT REFRESH
-- ---------------------------------------
-- REFRESH MATERIALIZED VIEW (without CONCURRENTLY) locks the entire MV for reads
-- while it rebuilds — queries against it will block/wait.
-- REFRESH MATERIALIZED VIEW CONCURRENTLY builds a new snapshot in the background,
-- then swaps it in — reads can continue against the old data during the refresh.
-- CONCURRENTLY requires a UNIQUE index on the MV so PostgreSQL can diff old vs new rows.

CREATE UNIQUE INDEX idx_dept_salary_summary_dept_id
    ON company.dept_salary_summary (dept_id);

-- Now we can refresh without blocking readers
REFRESH MATERIALIZED VIEW CONCURRENTLY company.dept_salary_summary;


-- 2c. DEPARTMENT HEADCOUNT MATERIALIZED VIEW
-- -------------------------------------------
-- Similar pattern to 2a but simpler — only headcount and avg_salary per department.
-- Useful as a quick lookup for BI tools or API endpoints that need dept stats.

CREATE MATERIALIZED VIEW company.dept_headcount_mv AS
SELECT
    d.dept_name,
    COUNT(e.emp_id)         AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM company.departments d
LEFT JOIN company.employees e
    ON d.dept_id = e.dept_id AND e.status = 'active'
GROUP BY d.dept_name
WITH DATA;

SELECT * FROM company.dept_headcount_mv ORDER BY headcount DESC;


-- 2d. TOP EARNERS MATERIALIZED VIEW + MANUAL REFRESH AFTER DATA CHANGE
-- ----------------------------------------------------------------------
-- This MV has a LIMIT 5 — MVs can use ORDER BY and LIMIT just like a regular SELECT.
-- After we UPDATE salaries in the live table, the MV still shows the old data.
-- REFRESH rebuilds it from scratch using the current state of employees.
-- Notice we SELECT from it BEFORE and AFTER the refresh to see the difference.

CREATE MATERIALIZED VIEW company.top_earners_mv AS
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.salary,
    d.dept_name
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
WHERE e.status = 'active'
ORDER BY e.salary DESC
LIMIT 5
WITH DATA;

-- View before the raise — snapshot of current data
SELECT * FROM company.top_earners_mv;

-- Give Engineering a 20% raise in the live table
UPDATE company.employees SET salary = salary * 1.20 WHERE dept_id = 1 AND status = 'active';

-- MV still shows OLD salaries — the UPDATE did not auto-refresh it
-- REFRESH rebuilds the snapshot from the updated employees table
REFRESH MATERIALIZED VIEW company.top_earners_mv;

-- Now we see the new salaries
SELECT * FROM company.top_earners_mv;


-- 2e. MONTHLY HIRE REPORT MATERIALIZED VIEW
-- -------------------------------------------
-- DATE_TRUNC('month', hire_date) strips the day/time part and keeps only year+month.
-- Example: '2023-03-15' becomes '2023-03-01 00:00:00'.
-- This lets us GROUP BY month without writing complex EXTRACT logic.
-- Useful for trend reports — refresh once per day or after each batch load.

CREATE MATERIALIZED VIEW company.monthly_hire_report AS
SELECT
    DATE_TRUNC('month', hire_date) AS hire_month,  -- truncate to first day of month
    d.dept_name,
    COUNT(*)                       AS hires
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
GROUP BY DATE_TRUNC('month', hire_date), d.dept_name
ORDER BY hire_month DESC
WITH DATA;

SELECT * FROM company.monthly_hire_report;


-- 2f. CENTRALIZED REFRESH PROCEDURE WITH AUDIT LOG
-- --------------------------------------------------
-- In pipelines, multiple MVs often need refreshing together after a load.
-- A procedure wraps all REFRESH calls in one place so pipelines call a single CALL.
-- After each refresh, we INSERT a log row — this creates an audit trail of when each MV was last refreshed.
-- All refreshes + log inserts happen in one transaction: if any fails, ROLLBACK undoes all.

CREATE TABLE IF NOT EXISTS company.refresh_log (
    log_id       SERIAL PRIMARY KEY,
    view_name    VARCHAR(200) NOT NULL,
    refreshed_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE company.run_daily_refresh()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Refresh dept_salary_summary and log it
    REFRESH MATERIALIZED VIEW company.dept_salary_summary;
    INSERT INTO company.refresh_log (view_name) VALUES ('company.dept_salary_summary');

    -- Refresh dept_headcount_mv and log it
    REFRESH MATERIALIZED VIEW company.dept_headcount_mv;
    INSERT INTO company.refresh_log (view_name) VALUES ('company.dept_headcount_mv');

    -- Refresh monthly_hire_report and log it
    REFRESH MATERIALIZED VIEW company.monthly_hire_report;
    INSERT INTO company.refresh_log (view_name) VALUES ('company.monthly_hire_report');

    RAISE NOTICE 'All materialized views refreshed.';
    COMMIT;   -- all refreshes and log inserts commit together
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;   -- if any single refresh fails, no log rows are written either
        RAISE;
END;
$$;

-- Run the daily refresh (call this from a pg_cron job or pipeline scheduler)
CALL company.run_daily_refresh();

-- Check when each MV was last refreshed
SELECT * FROM company.refresh_log ORDER BY refreshed_at DESC;


-- ===============================================================
-- SECTION 3: SEQUENCES
-- ===============================================================
--
-- A sequence is a database object that generates unique integer values in order.
-- It is the mechanism behind SERIAL / BIGSERIAL columns.
-- Key properties:
--   - Sequences are NOT transactional — a consumed value is gone even after ROLLBACK.
--   - Multiple sessions can call nextval() simultaneously without conflicts.
--   - Gaps in sequence values are normal and expected.
--
-- Core functions:
--   nextval('seq')  — advance and return the next value (always increments)
--   currval('seq')  — return the current value (only after nextval in same session)
--   lastval()       — return the last value from any sequence in this session
--   setval('seq',n) — manually jump the sequence to value n
-- ---------------------------------------------------------------


-- 3a. BASIC SEQUENCE CREATION AND USAGE
-- ----------------------------------------
-- START WITH 1      — first value returned by nextval()
-- INCREMENT BY 1    — each call adds 1
-- NO CYCLE          — after reaching MAXVALUE, raise an error instead of wrapping around
-- Each nextval() call permanently advances the counter even if you ROLLBACK.

CREATE SEQUENCE IF NOT EXISTS company.batch_run_seq
    START WITH   1
    INCREMENT BY 1
    NO CYCLE;

-- Each call returns the next integer in the sequence
SELECT nextval('company.batch_run_seq') AS batch_id;  -- returns 1
SELECT nextval('company.batch_run_seq') AS batch_id;  -- returns 2
SELECT nextval('company.batch_run_seq') AS batch_id;  -- returns 3

-- lastval() returns the most recent value produced in this session (any sequence)
SELECT lastval() AS last_batch_id;  -- returns 3


-- 3b. SEQUENCE AS A TABLE COLUMN DEFAULT
-- ----------------------------------------
-- Instead of SERIAL, we explicitly wire a sequence to a column via DEFAULT nextval(...).
-- This gives full control — we can use the same sequence across multiple tables
-- or share it with other objects.
-- When INSERT omits run_id, PostgreSQL calls nextval() automatically.

CREATE TABLE IF NOT EXISTS company.pipeline_runs (
    run_id        BIGINT       DEFAULT nextval('company.batch_run_seq') PRIMARY KEY,
    pipeline_name VARCHAR(200) NOT NULL,
    status        VARCHAR(50)  DEFAULT 'running',
    started_at    TIMESTAMP    DEFAULT NOW()
);

-- run_id is auto-generated from the sequence — no need to specify it
INSERT INTO company.pipeline_runs (pipeline_name) VALUES
    ('load_employees'),
    ('load_departments'),
    ('refresh_marts');

SELECT * FROM company.pipeline_runs ORDER BY run_id;


-- 3c. CUSTOM SEQUENCE — INVOICE NUMBERS STARTING AT 1001
-- --------------------------------------------------------
-- Business requirement: invoice IDs must start at 1001, not 1.
-- START WITH 1001 sets the first value; the sequence behaves identically after that.
-- Useful for human-readable IDs where starting at 1 looks unprofessional.

CREATE SEQUENCE IF NOT EXISTS company.invoice_number_seq
    START WITH   1001
    INCREMENT BY 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS company.invoices (
    invoice_id    BIGINT        DEFAULT nextval('company.invoice_number_seq') PRIMARY KEY,
    customer_name VARCHAR(200)  NOT NULL,
    total_amount  NUMERIC(12,2) CHECK (total_amount >= 0),
    created_at    TIMESTAMP     DEFAULT NOW()
);

-- invoice_id will be 1001, 1002, 1003
INSERT INTO company.invoices (customer_name, total_amount) VALUES
    ('Acme Corp',  15000.00),
    ('Beta Ltd',    8750.50),
    ('Gamma Pvt',  22000.00);

SELECT * FROM company.invoices;


-- 3d. SEQUENCE WITH CUSTOM INCREMENT
-- -------------------------------------
-- INCREMENT BY 5 means each nextval() adds 5 to the previous value.
-- Output: 5000, 5005, 5010, 5015, ...
-- Real use: order reference numbers that need spacing (e.g. to embed check digits
-- or leave room for manually assigned values between batches).

CREATE SEQUENCE IF NOT EXISTS company.order_ref_seq
    START WITH   5000
    INCREMENT BY 5
    NO CYCLE;

SELECT nextval('company.order_ref_seq');  -- 5000
SELECT nextval('company.order_ref_seq');  -- 5005
SELECT nextval('company.order_ref_seq');  -- 5010
SELECT nextval('company.order_ref_seq');  -- 5015


-- 3e. SHARED SEQUENCE ACROSS TWO TABLES (GLOBALLY UNIQUE EVENT IDs)
-- -------------------------------------------------------------------
-- Both login_events and purchase_events use the same sequence for event_id.
-- This guarantees that no two events — regardless of type — share the same ID.
-- Useful for event streaming where all events feed a single unified log or queue.
-- Insert order: 2 logins (IDs 1,2) then 2 purchases (IDs 3,4) — global uniqueness.

CREATE SEQUENCE IF NOT EXISTS company.global_event_seq START 1;

CREATE TABLE IF NOT EXISTS company.login_events (
    event_id    BIGINT    DEFAULT nextval('company.global_event_seq') PRIMARY KEY,
    user_id     INT,
    event_type  VARCHAR(50) DEFAULT 'LOGIN',
    occurred_at TIMESTAMP   DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS company.purchase_events (
    event_id    BIGINT    DEFAULT nextval('company.global_event_seq') PRIMARY KEY,
    user_id     INT,
    event_type  VARCHAR(50) DEFAULT 'PURCHASE',
    amount      NUMERIC(10,2),
    occurred_at TIMESTAMP   DEFAULT NOW()
);

-- Insert 2 logins — they get event_id 1, 2
INSERT INTO company.login_events    (user_id) VALUES (101), (102);

-- Insert 2 purchases — they get event_id 3, 4 (sequence continues from where it left off)
INSERT INTO company.purchase_events (user_id, amount) VALUES (101, 500.00), (103, 1200.00);

-- UNION ALL both tables — all four event_ids are globally unique
SELECT 'login'    AS source, event_id FROM company.login_events
UNION ALL
SELECT 'purchase' AS source, event_id FROM company.purchase_events
ORDER BY event_id;


-- 3f. SETVAL — RE-SEEDING A SEQUENCE AFTER BULK MIGRATION
-- ---------------------------------------------------------
-- Problem: a bulk migration inserted 50,000 rows with manually assigned IDs 1–50000.
-- The sequence is still at its last auto-generated value (e.g. 4).
-- If we insert normally now, nextval() returns 5 — which conflicts with the migrated data.
-- Fix: use setval() to jump the sequence to the highest existing ID.
-- After setval('seq', 50000), the next nextval() call returns 50001 — safe.

SELECT setval('company.batch_run_seq', 50000);  -- jump to 50000

-- Confirm: next call returns 50001, no PK conflict
SELECT nextval('company.batch_run_seq');   -- 50001


-- 3g. SEQUENCES DO NOT ROLL BACK — GAPS ARE PERMANENT
-- -----------------------------------------------------
-- This is the most important behavioral difference between sequences and regular data.
-- When a transaction calls nextval() and then rolls back, the sequence value is NOT returned.
-- The counter has permanently advanced. The next transaction gets the value AFTER the gap.
-- This is intentional: making sequences transactional would cause lock contention
-- in high-concurrency systems. Gaps are not a bug — never design business logic
-- that requires gap-free IDs from a sequence.

BEGIN;
SELECT nextval('company.batch_run_seq') AS next_val;  -- sequence advances (e.g. to 50002)
ROLLBACK;   -- transaction rolled back — but the sequence does NOT reset to 50001

-- Sequence is now at 50002 even though the transaction was rolled back
-- The next call skips straight to 50003
SELECT nextval('company.batch_run_seq') AS next_val_after_rollback;  -- 50003


-- 3h. PROCEDURE THAT RETURNS A SEQUENCE VALUE VIA OUT PARAMETER
-- ---------------------------------------------------------------
-- The procedure calls nextval() internally and assigns it to the OUT parameter p_run_id.
-- The caller receives this ID and can use it immediately (e.g. to associate other records).
-- This pattern is common in ETL: "start a batch run, get its ID, use it throughout the load".

CREATE OR REPLACE PROCEDURE company.start_batch_run(
    p_pipeline_name VARCHAR,
    OUT p_run_id    BIGINT     -- caller receives the generated ID through this
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_run_id := nextval('company.batch_run_seq');   -- advance sequence and store in OUT

    INSERT INTO company.pipeline_runs (run_id, pipeline_name)
    VALUES (p_run_id, p_pipeline_name);

    RAISE NOTICE 'Batch run started — run_id: %, pipeline: %', p_run_id, p_pipeline_name;
END;
$$;

-- Anonymous block: call the procedure and print the captured run_id
DO $$
DECLARE v_run_id BIGINT;
BEGIN
    CALL company.start_batch_run('load_orders', v_run_id);
    RAISE NOTICE 'Captured run_id in caller: %', v_run_id;
    -- v_run_id can now be used to tag all rows loaded in this batch
END;
$$;


-- ===============================================================
-- BONUS: DATA WAREHOUSE LOAD TRACKING PATTERN
-- ===============================================================
--
-- Combines all three concepts:
--   Sequence  → unique run_id for every pipeline execution
--   Procedure → start_load_run (create record) + complete_load_run (update stats)
--   MV        → daily summary of all completed loads, refreshed after each run
--
-- This pattern is standard in production data warehouses.
-- The pipeline calls start_load_run at the beginning, does its work,
-- then calls complete_load_run with row counts. The MV gives ops a dashboard.
-- ---------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS dw;

-- Sequence for unique load run IDs across all pipelines
CREATE SEQUENCE IF NOT EXISTS dw.load_run_seq START 1 INCREMENT 1;

-- Audit table: one row per pipeline execution
CREATE TABLE IF NOT EXISTS dw.load_runs (
    run_id         BIGINT       DEFAULT nextval('dw.load_run_seq') PRIMARY KEY,
    table_name     VARCHAR(200) NOT NULL,
    rows_inserted  BIGINT       DEFAULT 0,
    rows_updated   BIGINT       DEFAULT 0,
    started_at     TIMESTAMP    DEFAULT NOW(),
    completed_at   TIMESTAMP,                   -- NULL until the run finishes
    status         VARCHAR(50)  DEFAULT 'running'
);

-- Procedure 1: called at the START of a pipeline run
-- Generates a run_id and inserts a "running" record, returns run_id to caller
CREATE OR REPLACE PROCEDURE dw.start_load_run(
    p_table_name VARCHAR,
    OUT p_run_id BIGINT      -- pipeline receives this ID to use throughout the load
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_run_id := nextval('dw.load_run_seq');

    INSERT INTO dw.load_runs (run_id, table_name)
    VALUES (p_run_id, p_table_name);   -- status defaults to 'running', started_at to NOW()

    RAISE NOTICE 'Load run started — run_id: %, table: %', p_run_id, p_table_name;
END;
$$;

-- Procedure 2: called at the END of a pipeline run
-- Updates the record with final row counts and marks it 'completed'
CREATE OR REPLACE PROCEDURE dw.complete_load_run(
    p_run_id        BIGINT,
    p_rows_inserted BIGINT,
    p_rows_updated  BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE dw.load_runs
    SET rows_inserted = p_rows_inserted,
        rows_updated  = p_rows_updated,
        completed_at  = NOW(),            -- stamp the finish time
        status        = 'completed'
    WHERE run_id = p_run_id;

    RAISE NOTICE 'Load run % completed — inserted: %, updated: %.', p_run_id, p_rows_inserted, p_rows_updated;
    COMMIT;
END;
$$;

-- Materialized view: daily summary of completed loads per table
-- Only completed runs are included (status = 'completed')
-- DATE_TRUNC('day', ...) groups all runs from the same calendar day together
CREATE MATERIALIZED VIEW dw.load_summary_mv AS
SELECT
    table_name,
    DATE_TRUNC('day', started_at)  AS load_date,
    COUNT(*)                        AS total_runs,
    SUM(rows_inserted)              AS total_inserted,
    SUM(rows_updated)               AS total_updated
FROM dw.load_runs
WHERE status = 'completed'
GROUP BY table_name, DATE_TRUNC('day', started_at)
ORDER BY load_date DESC, total_inserted DESC
WITH DATA;

-- Simulate a full pipeline execution:
-- Step 1: start the run, capture run_id
-- Step 2: (pipeline does its work — omitted here)
-- Step 3: complete the run with actual row counts
DO $$
DECLARE v_run_id BIGINT;
BEGIN
    CALL dw.start_load_run('fact_orders', v_run_id);    -- step 1: creates record, returns ID
    -- ... pipeline inserts/updates fact_orders here ...
    CALL dw.complete_load_run(v_run_id, 15000, 3200);   -- step 3: stamps counts and 'completed'
END;
$$;

-- Refresh the MV so the new run appears in the summary
REFRESH MATERIALIZED VIEW dw.load_summary_mv;

SELECT * FROM dw.load_summary_mv;


-- ---------------------------------------------------------------
-- CLEANUP (uncomment to reset for re-practice)
-- ---------------------------------------------------------------
-- DROP SCHEMA company CASCADE;
-- DROP SCHEMA dw CASCADE;
