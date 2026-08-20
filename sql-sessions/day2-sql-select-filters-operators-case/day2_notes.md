# Day 2 Notes — SQL SELECT: Filters, Operators & CASE

## Topics Covered
1. SELECT — `*` vs specific columns, aliases, expressions
2. WHERE — comparison operators
3. Logical operators — AND, OR, NOT
4. Range & list filters — BETWEEN, IN, NOT IN
5. Pattern matching — LIKE, ILIKE
6. NULL handling — IS NULL, IS NOT NULL
7. EXISTS / NOT EXISTS
8. CASE — simple, searched, in SELECT / WHERE / aggregation

---

## 1. SELECT — Choosing Columns

### SELECT * (All Columns)
Returns every column in the order they were defined in the table.

```sql
SELECT * FROM company.employees;
```

**When to avoid `*`:**
- In production queries — adding a new column breaks downstream code that expects a fixed column order.
- In pipelines — always name columns explicitly so schema changes don't silently break transforms.
- In JOINs — `*` across joined tables returns duplicate column names (two `dept_id` columns).

### SELECT Specific Columns
```sql
SELECT emp_id, first_name, last_name, salary
FROM company.employees;
```

### Column Aliases — AS
Rename a column in the result. Does not change the table.
```sql
SELECT
    first_name                      AS first,
    last_name                       AS last,
    salary                          AS monthly_salary,
    salary * 12                     AS annual_salary,
    first_name || ' ' || last_name  AS full_name
FROM company.employees;
```

> `||` is the string concatenation operator in PostgreSQL.

### Expressions in SELECT
Math, string operations, and function calls can be written directly in SELECT.
```sql
SELECT
    emp_id,
    first_name || ' ' || last_name   AS full_name,
    ROUND(salary / 30, 2)            AS daily_rate,
    UPPER(first_name)                AS first_upper,
    LENGTH(email)                    AS email_length,
    CURRENT_DATE - hire_date         AS days_employed
FROM company.employees;
```

### DISTINCT — Remove Duplicates
```sql
-- All unique dept_ids used by employees
SELECT DISTINCT dept_id FROM company.employees;

-- Unique combinations of dept_id and status
SELECT DISTINCT dept_id, status FROM company.employees;
```

### ORDER BY — Sort Results
```sql
SELECT first_name, salary FROM company.employees
ORDER BY salary DESC;           -- highest first

ORDER BY salary ASC;            -- lowest first (ASC is default)
ORDER BY last_name, first_name; -- multi-column sort
ORDER BY 2 DESC;                -- positional: sort by 2nd column in SELECT list
```

### LIMIT and OFFSET — Pagination
```sql
-- Top 5 earners
SELECT * FROM company.employees ORDER BY salary DESC LIMIT 5;

-- Rows 6 to 10 (skip first 5)
SELECT * FROM company.employees ORDER BY salary DESC LIMIT 5 OFFSET 5;
```

---

## 2. WHERE — Row Filtering

`WHERE` filters rows **before** any aggregation. Only rows satisfying the condition are returned.

### Comparison Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equal | `salary = 70000` |
| `<>` or `!=` | Not equal | `status <> 'inactive'` |
| `>` | Greater than | `salary > 80000` |
| `<` | Less than | `salary < 50000` |
| `>=` | Greater than or equal | `salary >= 75000` |
| `<=` | Less than or equal | `salary <= 90000` |

```sql
SELECT * FROM company.employees WHERE salary = 75000;
SELECT * FROM company.employees WHERE dept_id <> 2;
SELECT * FROM company.employees WHERE hire_date < '2022-01-01';
```

---

## 3. Logical Operators — AND, OR, NOT

Combine multiple conditions in WHERE.

### AND — Both conditions must be true
```sql
SELECT * FROM company.employees
WHERE dept_id = 1
  AND status = 'active'
  AND salary > 80000;
```

### OR — At least one condition must be true
```sql
SELECT * FROM company.employees
WHERE dept_id = 1
   OR dept_id = 3;
```

### NOT — Invert a condition
```sql
SELECT * FROM company.employees
WHERE NOT status = 'inactive';
-- Same as: WHERE status <> 'inactive'
```

### Mixing AND and OR — Parentheses matter
```sql
-- (dept 1 OR dept 2) AND salary > 70,000
SELECT * FROM company.employees
WHERE (dept_id = 1 OR dept_id = 2)
  AND salary > 70000;

-- Without parentheses — different meaning because AND binds tighter than OR:
-- dept_id = 1 OR (dept_id = 2 AND salary > 70000)
SELECT * FROM company.employees
WHERE dept_id = 1
   OR dept_id = 2 AND salary > 70000;
```

> **Rule:** `AND` has higher precedence than `OR`. Always use parentheses when mixing both.

---

## 4. BETWEEN, IN, NOT IN

### BETWEEN — Inclusive range filter
Both endpoints are included.
```sql
SELECT * FROM company.employees WHERE salary BETWEEN 60000 AND 90000;
SELECT * FROM company.employees WHERE hire_date BETWEEN '2022-01-01' AND '2023-12-31';
SELECT * FROM company.employees WHERE salary NOT BETWEEN 60000 AND 90000;
```

### IN — Match any value in a list
```sql
SELECT * FROM company.employees WHERE dept_id IN (1, 2, 4);
SELECT * FROM company.employees WHERE status IN ('active', 'on_leave');
```

### NOT IN — Exclude a list of values
```sql
SELECT * FROM company.employees WHERE dept_id NOT IN (2, 3);
```

> **Warning:** `NOT IN` returns **no rows** if the list contains any `NULL`.
> Use `NOT EXISTS` (covered below) when the list comes from a subquery.

---

## 5. LIKE and ILIKE — Pattern Matching

`%` matches any sequence of characters. `_` matches exactly one character.

| Pattern | What it matches |
|---------|----------------|
| `'A%'` | Starts with A |
| `'%son'` | Ends with son |
| `'%lee%'` | Contains lee anywhere |
| `'_lee'` | Any one char then lee |
| `'A__'` | A followed by exactly 2 chars |

```sql
SELECT * FROM company.employees WHERE first_name LIKE 'A%';       -- starts with A
SELECT * FROM company.employees WHERE email LIKE '%company%';      -- contains company
SELECT * FROM company.employees WHERE last_name LIKE '%son';       -- ends with son
SELECT * FROM company.employees WHERE first_name LIKE '_____';     -- exactly 5 chars
SELECT * FROM company.employees WHERE email NOT LIKE '%@company.com';
```

### ILIKE — Case-insensitive (PostgreSQL only)
```sql
-- Matches 'alice', 'Alice', 'ALICE'
SELECT * FROM company.employees WHERE first_name ILIKE 'alice';
```

---

## 6. NULL Handling — IS NULL, IS NOT NULL

`NULL` means unknown/missing. You cannot compare it with `=` or `<>` — those always return `NULL` (not TRUE or FALSE).

```sql
-- Correct
SELECT * FROM company.employees WHERE dept_id IS NULL;
SELECT * FROM company.employees WHERE hire_date IS NOT NULL;

-- Wrong — returns no rows even when NULLs exist
SELECT * FROM company.employees WHERE dept_id = NULL;
```

### COALESCE — Replace NULL with a default
```sql
SELECT dept_name, COALESCE(location, 'No Location') AS location
FROM company.departments;
```

### NULLIF — Return NULL when two values are equal
```sql
-- Prevent division by zero: if headcount is 0, return NULL instead
SELECT dept_name, total_salary / NULLIF(headcount, 0) AS avg_salary
FROM dept_summary;
```

---

## 7. EXISTS and NOT EXISTS

`EXISTS` checks whether a subquery returns **at least one row**.
It stops scanning immediately on the first match — more efficient than `IN` for large subqueries.

### EXISTS
```sql
-- Departments that have at least one active employee
SELECT dept_id, dept_name
FROM company.departments d
WHERE EXISTS (
    SELECT 1
    FROM company.employees e
    WHERE e.dept_id = d.dept_id
      AND e.status = 'active'
);
```

> `SELECT 1` inside EXISTS is the convention — the values returned don't matter, only whether rows exist.

### NOT EXISTS
```sql
-- Departments with NO employees at all
SELECT dept_id, dept_name
FROM company.departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM company.employees e
    WHERE e.dept_id = d.dept_id
);
```

### Why NOT EXISTS is safer than NOT IN
```sql
-- NOT IN breaks if subquery returns any NULL
SELECT * FROM company.employees
WHERE dept_id NOT IN (SELECT dept_id FROM company.departments);
-- If any dept_id in departments is NULL, this returns ZERO rows — silent bug.

-- NOT EXISTS handles NULLs correctly
SELECT * FROM company.employees e
WHERE NOT EXISTS (
    SELECT 1 FROM company.departments d
    WHERE d.dept_id = e.dept_id
);
```

---

## 8. CASE — Conditional Logic

`CASE` is SQL's if/else. Works in `SELECT`, `WHERE`, `ORDER BY`, and `GROUP BY`.

### Simple CASE — one expression matched against values
```sql
SELECT
    emp_id,
    dept_id,
    CASE dept_id
        WHEN 1 THEN 'Engineering'
        WHEN 2 THEN 'Marketing'
        WHEN 3 THEN 'HR'
        ELSE 'Other'
    END AS dept_label
FROM company.employees;
```

### Searched CASE — each branch has its own condition
```sql
SELECT
    emp_id,
    first_name,
    salary,
    CASE
        WHEN salary >= 90000 THEN 'Senior'
        WHEN salary >= 70000 THEN 'Mid'
        WHEN salary >= 50000 THEN 'Junior'
        ELSE 'Entry'
    END AS salary_band
FROM company.employees;
```

> CASE evaluates branches **top to bottom** and returns on the first match — order matters.

### CASE in ORDER BY — custom sort order
```sql
SELECT emp_id, first_name, status
FROM company.employees
ORDER BY
    CASE status
        WHEN 'active'   THEN 1
        WHEN 'on_leave' THEN 2
        WHEN 'inactive' THEN 3
        ELSE 4
    END;
```

### CASE in WHERE — condition depends on another column
```sql
SELECT * FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id
WHERE
    CASE d.dept_name
        WHEN 'Engineering' THEN e.salary > 80000
        ELSE e.salary > 60000
    END;
```

### CASE inside aggregate — conditional counting (pivot pattern)
```sql
SELECT
    dept_id,
    COUNT(*)                                           AS total,
    COUNT(CASE WHEN status = 'active'   THEN 1 END)   AS active_count,
    COUNT(CASE WHEN status = 'inactive' THEN 1 END)   AS inactive_count,
    SUM(CASE WHEN status = 'active'     THEN salary END) AS active_payroll
FROM company.employees
GROUP BY dept_id;
```

---

## Full Clause Execution Order

```
FROM       → which table(s)
WHERE      → filter rows before grouping
GROUP BY   → group filtered rows
HAVING     → filter groups
SELECT     → compute columns / expressions / CASE
DISTINCT   → remove duplicates
ORDER BY   → sort
LIMIT      → restrict row count
OFFSET     → skip rows
```

Even though you write SELECT first, it runs **after** FROM and WHERE.
This is why you cannot reference a SELECT alias in a WHERE clause — WHERE runs before SELECT.

---

## DE Relevance Summary

| Concept | Data Engineering Use |
|---------|---------------------|
| Specific columns over `*` | Prevents schema drift breaking downstream pipelines |
| AND / OR / NOT | Row-level filtering in ETL source queries |
| BETWEEN | Date-range incremental loads (`WHERE event_date BETWEEN ...`) |
| IN | Filtering on lookup/allow-lists loaded from config tables |
| NOT EXISTS | Detecting orphaned or unmatched records before load |
| IS NULL / IS NOT NULL | Data quality checks, missing-value detection before transform |
| LIKE | Filename pattern matching, log category filtering |
| CASE in SELECT | Creating derived classification columns in staging transforms |
| CASE in aggregation | Pivot-style breakdowns without a PIVOT clause |
| COALESCE | Filling NULLs before writing to target tables |
