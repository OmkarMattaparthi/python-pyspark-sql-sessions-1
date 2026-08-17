# Day 1 Notes — SQL Overview: Database Objects, Query Types & Keys

## Topics Covered
1. SQL Architecture — Server → Database → Schema → Objects
2. Database Objects — Tables, Views, Functions, Triggers
3. Constraints
4. Types of SQL Queries — DDL, DML, DCL, TCL, DQL
5. Key Types — Primary, Foreign, Unique, Composite, Surrogate, Candidate

---

## 1. SQL Architecture

SQL follows a **hierarchical structure**:

```
Server
 └── Database
      └── Schema
           ├── Tables
           ├── Views
           ├── Functions
           ├── Triggers
           └── Procedures
```

### Server
- The database engine that manages all databases (e.g., PostgreSQL server, MySQL server).
- Handles connections, authentication, memory, and query execution.

### Database
- A logical container that holds all related data objects.
- One server can host multiple databases (e.g., `sales_db`, `hr_db`, `analytics_db`).

```sql
-- Create a database
CREATE DATABASE company_db;

-- Switch to a database (PostgreSQL)
\c company_db

-- List all databases (PostgreSQL)
\l
```

### Schema
- A **namespace** inside a database that groups related objects together.
- Default schema in PostgreSQL is `public`.
- Helps organize large databases (e.g., `sales.orders`, `hr.employees`).

```sql
-- Create a schema
CREATE SCHEMA hr;
CREATE SCHEMA sales;

-- Reference an object inside a schema
SELECT * FROM hr.employees;
SELECT * FROM sales.orders;

-- List schemas (PostgreSQL)
\dn
```

### Why Schema matters in Data Engineering
- In data warehouses (Snowflake, BigQuery, Redshift) schemas separate raw, staging, and curated layers.
- Example: `raw.orders` → `staging.orders` → `marts.orders`

---

## 2. Database Objects

### Tables
- The **core object** — stores data in rows and columns.
- Each column has a defined data type.

```sql
CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    dept_id    INT,
    salary     NUMERIC(10, 2),
    hire_date  DATE
);
```

### Views
- A **saved SELECT query** stored as a virtual table.
- Does not store data itself — runs the underlying query each time.
- Used to simplify complex queries or restrict column access.

```sql
CREATE VIEW active_employees AS
SELECT emp_id, first_name, last_name, salary
FROM employees
WHERE status = 'active';

-- Query the view like a table
SELECT * FROM active_employees;
```

**Types of Views:**
| Type | Description |
|------|-------------|
| Simple View | Based on one table, no aggregations |
| Complex View | Joins, subqueries, aggregations |
| Materialized View | Physically stores the result — refreshed on demand (faster reads) |

### Functions
- Reusable blocks of SQL/procedural logic that **return a value**.
- Built-in functions: `SUM()`, `COUNT()`, `UPPER()`, `NOW()`
- Custom (user-defined) functions:

```sql
CREATE OR REPLACE FUNCTION get_full_name(fname VARCHAR, lname VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN fname || ' ' || lname;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT get_full_name('John', 'Doe');  -- 'John Doe'
```

### Triggers
- Automatically execute SQL when an **event** occurs on a table (INSERT, UPDATE, DELETE).
- Used for auditing, data validation, or cascading updates.

```sql
-- Example: log every salary change
CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO salary_audit(emp_id, old_salary, new_salary, changed_at)
    VALUES (OLD.emp_id, OLD.salary, NEW.salary, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER salary_change_trigger
AFTER UPDATE OF salary ON employees
FOR EACH ROW EXECUTE FUNCTION log_salary_change();
```

**Trigger Timing:**
| Timing | When it fires |
|--------|---------------|
| BEFORE | Before the row is written |
| AFTER | After the row is written |
| INSTEAD OF | Used on views to intercept the operation |

---

## 3. Constraints

Constraints **enforce rules** on data at the column or table level.

| Constraint | Purpose | Example |
|------------|---------|---------|
| `PRIMARY KEY` | Uniquely identifies each row, NOT NULL + UNIQUE | `emp_id SERIAL PRIMARY KEY` |
| `FOREIGN KEY` | Links to a primary key in another table | `dept_id INT REFERENCES departments(dept_id)` |
| `UNIQUE` | No duplicate values in the column | `email VARCHAR UNIQUE` |
| `NOT NULL` | Column cannot be empty | `first_name VARCHAR NOT NULL` |
| `CHECK` | Value must satisfy a condition | `salary NUMERIC CHECK (salary > 0)` |
| `DEFAULT` | Uses a default value if none provided | `status VARCHAR DEFAULT 'active'` |

```sql
CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    email      VARCHAR(100) UNIQUE NOT NULL,
    salary     NUMERIC(10,2) CHECK (salary > 0),
    dept_id    INT REFERENCES departments(dept_id),
    status     VARCHAR(20) DEFAULT 'active'
);
```

---

## 4. Types of SQL Queries

### DDL — Data Definition Language
Defines and modifies the **structure** of database objects.

| Command | Purpose |
|---------|---------|
| `CREATE` | Create a new object (table, schema, view, index) |
| `ALTER` | Modify an existing object |
| `DROP` | Delete an object permanently |
| `TRUNCATE` | Remove all rows from a table (keeps structure) |
| `RENAME` | Rename an object |

```sql
-- CREATE
CREATE TABLE departments (
    dept_id   SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- ALTER — add a column
ALTER TABLE employees ADD COLUMN phone VARCHAR(20);

-- ALTER — modify a column type
ALTER TABLE employees ALTER COLUMN phone TYPE VARCHAR(15);

-- DROP
DROP TABLE IF EXISTS temp_table;

-- TRUNCATE — clears all rows, faster than DELETE
TRUNCATE TABLE employees;

-- RENAME
ALTER TABLE employees RENAME TO staff;
```

> **Key point:** DDL commands are **auto-committed** in most databases — they cannot be rolled back.

---

### DML — Data Manipulation Language
Manipulates the **data** inside tables.

| Command | Purpose |
|---------|---------|
| `INSERT` | Add new rows |
| `UPDATE` | Modify existing rows |
| `DELETE` | Remove specific rows |
| `MERGE` | Upsert — insert or update based on a condition |

```sql
-- INSERT single row
INSERT INTO departments (dept_name) VALUES ('Engineering');

-- INSERT multiple rows
INSERT INTO employees (first_name, last_name, dept_id, salary)
VALUES
    ('Alice', 'Smith', 1, 75000),
    ('Bob',   'Jones', 2, 82000),
    ('Carol', 'Lee',   1, 91000);

-- UPDATE
UPDATE employees
SET salary = salary * 1.10
WHERE dept_id = 1;

-- DELETE
DELETE FROM employees
WHERE status = 'inactive';

-- MERGE (upsert — PostgreSQL 15+ syntax)
MERGE INTO employees AS target
USING new_employees AS source
ON target.emp_id = source.emp_id
WHEN MATCHED THEN
    UPDATE SET salary = source.salary
WHEN NOT MATCHED THEN
    INSERT (emp_id, first_name, salary) VALUES (source.emp_id, source.first_name, source.salary);
```

---

### DQL — Data Query Language
Used to **retrieve** data.

| Command | Purpose |
|---------|---------|
| `SELECT` | Fetch rows from one or more tables |

```sql
-- Basic SELECT
SELECT first_name, last_name, salary
FROM employees
WHERE dept_id = 1
ORDER BY salary DESC;

-- SELECT with alias
SELECT
    first_name || ' ' || last_name AS full_name,
    salary,
    salary * 12 AS annual_salary
FROM employees;
```

---

### DCL — Data Control Language
Controls **access** and **permissions**.

| Command | Purpose |
|---------|---------|
| `GRANT` | Give a user/role permission to perform an action |
| `REVOKE` | Remove a permission from a user/role |

```sql
-- Grant SELECT permission on a table
GRANT SELECT ON employees TO analyst_user;

-- Grant all privileges on a schema
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dev_user;

-- Revoke a permission
REVOKE DELETE ON employees FROM analyst_user;
```

---

### TCL — Transaction Control Language
Manages **transactions** — groups of DML statements treated as one unit.

| Command | Purpose |
|---------|---------|
| `BEGIN` / `START TRANSACTION` | Start a transaction block |
| `COMMIT` | Save all changes permanently |
| `ROLLBACK` | Undo all changes since last BEGIN |
| `SAVEPOINT` | Set a point to partially rollback to |
| `RELEASE SAVEPOINT` | Remove a savepoint |

```sql
BEGIN;

UPDATE accounts SET balance = balance - 5000 WHERE account_id = 101;
UPDATE accounts SET balance = balance + 5000 WHERE account_id = 202;

-- If both succeed, commit
COMMIT;

-- If something goes wrong, rollback
-- ROLLBACK;
```

**ACID Properties (what transactions guarantee):**
| Property | Meaning |
|----------|---------|
| **A**tomicity | All steps succeed or all are rolled back |
| **C**onsistency | Data always moves from one valid state to another |
| **I**solation | Concurrent transactions don't interfere with each other |
| **D**urability | Committed data survives crashes |

---

## 5. Key Types

### Primary Key (PK)
- Uniquely identifies each row in a table.
- Cannot be NULL, cannot be duplicated.
- Every table should have one.

```sql
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,   -- auto-increment integer PK
    ...
);
```

### Foreign Key (FK)
- Links a column in one table to the **Primary Key** of another.
- Enforces **referential integrity** — you can't reference a row that doesn't exist.

```sql
CREATE TABLE orders (
    order_id  SERIAL PRIMARY KEY,
    emp_id    INT REFERENCES employees(emp_id),   -- FK to employees
    order_date DATE
);
```

**FK behavior on delete:**
| Option | What happens when the parent row is deleted |
|--------|---------------------------------------------|
| `RESTRICT` | Prevents deletion if child rows exist |
| `CASCADE` | Deletes all child rows automatically |
| `SET NULL` | Sets the FK column to NULL in child rows |
| `SET DEFAULT` | Sets the FK column to its default value |

### Unique Key
- Ensures no duplicate values in a column (or combination of columns).
- Unlike PK, a table can have **multiple** unique keys, and they **can** allow NULL (one per column).

```sql
ALTER TABLE employees ADD CONSTRAINT uq_email UNIQUE (email);
```

### Composite Key
- A **Primary Key or Unique Key made of two or more columns**.
- Used when no single column uniquely identifies a row.

```sql
CREATE TABLE order_items (
    order_id   INT,
    product_id INT,
    quantity   INT,
    PRIMARY KEY (order_id, product_id)  -- composite PK
);
```

### Candidate Key
- Any column (or set of columns) that **could** serve as a Primary Key — it's unique and not null.
- From all candidate keys, one is chosen as the PK; the rest become **alternate keys**.

```sql
-- employees table: both emp_id and email are candidate keys
-- emp_id is chosen as PK; email becomes an alternate/unique key
```

### Surrogate Key
- An **artificial key** generated by the database (not derived from business data).
- `SERIAL` / `BIGSERIAL` / `UUID` in PostgreSQL are surrogate keys.
- Preferred over natural keys in data warehouses (stable, never changes).

```sql
emp_id UUID DEFAULT gen_random_uuid() PRIMARY KEY   -- surrogate key
```

### Natural Key
- A key **derived from real-world business data** (e.g., SSN, email, passport number).
- Risky: business data can change, making the key unstable.

### Super Key
- Any set of columns that uniquely identifies a row — including columns that are redundant.
- A candidate key is the **minimal** super key (no redundant columns).

---

## Key Comparison Summary

| Key Type | Null Allowed | Duplicates | Count per Table |
|----------|-------------|------------|-----------------|
| Primary Key | No | No | 1 |
| Foreign Key | Yes (if no NOT NULL) | Yes | Many |
| Unique Key | Yes (one NULL) | No | Many |
| Composite Key | Depends on each column | Defined by combination | Many |
| Surrogate Key | No | No | Usually 1 (as PK) |
| Candidate Key | No | No | Many (one becomes PK) |

---

## 6. DE Relevance Summary

| Concept | Data Engineering Use |
|---------|---------------------|
| Schema separation | Raw / Staging / Marts layers in data warehouses |
| Views | Expose clean datasets to BI tools without exposing raw tables |
| Materialized Views | Pre-aggregate expensive queries in Redshift/Snowflake |
| Triggers | Audit logs, CDC (Change Data Capture) |
| Constraints | Data quality enforcement at the database level |
| DDL | Pipeline setup — creating tables, schemas, partitions |
| DML | Loading, updating, and merging data in pipelines |
| TCL | Ensuring atomic batch loads — all rows commit or none do |
| Surrogate Keys | Stable join keys in star schema fact/dimension tables |
| Foreign Keys | Referential integrity in normalized operational databases |
