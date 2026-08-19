-- =============================================================
-- Day 2 Practice — Stored Procedures, Materialized Views & Sequences
-- =============================================================
-- Prerequisite: run day1_practice.sql first to create company schema & tables


-- ---------------------------------------------------------------
-- SECTION 1: STORED PROCEDURES
-- ---------------------------------------------------------------

-- 1a. Simple insert procedure
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

CALL company.add_department('Data Engineering', 'Hyderabad');
CALL company.add_department('Legal');


-- 1b. Procedure with existence check and exception
CREATE OR REPLACE PROCEDURE company.deactivate_employee(p_emp_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM company.employees WHERE emp_id = p_emp_id) THEN
        RAISE EXCEPTION 'Employee with ID % does not exist.', p_emp_id;
    END IF;

    UPDATE company.employees
    SET status = 'inactive'
    WHERE emp_id = p_emp_id;

    RAISE NOTICE 'Employee % deactivated.', p_emp_id;
END;
$$;

CALL company.deactivate_employee(3);
-- CALL company.deactivate_employee(9999);  -- raises exception


-- 1c. Procedure with GET DIAGNOSTICS + COMMIT/ROLLBACK
CREATE OR REPLACE PROCEDURE company.bulk_salary_update(
    p_dept_id     INT,
    p_raise_pct   NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INT;
BEGIN
    UPDATE company.employees
    SET salary = salary * (1 + p_raise_pct / 100)
    WHERE dept_id = p_dept_id
      AND status  = 'active';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '% employees in dept % received a % %% raise.', v_rows, p_dept_id, p_raise_pct;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

CALL company.bulk_salary_update(1, 10);


-- 1d. Transfer procedure — both updates in one transaction
CREATE OR REPLACE PROCEDURE company.move_employee(
    p_emp_id     INT,
    p_new_dept   INT,
    p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM company.employees WHERE emp_id = p_emp_id) THEN
        RAISE EXCEPTION 'Employee % not found.', p_emp_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM company.departments WHERE dept_id = p_new_dept) THEN
        RAISE EXCEPTION 'Department % not found.', p_new_dept;
    END IF;

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

CALL company.move_employee(2, 1, 90000);


-- 1e. Procedure with OUT parameter (headcount)
CREATE OR REPLACE PROCEDURE company.get_dept_headcount(
    p_dept_id  INT,
    OUT p_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*)
    INTO p_count
    FROM company.employees
    WHERE dept_id = p_dept_id
      AND status  = 'active';
END;
$$;

DO $$
DECLARE v_count INT;
BEGIN
    CALL company.get_dept_headcount(1, v_count);
    RAISE NOTICE 'Dept 1 active headcount: %', v_count;
END;
$$;


-- 1f. Archive + delete in one transaction
CREATE TABLE IF NOT EXISTS company.employees_archive (
    LIKE company.employees INCLUDING ALL,
    archived_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE company.archive_inactive_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INT;
BEGIN
    INSERT INTO company.employees_archive
    SELECT *, NOW()
    FROM company.employees
    WHERE status = 'inactive';

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    DELETE FROM company.employees WHERE status = 'inactive';

    RAISE NOTICE '% inactive employees archived and removed.', v_rows;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

CALL company.archive_inactive_employees();


-- ---------------------------------------------------------------
-- SECTION 2: MATERIALIZED VIEWS
-- ---------------------------------------------------------------

-- 2a. Department salary summary
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
LEFT JOIN company.employees e
    ON d.dept_id = e.dept_id AND e.status = 'active'
GROUP BY d.dept_id, d.dept_name
WITH DATA;

SELECT * FROM company.dept_salary_summary ORDER BY total_salary_cost DESC NULLS LAST;


-- 2b. Add unique index — required for CONCURRENTLY refresh
CREATE UNIQUE INDEX idx_dept_salary_summary_dept_id
    ON company.dept_salary_summary (dept_id);

-- Now CONCURRENTLY is possible (no read lock during refresh)
REFRESH MATERIALIZED VIEW CONCURRENTLY company.dept_salary_summary;


-- 2c. Department headcount MV
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


-- 2d. Top earners MV
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

SELECT * FROM company.top_earners_mv;

-- Apply 20% raise to Engineering (dept_id = 1) then refresh
UPDATE company.employees SET salary = salary * 1.20 WHERE dept_id = 1 AND status = 'active';
REFRESH MATERIALIZED VIEW company.top_earners_mv;
SELECT * FROM company.top_earners_mv;


-- 2e. Monthly hire report MV
CREATE MATERIALIZED VIEW company.monthly_hire_report AS
SELECT
    DATE_TRUNC('month', hire_date) AS hire_month,
    d.dept_name,
    COUNT(*)                       AS hires
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
GROUP BY DATE_TRUNC('month', hire_date), d.dept_name
ORDER BY hire_month DESC
WITH DATA;

SELECT * FROM company.monthly_hire_report;


-- 2f. Refresh log table + centralized refresh procedure
CREATE TABLE IF NOT EXISTS company.refresh_log (
    log_id      SERIAL PRIMARY KEY,
    view_name   VARCHAR(200) NOT NULL,
    refreshed_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE company.run_daily_refresh()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW company.dept_salary_summary;
    INSERT INTO company.refresh_log (view_name) VALUES ('company.dept_salary_summary');

    REFRESH MATERIALIZED VIEW company.dept_headcount_mv;
    INSERT INTO company.refresh_log (view_name) VALUES ('company.dept_headcount_mv');

    REFRESH MATERIALIZED VIEW company.monthly_hire_report;
    INSERT INTO company.refresh_log (view_name) VALUES ('company.monthly_hire_report');

    RAISE NOTICE 'All materialized views refreshed.';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

CALL company.run_daily_refresh();
SELECT * FROM company.refresh_log ORDER BY refreshed_at DESC;


-- ---------------------------------------------------------------
-- SECTION 3: SEQUENCES
-- ---------------------------------------------------------------

-- 3a. Basic sequence
CREATE SEQUENCE IF NOT EXISTS company.batch_run_seq
    START WITH   1
    INCREMENT BY 1
    NO CYCLE;

-- Generate 3 batch IDs
SELECT nextval('company.batch_run_seq') AS batch_id;  -- 1
SELECT nextval('company.batch_run_seq') AS batch_id;  -- 2
SELECT nextval('company.batch_run_seq') AS batch_id;  -- 3

-- Check last value (session-scoped)
SELECT lastval() AS last_batch_id;


-- 3b. Use sequence as table default
CREATE TABLE IF NOT EXISTS company.pipeline_runs (
    run_id        BIGINT      DEFAULT nextval('company.batch_run_seq') PRIMARY KEY,
    pipeline_name VARCHAR(200) NOT NULL,
    status        VARCHAR(50)  DEFAULT 'running',
    started_at    TIMESTAMP    DEFAULT NOW()
);

INSERT INTO company.pipeline_runs (pipeline_name) VALUES
    ('load_employees'),
    ('load_departments'),
    ('refresh_marts');

SELECT * FROM company.pipeline_runs ORDER BY run_id;


-- 3c. Custom sequence — invoice numbers starting at 1001
CREATE SEQUENCE IF NOT EXISTS company.invoice_number_seq
    START WITH   1001
    INCREMENT BY 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS company.invoices (
    invoice_id    BIGINT       DEFAULT nextval('company.invoice_number_seq') PRIMARY KEY,
    customer_name VARCHAR(200) NOT NULL,
    total_amount  NUMERIC(12,2) CHECK (total_amount >= 0),
    created_at    TIMESTAMP    DEFAULT NOW()
);

INSERT INTO company.invoices (customer_name, total_amount) VALUES
    ('Acme Corp',    15000.00),
    ('Beta Ltd',      8750.50),
    ('Gamma Pvt',    22000.00);

SELECT * FROM company.invoices;


-- 3d. Sequence with custom increment — order ref numbers (5000, 5005, 5010, ...)
CREATE SEQUENCE IF NOT EXISTS company.order_ref_seq
    START WITH   5000
    INCREMENT BY 5
    NO CYCLE;

SELECT nextval('company.order_ref_seq');  -- 5000
SELECT nextval('company.order_ref_seq');  -- 5005
SELECT nextval('company.order_ref_seq');  -- 5010
SELECT nextval('company.order_ref_seq');  -- 5015


-- 3e. Shared sequence across two tables (globally unique event IDs)
CREATE SEQUENCE IF NOT EXISTS company.global_event_seq START 1;

CREATE TABLE IF NOT EXISTS company.login_events (
    event_id    BIGINT DEFAULT nextval('company.global_event_seq') PRIMARY KEY,
    user_id     INT,
    event_type  VARCHAR(50) DEFAULT 'LOGIN',
    occurred_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS company.purchase_events (
    event_id    BIGINT DEFAULT nextval('company.global_event_seq') PRIMARY KEY,
    user_id     INT,
    event_type  VARCHAR(50) DEFAULT 'PURCHASE',
    amount      NUMERIC(10,2),
    occurred_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO company.login_events    (user_id) VALUES (101), (102);
INSERT INTO company.purchase_events (user_id, amount) VALUES (101, 500.00), (103, 1200.00);

-- All event_ids are globally unique
SELECT 'login'    AS source, event_id FROM company.login_events
UNION ALL
SELECT 'purchase' AS source, event_id FROM company.purchase_events
ORDER BY event_id;


-- 3f. setval — re-seed after bulk migration
-- Scenario: 50,000 rows imported manually with IDs 1-50000, sequence still at 1
SELECT setval('company.batch_run_seq', 50000);

-- Next call returns 50001 — no conflict
SELECT nextval('company.batch_run_seq');


-- 3g. Demonstrate sequences do NOT roll back
BEGIN;
SELECT nextval('company.batch_run_seq') AS next_val;  -- advances the sequence
ROLLBACK;
-- Sequence is still advanced — gap is permanent and expected
SELECT nextval('company.batch_run_seq') AS next_val_after_rollback;


-- 3h. Procedure with OUT parameter returning a sequence-based batch ID
CREATE OR REPLACE PROCEDURE company.start_batch_run(
    p_pipeline_name VARCHAR,
    OUT p_run_id    BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_run_id := nextval('company.batch_run_seq');

    INSERT INTO company.pipeline_runs (run_id, pipeline_name)
    VALUES (p_run_id, p_pipeline_name);

    RAISE NOTICE 'Batch run started — run_id: %, pipeline: %', p_run_id, p_pipeline_name;
END;
$$;

DO $$
DECLARE v_run_id BIGINT;
BEGIN
    CALL company.start_batch_run('load_orders', v_run_id);
    RAISE NOTICE 'Captured run_id: %', v_run_id;
END;
$$;


-- ---------------------------------------------------------------
-- BONUS: DATA WAREHOUSE LOAD TRACKING PATTERN
-- ---------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS dw;

CREATE SEQUENCE IF NOT EXISTS dw.load_run_seq START 1 INCREMENT 1;

CREATE TABLE IF NOT EXISTS dw.load_runs (
    run_id         BIGINT       DEFAULT nextval('dw.load_run_seq') PRIMARY KEY,
    table_name     VARCHAR(200) NOT NULL,
    rows_inserted  BIGINT       DEFAULT 0,
    rows_updated   BIGINT       DEFAULT 0,
    started_at     TIMESTAMP    DEFAULT NOW(),
    completed_at   TIMESTAMP,
    status         VARCHAR(50)  DEFAULT 'running'
);

-- Start a load run, return the run_id
CREATE OR REPLACE PROCEDURE dw.start_load_run(
    p_table_name VARCHAR,
    OUT p_run_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_run_id := nextval('dw.load_run_seq');

    INSERT INTO dw.load_runs (run_id, table_name)
    VALUES (p_run_id, p_table_name);

    RAISE NOTICE 'Load run started — run_id: %, table: %', p_run_id, p_table_name;
END;
$$;

-- Complete a load run with final stats
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
        completed_at  = NOW(),
        status        = 'completed'
    WHERE run_id = p_run_id;

    RAISE NOTICE 'Load run % completed — inserted: %, updated: %.', p_run_id, p_rows_inserted, p_rows_updated;
    COMMIT;
END;
$$;

-- Daily load summary materialized view
CREATE MATERIALIZED VIEW dw.load_summary_mv AS
SELECT
    table_name,
    DATE_TRUNC('day', started_at) AS load_date,
    COUNT(*)                       AS total_runs,
    SUM(rows_inserted)             AS total_inserted,
    SUM(rows_updated)              AS total_updated
FROM dw.load_runs
WHERE status = 'completed'
GROUP BY table_name, DATE_TRUNC('day', started_at)
ORDER BY load_date DESC, total_inserted DESC
WITH DATA;

-- Simulate a full load run
DO $$
DECLARE v_run_id BIGINT;
BEGIN
    CALL dw.start_load_run('fact_orders', v_run_id);
    -- ... pipeline loads data ...
    CALL dw.complete_load_run(v_run_id, 15000, 3200);
END;
$$;

REFRESH MATERIALIZED VIEW dw.load_summary_mv;
SELECT * FROM dw.load_summary_mv;


-- ---------------------------------------------------------------
-- CLEANUP (run to reset for re-practice)
-- ---------------------------------------------------------------
-- DROP SCHEMA company CASCADE;
-- DROP SCHEMA dw CASCADE;
