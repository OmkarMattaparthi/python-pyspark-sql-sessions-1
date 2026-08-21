# Day 3 Notes — SQL JOINs: INNER, LEFT, RIGHT, FULL, SELF, CROSS

## Topics Covered
1. What is a JOIN and why it exists
2. INNER JOIN — only matching rows
3. LEFT JOIN — all left rows + matching right rows
4. RIGHT JOIN — all right rows + matching left rows
5. FULL OUTER JOIN — all rows from both sides
6. SELF JOIN — a table joined to itself
7. CROSS JOIN — cartesian product
8. Multiple JOINs — chaining 3+ tables
9. JOIN with filters, aggregation, and CASE
10. Common mistakes and NULL behavior in JOINs

---

## 1. What is a JOIN?

Tables in a relational database are split to avoid duplication (normalization).
A JOIN **combines rows from two or more tables** based on a related column — usually a foreign key.

```
employees table         departments table
-----------------       -----------------
emp_id | dept_id        dept_id | dept_name
   1   |    1              1    | Engineering
   2   |    2              2    | Marketing
   3   |    1              3    | HR
```

Without a JOIN you'd need two queries and manual matching.
A JOIN does it in one query and lets the database use indexes.

### JOIN Syntax
```sql
SELECT columns
FROM   left_table  alias1
JOIN   right_table alias2  ON alias1.key = alias2.key;
```

- `left_table` — the table in FROM
- `right_table` — the table in JOIN
- `ON` — the condition that links the two tables (usually FK = PK)
- Aliases (`e`, `d`) keep queries short when referencing columns

---

## 2. INNER JOIN

Returns **only rows that have a match on both sides**.
Rows from either table with no match are excluded.

```
employees: emp 4 has dept_id = 99 (no matching dept) → excluded
departments: dept HR has no employees → excluded
```

```sql
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    d.dept_name,
    e.salary
FROM company.employees   e
INNER JOIN company.departments d ON e.dept_id = d.dept_id;

-- INNER is optional — plain JOIN defaults to INNER JOIN
FROM company.employees e
JOIN company.departments d ON e.dept_id = d.dept_id;
```

### Venn diagram
```
  employees   departments
  [  | ### |  ]
       ^^^
   only the overlap (matching dept_id)
```

### When to use INNER JOIN
- When you only want rows that are fully linked (no orphans)
- Most common join type in analytics and reporting

---

## 3. LEFT JOIN (LEFT OUTER JOIN)

Returns **all rows from the left table** (FROM table), plus matching rows from the right table.
Where there is no match on the right, right-side columns come back as `NULL`.

```sql
SELECT
    e.emp_id,
    e.first_name,
    d.dept_name           -- NULL if employee has no dept
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id;
```

### Venn diagram
```
  employees   departments
  [######|###|  ]
   ^^^^^^^^^^^
   all employees, matched dept or NULL
```

### Finding rows with NO match (anti-join pattern)
```sql
-- Employees who have no department assigned
SELECT e.emp_id, e.first_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;   -- right side is NULL → no match found
```

### When to use LEFT JOIN
- When you want all records from one table regardless of whether the other table has data
- Finding orphaned records (unmatched rows)
- Reporting where some employees may not have a manager, a department, etc.

---

## 4. RIGHT JOIN (RIGHT OUTER JOIN)

Returns **all rows from the right table** (JOIN table), plus matching rows from the left table.
Where there is no match on the left, left-side columns are `NULL`.

```sql
-- All departments, even those with no employees
SELECT
    d.dept_id,
    d.dept_name,
    e.first_name          -- NULL if dept has no employees
FROM company.employees   e
RIGHT JOIN company.departments d ON e.dept_id = d.dept_id;
```

### Venn diagram
```
  employees   departments
  [  |###|######]
         ^^^^^^^^
   all departments, matched employees or NULL
```

> **Tip:** A RIGHT JOIN is always rewritable as a LEFT JOIN by swapping the table order.
> Most developers prefer LEFT JOIN for consistency.

```sql
-- These two queries return the same result:
FROM employees e RIGHT JOIN departments d ON e.dept_id = d.dept_id
FROM departments d LEFT JOIN employees e ON e.dept_id = d.dept_id
```

---

## 5. FULL OUTER JOIN

Returns **all rows from both tables**.
Where there is no match, the unmatched side's columns are `NULL`.

```sql
-- All employees AND all departments, regardless of whether they match
SELECT
    e.emp_id,
    e.first_name,
    d.dept_id,
    d.dept_name
FROM company.employees   e
FULL OUTER JOIN company.departments d ON e.dept_id = d.dept_id;
```

### Venn diagram
```
  employees   departments
  [######|###|######]
   ^^^^^^^^^^^^^^^^^^
   everything from both sides
```

### Finding unmatched rows on EITHER side
```sql
-- Employees with no dept OR departments with no employees
SELECT e.emp_id, e.first_name, d.dept_id, d.dept_name
FROM company.employees   e
FULL OUTER JOIN company.departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL          -- dept has no employees
   OR d.dept_id IS NULL;        -- employee has no dept
```

### When to use FULL OUTER JOIN
- Data reconciliation: compare two systems to find what's missing in either
- Merging datasets from different sources

---

## 6. SELF JOIN

A table joined to **itself**. Uses two aliases to treat the same table as two separate tables.
Used for hierarchical data (employee–manager), comparing rows within the same table.

```sql
-- Employees with their manager's name
-- employees table has a manager_id column that references emp_id in the same table
SELECT
    e.emp_id,
    e.first_name                              AS employee,
    m.first_name                              AS manager
FROM company.employees e
LEFT JOIN company.employees m ON e.manager_id = m.emp_id;
-- LEFT JOIN so employees with no manager (CEO) still appear with NULL as manager
```

### Finding pairs within the same table
```sql
-- Pairs of employees in the same department (non-redundant)
SELECT
    a.first_name AS employee_1,
    b.first_name AS employee_2,
    a.dept_id
FROM company.employees a
JOIN company.employees b
    ON  a.dept_id = b.dept_id
    AND a.emp_id  < b.emp_id;   -- < prevents (Alice,Bob) and (Bob,Alice) both appearing
```

---

## 7. CROSS JOIN

Returns the **Cartesian product** — every row from the left table paired with every row from the right table.
No ON condition needed. If left has 5 rows and right has 4 rows → result has 5 × 4 = 20 rows.

```sql
-- Every employee paired with every department (whether they belong or not)
SELECT e.first_name, d.dept_name
FROM company.employees   e
CROSS JOIN company.departments d;
```

### When CROSS JOIN is useful
- Generating all combinations (e.g. all products × all regions for a sales matrix)
- Pairing a list of dates with a list of categories for a reporting scaffold
- Rarely used directly; most accidental cross joins are bugs from missing ON conditions

```sql
-- Real use: generate a date-department scaffold for a report
SELECT dates.report_date, d.dept_name
FROM (VALUES ('2024-01-01'::DATE), ('2024-01-02'::DATE), ('2024-01-03'::DATE)) AS dates(report_date)
CROSS JOIN company.departments d
ORDER BY dates.report_date, d.dept_name;
```

---

## 8. Multiple JOINs — Chaining 3+ Tables

You can chain as many JOINs as needed. Each JOIN adds another table to the result.
Aliases become critical for readability.

```sql
-- employees → departments → a third table: projects
SELECT
    e.first_name || ' ' || e.last_name  AS employee,
    d.dept_name,
    p.project_name,
    ep.role
FROM company.employees        e
JOIN company.departments      d  ON e.dept_id    = d.dept_id
JOIN company.employee_projects ep ON e.emp_id    = ep.emp_id
JOIN company.projects          p  ON ep.project_id = p.project_id
WHERE e.status = 'active';
```

### Mix of JOIN types
```sql
-- All departments (even empty ones) with their active employees (if any)
SELECT
    d.dept_name,
    e.first_name,
    e.salary
FROM company.departments d
LEFT JOIN company.employees e
    ON  d.dept_id = e.dept_id
    AND e.status  = 'active'   -- filter inside ON, not WHERE (see Section 10)
ORDER BY d.dept_name, e.salary DESC;
```

---

## 9. JOIN with Aggregation and CASE

JOINs are frequently combined with GROUP BY and CASE.

### Aggregation after JOIN
```sql
-- Headcount and average salary per department (including empty departments)
SELECT
    d.dept_name,
    COUNT(e.emp_id)         AS headcount,       -- COUNT on FK: NULLs not counted
    ROUND(AVG(e.salary), 2) AS avg_salary,
    SUM(e.salary)           AS total_payroll
FROM company.departments d
LEFT JOIN company.employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY total_payroll DESC NULLS LAST;
```

### CASE on a JOINed column
```sql
SELECT
    e.first_name,
    d.dept_name,
    e.salary,
    CASE
        WHEN e.salary > 90000 THEN 'Above budget'
        WHEN e.salary > 70000 THEN 'Within budget'
        ELSE 'Under budget'
    END AS budget_status
FROM company.employees   e
JOIN company.departments d ON e.dept_id = d.dept_id;
```

---

## 10. Common Mistakes and NULL Behavior

### Mistake 1 — Filter in WHERE vs ON for OUTER JOINs

```sql
-- WRONG: WHERE filter turns LEFT JOIN into INNER JOIN
-- Departments with no employees have d.dept_name = NULL in result,
-- then WHERE d.dept_name = 'Engineering' filters them ALL out.
SELECT e.*, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering';   -- filters out NULL right-side rows!

-- CORRECT: put the right-side filter inside ON
SELECT e.*, d.dept_name
FROM company.employees   e
LEFT JOIN company.departments d
    ON  e.dept_id  = d.dept_id
    AND d.dept_name = 'Engineering';  -- unmatched employees still appear with NULL dept_name
```

### Mistake 2 — Forgetting the ON condition (accidental CROSS JOIN)

```sql
-- Missing ON — produces a cartesian product (all × all rows)
SELECT * FROM company.employees, company.departments;  -- old-style implicit join = CROSS JOIN
SELECT * FROM company.employees JOIN company.departments;  -- syntax error in PostgreSQL
```

### Mistake 3 — COUNT(*) vs COUNT(column) after LEFT JOIN

```sql
-- COUNT(*) counts ALL rows including NULLs from the right side
-- COUNT(e.emp_id) counts only matched rows (NULLs not counted)
SELECT d.dept_name,
       COUNT(*)        AS wrong_headcount,   -- counts the NULL rows too
       COUNT(e.emp_id) AS correct_headcount  -- NULLs excluded
FROM company.departments d
LEFT JOIN company.employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name;
```

### Mistake 4 — Duplicate rows from one-to-many joins

```sql
-- If one employee has 3 projects, that employee appears 3 times after the join.
-- Always check row counts before and after joining.
SELECT COUNT(*) FROM company.employees;              -- 5
SELECT COUNT(*) FROM company.employees
JOIN company.employee_projects ep ON employees.emp_id = ep.emp_id;  -- may be > 5
```

---

## JOIN Type Summary

| JOIN Type | Left rows | Right rows | On no match |
|-----------|-----------|------------|-------------|
| INNER JOIN | Only matched | Only matched | Row excluded |
| LEFT JOIN | All | Only matched | Right side = NULL |
| RIGHT JOIN | Only matched | All | Left side = NULL |
| FULL OUTER JOIN | All | All | Unmatched side = NULL |
| SELF JOIN | Same table twice with aliases | — | Depends on INNER/LEFT |
| CROSS JOIN | All × All | No ON needed | Always included |

---

## DE Relevance Summary

| Concept | Data Engineering Use |
|---------|---------------------|
| INNER JOIN | Fact-to-dimension joins in star schema queries |
| LEFT JOIN | Including all source records even if no lookup match (load with nulls) |
| LEFT JOIN anti-join | Finding new records not yet in the target (incremental loads) |
| FULL OUTER JOIN | Reconciling two source systems or comparing staging vs target |
| SELF JOIN | Org chart / hierarchy traversal, comparing same-day events |
| CROSS JOIN | Building date-spine × dimension scaffolds for time-series reporting |
| Filter in ON vs WHERE | Preserving outer join semantics in complex pipeline queries |
| COUNT(col) not COUNT(*) | Correct aggregation after LEFT JOINs in reporting queries |
