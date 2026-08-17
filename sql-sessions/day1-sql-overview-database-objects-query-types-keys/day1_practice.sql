-- =============================================================
-- Day 1 Practice — SQL Overview: Database Objects, Query Types & Keys
-- =============================================================


-- ---------------------------------------------------------------
-- SECTION 1: DATABASE & SCHEMA SETUP
-- ---------------------------------------------------------------

-- Create the database (run outside of a transaction block)
-- CREATE DATABASE company_db;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS company;
CREATE SCHEMA IF NOT EXISTS hr;
CREATE SCHEMA IF NOT EXISTS sales;


-- ---------------------------------------------------------------
-- SECTION 2: DDL — CREATE TABLES
-- ---------------------------------------------------------------

-- Departments table
CREATE TABLE company.departments (
    dept_id   SERIAL          PRIMARY KEY,
    dept_name VARCHAR(100)    NOT NULL,
    location  VARCHAR(100)
);

-- Employees table — demonstrates most constraint types
CREATE TABLE company.employees (
    emp_id     SERIAL          PRIMARY KEY,                             -- surrogate key, auto-increment
    first_name VARCHAR(50)     NOT NULL,
    last_name  VARCHAR(50)     NOT NULL,
    email      VARCHAR(100)    UNIQUE NOT NULL,                         -- candidate key → unique constraint
    salary     NUMERIC(10, 2)  CHECK (salary > 0),
    dept_id    INT             REFERENCES company.departments(dept_id)  -- FK with default RESTRICT
                               ON DELETE RESTRICT,
    hire_date  DATE,
    status     VARCHAR(20)     DEFAULT 'active'
);

-- Composite primary key example
CREATE TABLE company.order_items (
    order_id    INT         NOT NULL,
    product_id  INT         NOT NULL,
    quantity    INT         NOT NULL CHECK (quantity >= 1),
    unit_price  NUMERIC(10,2),
    PRIMARY KEY (order_id, product_id)   -- composite PK
);


-- ---------------------------------------------------------------
-- SECTION 3: DDL — ALTER TABLE
-- ---------------------------------------------------------------

-- Add a column
ALTER TABLE company.employees ADD COLUMN phone VARCHAR(20);

-- Rename a column
ALTER TABLE company.employees RENAME COLUMN phone TO mobile;

-- Drop the column
ALTER TABLE company.employees DROP COLUMN mobile;

-- Add a named constraint after table creation
ALTER TABLE company.employees
    ADD CONSTRAINT chk_status CHECK (status IN ('active', 'inactive', 'on_leave'));


-- ---------------------------------------------------------------
-- SECTION 4: DML — INSERT
-- ---------------------------------------------------------------

-- Insert departments
INSERT INTO company.departments (dept_name, location) VALUES
    ('Engineering', 'Pune'),
    ('Marketing',   'Mumbai'),
    ('HR',          'Bangalore');

-- Insert employees
INSERT INTO company.employees (first_name, last_name, email, salary, dept_id, hire_date) VALUES
    ('Alice',  'Smith',  'alice.smith@company.com',  85000.00, 1, '2022-03-15'),
    ('Bob',    'Jones',  'bob.jones@company.com',    72000.00, 2, '2021-07-01'),
    ('Carol',  'Lee',    'carol.lee@company.com',    91000.00, 1, '2023-01-10'),
    ('David',  'Brown',  'david.brown@company.com',  65000.00, 3, '2020-11-20'),
    ('Eve',    'Davis',  'eve.davis@company.com',    55000.00, 2, '2024-06-05');


-- ---------------------------------------------------------------
-- SECTION 5: DML — UPDATE & DELETE
-- ---------------------------------------------------------------

-- Give 15% raise to Engineering (dept_id = 1)
UPDATE company.employees
SET salary = salary * 1.15
WHERE dept_id = 1;

-- Mark an employee as inactive
UPDATE company.employees
SET status = 'inactive'
WHERE emp_id = 5;

-- Delete inactive employees
DELETE FROM company.employees
WHERE status = 'inactive';


-- ---------------------------------------------------------------
-- SECTION 6: DQL — SELECT QUERIES
-- ---------------------------------------------------------------

-- All employees, ordered by salary descending
SELECT *
FROM company.employees
ORDER BY salary DESC;

-- High earners (> 80,000)
SELECT first_name, last_name, salary
FROM company.employees
WHERE salary > 80000
ORDER BY salary DESC;

-- Full name + annual salary calculation
SELECT
    first_name || ' ' || last_name    AS full_name,
    salary                            AS monthly_salary,
    salary * 12                       AS annual_salary
FROM company.employees
WHERE dept_id = 1;

-- Employees hired after 2023-01-01
SELECT first_name, last_name, hire_date
FROM company.employees
WHERE hire_date > '2023-01-01'
ORDER BY hire_date;


-- ---------------------------------------------------------------
-- SECTION 7: VIEWS
-- ---------------------------------------------------------------

-- Simple view: high earners with department name
CREATE OR REPLACE VIEW company.high_earners AS
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    e.salary,
    d.dept_name
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
WHERE e.salary > 80000;

-- Query the view
SELECT * FROM company.high_earners ORDER BY salary DESC;

-- Drop a view
-- DROP VIEW IF EXISTS company.high_earners;


-- ---------------------------------------------------------------
-- SECTION 8: TCL — TRANSACTIONS
-- ---------------------------------------------------------------

-- Successful transaction
BEGIN;

INSERT INTO company.departments (dept_name, location)
    VALUES ('Finance', 'Delhi');

INSERT INTO company.employees (first_name, last_name, email, salary, dept_id, hire_date)
    VALUES ('Frank', 'Wilson', 'frank.wilson@company.com', 78000.00, 4, '2024-08-01');

COMMIT;

-- Transaction with ROLLBACK
BEGIN;

UPDATE company.employees
SET salary = salary * 2
WHERE dept_id = 99;   -- no rows match — still safe to rollback

ROLLBACK;

-- SAVEPOINT example
BEGIN;

INSERT INTO company.departments (dept_name, location) VALUES ('Legal', 'Chennai');
SAVEPOINT after_dept_insert;

INSERT INTO company.employees (first_name, last_name, email, salary, dept_id)
    VALUES ('Grace', 'Taylor', 'grace.taylor@company.com', 69000, 5);

-- Pretend something went wrong — rollback to savepoint
ROLLBACK TO SAVEPOINT after_dept_insert;

-- Only the department insert survives
COMMIT;


-- ---------------------------------------------------------------
-- SECTION 9: DCL — PERMISSIONS
-- ---------------------------------------------------------------

-- Grant read-only access to an analyst role
-- GRANT SELECT ON company.employees TO analyst_user;
-- GRANT SELECT ON company.departments TO analyst_user;

-- Grant insert on a specific table
-- GRANT INSERT ON company.employees TO hr_user;

-- Revoke a permission
-- REVOKE INSERT ON company.employees FROM hr_user;


-- ---------------------------------------------------------------
-- SECTION 10: USER-DEFINED FUNCTION
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION company.get_full_name(fname VARCHAR, lname VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN fname || ' ' || lname;
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT company.get_full_name(first_name, last_name) AS full_name
FROM company.employees;


-- ---------------------------------------------------------------
-- SECTION 11: TRIGGER EXAMPLE
-- ---------------------------------------------------------------

-- Audit table to log salary changes
CREATE TABLE company.salary_audit (
    audit_id   SERIAL PRIMARY KEY,
    emp_id     INT,
    old_salary NUMERIC(10, 2),
    new_salary NUMERIC(10, 2),
    changed_at TIMESTAMP DEFAULT NOW()
);

-- Trigger function
CREATE OR REPLACE FUNCTION company.log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO company.salary_audit (emp_id, old_salary, new_salary)
        VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to employees table
CREATE TRIGGER salary_change_trigger
AFTER UPDATE OF salary ON company.employees
FOR EACH ROW EXECUTE FUNCTION company.log_salary_change();

-- Fire the trigger by updating salary
UPDATE company.employees SET salary = 90000 WHERE emp_id = 1;

-- Check the audit log
SELECT * FROM company.salary_audit;


-- ---------------------------------------------------------------
-- SECTION 12: KEY TYPES DEMONSTRATION
-- ---------------------------------------------------------------

-- Table demonstrating all key types together
CREATE TABLE company.products (
    product_id   SERIAL          PRIMARY KEY,          -- surrogate PK
    sku          VARCHAR(50)     UNIQUE NOT NULL,       -- candidate key (natural, alternate)
    product_name VARCHAR(200)    NOT NULL,
    category_id  INT             REFERENCES company.departments(dept_id),  -- FK
    price        NUMERIC(10, 2)  CHECK (price >= 0)
);

-- Composite key table
CREATE TABLE company.product_warehouse (
    product_id    INT NOT NULL REFERENCES company.products(product_id),
    warehouse_id  INT NOT NULL,
    stock_count   INT DEFAULT 0 CHECK (stock_count >= 0),
    PRIMARY KEY (product_id, warehouse_id)   -- composite PK
);


-- ---------------------------------------------------------------
-- CLEANUP (run to reset for re-practice)
-- ---------------------------------------------------------------
-- DROP SCHEMA company CASCADE;
-- DROP SCHEMA hr CASCADE;
-- DROP SCHEMA sales CASCADE;
