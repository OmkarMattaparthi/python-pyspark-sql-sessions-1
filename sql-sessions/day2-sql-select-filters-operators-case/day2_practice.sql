-- =============================================================
-- Day 2 Practice — SELECT: Filters, Operators & CASE
-- =============================================================
-- Prerequisite: run day1_practice.sql first to create company schema & tables
--
-- Sample data used throughout this file:
--   company.employees  — emp_id, first_name, last_name, email, salary, dept_id, hire_date, status
--   company.departments — dept_id, dept_name, location


-- ===============================================================
-- SECTION 1: SELECT — COLUMNS, ALIASES, EXPRESSIONS
-- ===============================================================
--
-- SELECT decides WHICH columns appear in your result and HOW they look.
-- You can rename columns, compute new values, and apply functions
-- all within the SELECT clause without changing the underlying table.
-- ---------------------------------------------------------------


-- SELECT * — returns every column in the table as-is.
-- Avoid in production: schema changes silently break downstream code.
SELECT * FROM company.employees;


-- SELECT specific columns — safer and more readable.
-- Only the listed columns come back; order in SELECT controls output order.
SELECT emp_id, first_name, last_name, salary
FROM company.employees;


-- AS — alias a column for the output.
-- The alias exists only in the result set; the table column name is unchanged.
-- || is the PostgreSQL string concatenation operator.
SELECT
    first_name                      AS first,
    last_name                       AS last,
    salary                          AS monthly_salary,
    salary * 12                     AS annual_salary,       -- arithmetic directly in SELECT
    first_name || ' ' || last_name  AS full_name            -- string concat
FROM company.employees;


-- Expressions in SELECT — math, functions, date arithmetic all work here.
-- ROUND(x, n)     → round x to n decimal places
-- UPPER(str)      → uppercase the string
-- LENGTH(str)     → number of characters
-- CURRENT_DATE    → today's date; subtracting a DATE gives an integer (days)
SELECT
    emp_id,
    first_name || ' ' || last_name   AS full_name,
    ROUND(salary / 30.0, 2)          AS daily_rate,     -- /30.0 forces decimal division
    UPPER(first_name)                AS first_upper,
    LENGTH(email)                    AS email_length,
    CURRENT_DATE - hire_date         AS days_employed   -- integer: number of days since hire
FROM company.employees;


-- DISTINCT — removes duplicate rows from the result.
-- Works on the entire row: (dept_id=1, status='active') is one unique combination.
SELECT DISTINCT dept_id FROM company.employees;

SELECT DISTINCT dept_id, status FROM company.employees;


-- ORDER BY — controls the sort order of results.
-- DESC = descending (high → low), ASC = ascending (low → high, the default).
-- Multi-column: sort by first column, break ties using the second.
-- Positional (ORDER BY 2) refers to the 2nd column in the SELECT list.
SELECT first_name, last_name, salary
FROM company.employees
ORDER BY salary DESC;

SELECT first_name, last_name, salary
FROM company.employees
ORDER BY last_name ASC, first_name ASC;


-- LIMIT n — return at most n rows.
-- OFFSET n — skip the first n rows (used with LIMIT for pagination).
-- Always pair LIMIT with ORDER BY so results are deterministic.
SELECT first_name, salary
FROM company.employees
ORDER BY salary DESC
LIMIT 5;

-- Page 2: skip the first 5, show the next 5
SELECT first_name, salary
FROM company.employees
ORDER BY salary DESC
LIMIT 5 OFFSET 5;


-- ===============================================================
-- SECTION 2: WHERE — COMPARISON OPERATORS
-- ===============================================================
--
-- WHERE filters rows BEFORE they reach SELECT.
-- Only rows where the condition evaluates to TRUE are kept.
-- NULL comparisons (= NULL, <> NULL) always return NULL, not TRUE/FALSE.
-- Use IS NULL / IS NOT NULL for null checks (Section 6).
-- ---------------------------------------------------------------


-- = checks exact equality (case-sensitive for strings in PostgreSQL)
SELECT * FROM company.employees WHERE salary = 75000;

-- <> and != both mean "not equal" — they are interchangeable in PostgreSQL
SELECT * FROM company.employees WHERE dept_id <> 2;
SELECT * FROM company.employees WHERE dept_id != 2;

-- > greater than
SELECT * FROM company.employees WHERE salary > 80000;

-- < less than
SELECT * FROM company.employees WHERE salary < 50000;

-- >= greater than or equal (includes the boundary value)
SELECT * FROM company.employees WHERE salary >= 75000;

-- <= less than or equal (includes the boundary value)
SELECT * FROM company.employees WHERE salary <= 90000;

-- Date comparisons use ISO format 'YYYY-MM-DD' in single quotes
SELECT * FROM company.employees WHERE hire_date < '2022-01-01';
SELECT * FROM company.employees WHERE hire_date >= '2023-01-01';


-- ===============================================================
-- SECTION 3: AND, OR, NOT
-- ===============================================================
--
-- Logical operators combine multiple WHERE conditions.
-- AND → both sides must be TRUE for the row to pass.
-- OR  → at least one side must be TRUE for the row to pass.
-- NOT → inverts TRUE to FALSE and FALSE to TRUE.
-- Precedence: NOT > AND > OR. Use parentheses to make intent explicit.
-- ---------------------------------------------------------------


-- AND — all three conditions must be true simultaneously.
-- This returns only Engineering (dept 1) active employees earning > 80k.
SELECT * FROM company.employees
WHERE dept_id = 1
  AND status  = 'active'
  AND salary  > 80000;


-- OR — either department qualifies.
-- Returns everyone from dept 1 plus everyone from dept 3.
SELECT * FROM company.employees
WHERE dept_id = 1
   OR dept_id = 3;


-- NOT — inverts the condition.
-- "NOT status = 'inactive'" is the same as "status <> 'inactive'".
-- NOT is more readable when negating complex expressions.
SELECT * FROM company.employees
WHERE NOT status = 'inactive';


-- AND vs OR precedence — AND binds tighter than OR.
-- Without parentheses: dept_id=1 OR (dept_id=2 AND salary>70000)
-- The OR applies to EVERYTHING on its left vs the AND group on its right.
-- This means ALL dept 1 employees come through regardless of salary.
SELECT * FROM company.employees
WHERE dept_id = 1
   OR dept_id = 2 AND salary > 70000;   -- reads: dept_id=1 OR (dept_id=2 AND salary>70k)

-- With parentheses — enforce grouping explicitly.
-- Now only employees who are (in dept 1 OR dept 2) AND earn > 70k qualify.
SELECT * FROM company.employees
WHERE (dept_id = 1 OR dept_id = 2)
  AND salary > 70000;


-- ===============================================================
-- SECTION 4: BETWEEN, IN, NOT IN
-- ===============================================================
--
-- BETWEEN and IN are shorthand for common WHERE patterns.
-- BETWEEN lo AND hi  ≡  col >= lo AND col <= hi  (both endpoints inclusive).
-- IN (v1,v2,...)     ≡  col=v1 OR col=v2 OR ...
-- NOT IN (...)       ≡  col<>v1 AND col<>v2 AND ... (breaks if list has NULL).
-- ---------------------------------------------------------------


-- BETWEEN — inclusive range. 60,000 and 90,000 are included.
-- More readable than writing >= and <= separately.
SELECT * FROM company.employees
WHERE salary BETWEEN 60000 AND 90000;

-- NOT BETWEEN — outside the range (< 60,000 OR > 90,000)
SELECT * FROM company.employees
WHERE salary NOT BETWEEN 60000 AND 90000;

-- BETWEEN with dates — same inclusivity rule applies
SELECT * FROM company.employees
WHERE hire_date BETWEEN '2022-01-01' AND '2023-12-31';


-- IN — tests membership in a fixed list.
-- Cleaner than chaining multiple OR conditions.
SELECT * FROM company.employees WHERE dept_id IN (1, 2, 4);
SELECT * FROM company.employees WHERE status  IN ('active', 'on_leave');

-- NOT IN — excludes the listed values.
-- Works correctly when the list is a hard-coded literal set.
SELECT * FROM company.employees WHERE dept_id NOT IN (2, 3);

-- NOT IN danger with NULLs — demonstration.
-- If the subquery returns even one NULL, NOT IN produces zero rows.
-- NULL in SQL is "unknown", so "emp_id NOT IN (1, NULL)" is always NULL (unknown),
-- and unknown conditions filter OUT every row.
-- Fix: use NOT EXISTS (Section 7) when the list comes from a subquery.
SELECT * FROM company.employees
WHERE dept_id NOT IN (1, 2);         -- safe: hard-coded list, no NULLs


-- ===============================================================
-- SECTION 5: LIKE AND ILIKE — PATTERN MATCHING
-- ===============================================================
--
-- LIKE tests string values against a pattern.
-- %  → wildcard for zero or more characters (any characters)
-- _  → wildcard for exactly one character
-- ILIKE is LIKE but case-insensitive (PostgreSQL extension).
-- NOT LIKE / NOT ILIKE negate the match.
-- ---------------------------------------------------------------


-- % at the end — starts with 'A' (A followed by anything)
SELECT * FROM company.employees WHERE first_name LIKE 'A%';

-- % at both ends — 'company' appears anywhere in the email
SELECT * FROM company.employees WHERE email LIKE '%company%';

-- % at the start — last name ends with 'son'
SELECT * FROM company.employees WHERE last_name LIKE '%son';

-- Five _ wildcards — first name is exactly 5 characters long
SELECT * FROM company.employees WHERE first_name LIKE '_____';

-- NOT LIKE — exclude emails from the company domain
SELECT * FROM company.employees WHERE email NOT LIKE '%@company.com';

-- ILIKE — case-insensitive match.
-- Finds 'alice', 'Alice', 'ALICE', 'aLiCe', etc.
SELECT * FROM company.employees WHERE first_name ILIKE 'alice';

-- ILIKE with % — starts with any capitalisation of 'al'
SELECT * FROM company.employees WHERE first_name ILIKE 'al%';


-- ===============================================================
-- SECTION 6: NULL HANDLING — IS NULL, IS NOT NULL, COALESCE, NULLIF
-- ===============================================================
--
-- NULL represents "unknown" or "missing" — it is not a value.
-- Any comparison with NULL (=, <>, >, <) returns NULL, not TRUE or FALSE.
-- That means the row gets filtered OUT because only TRUE rows pass WHERE.
-- Always use IS NULL / IS NOT NULL for null checks.
-- ---------------------------------------------------------------


-- IS NULL — finds rows where the column has no value
SELECT * FROM company.employees WHERE dept_id IS NULL;

-- IS NOT NULL — finds rows where the column has a value
SELECT * FROM company.employees WHERE hire_date IS NOT NULL;

-- Wrong way — returns no rows even if NULLs exist in dept_id
-- Because (NULL = NULL) evaluates to NULL, not TRUE
SELECT * FROM company.employees WHERE dept_id = NULL;


-- COALESCE(value, fallback, ...) — returns the first non-NULL argument.
-- Use it to replace NULLs with a display-friendly default.
-- Here: if location is NULL, show 'No Location' instead.
SELECT
    dept_name,
    COALESCE(location, 'No Location') AS location
FROM company.departments;

-- COALESCE with multiple fallbacks — tries each argument in order
SELECT
    emp_id,
    COALESCE(first_name, last_name, 'Unknown') AS display_name
FROM company.employees;


-- NULLIF(a, b) — returns NULL if a equals b, otherwise returns a.
-- Classic use: prevent division by zero.
-- If headcount = 0, NULLIF returns NULL, and NULL / anything = NULL (no error).
SELECT
    dept_id,
    SUM(salary)                              AS total_salary,
    COUNT(*)                                 AS headcount,
    ROUND(SUM(salary) / NULLIF(COUNT(*), 0), 2) AS avg_salary   -- safe division
FROM company.employees
GROUP BY dept_id;


-- ===============================================================
-- SECTION 7: EXISTS AND NOT EXISTS
-- ===============================================================
--
-- EXISTS (subquery) returns TRUE if the subquery produces at least one row.
-- It stops scanning as soon as it finds the first match — efficient.
-- The outer query's column is correlated to the subquery via WHERE.
-- "SELECT 1" is the convention inside EXISTS — values are ignored.
--
-- NOT EXISTS returns TRUE if the subquery produces ZERO rows.
-- Safe with NULLs — unlike NOT IN which breaks when NULLs are present.
-- ---------------------------------------------------------------


-- EXISTS — departments that have at least one active employee.
-- For each department row, the subquery checks if any employee row matches.
-- The "d.dept_id = e.dept_id" correlation ties the subquery to the outer row.
SELECT dept_id, dept_name
FROM company.departments d
WHERE EXISTS (
    SELECT 1                           -- value doesn't matter; only row existence matters
    FROM company.employees e
    WHERE e.dept_id = d.dept_id
      AND e.status  = 'active'
);


-- NOT EXISTS — departments with NO employees at all.
-- The subquery finds any employee for this department; NOT EXISTS keeps
-- only the departments where no such employee is found.
SELECT dept_id, dept_name
FROM company.departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM company.employees e
    WHERE e.dept_id = d.dept_id
);


-- EXISTS vs IN — same result, but EXISTS is NULL-safe and often faster.
-- IN version (works here because dept_id is a FK, so no NULLs expected):
SELECT * FROM company.employees
WHERE dept_id IN (
    SELECT dept_id FROM company.departments WHERE location IS NOT NULL
);

-- Equivalent EXISTS version (preferred when subquery may have NULLs):
SELECT * FROM company.employees e
WHERE EXISTS (
    SELECT 1 FROM company.departments d
    WHERE d.dept_id  = e.dept_id
      AND d.location IS NOT NULL
);


-- NOT IN NULL danger — why NOT EXISTS is safer.
-- Scenario: departments table has a row where dept_id is NULL (allowed if no FK constraint).
-- NOT IN (1, 2, NULL) → for any emp row: emp.dept_id NOT IN (1,2,NULL)
-- → emp.dept_id <> 1 AND emp.dept_id <> 2 AND emp.dept_id <> NULL
-- → emp.dept_id <> NULL always evaluates to NULL (unknown)
-- → the entire AND chain is NULL → row is filtered OUT → zero rows returned.
SELECT * FROM company.employees
WHERE dept_id NOT IN (1, 2);        -- safe only if the list has no NULLs

-- NOT EXISTS version — always correct regardless of NULLs in the subquery
SELECT e.* FROM company.employees e
WHERE NOT EXISTS (
    SELECT 1 FROM company.departments d
    WHERE d.dept_id = e.dept_id
);


-- EXISTS with COUNT in subquery — departments with 2+ active employees
SELECT dept_id, dept_name
FROM company.departments d
WHERE EXISTS (
    SELECT 1
    FROM company.employees e
    WHERE e.dept_id = d.dept_id
      AND e.status  = 'active'
    HAVING COUNT(*) >= 2
);


-- ===============================================================
-- SECTION 8: CASE — CONDITIONAL LOGIC
-- ===============================================================
--
-- CASE is SQL's if/else expression. It can appear in:
--   SELECT  — to compute a new column based on conditions
--   ORDER BY — to define a custom sort priority
--   WHERE   — to vary the filter threshold based on another column
--   inside an aggregate — for conditional counting/summing (pivot pattern)
--
-- Two forms:
--   Simple CASE:   CASE column WHEN val1 THEN r1 WHEN val2 THEN r2 ELSE rn END
--   Searched CASE: CASE WHEN condition1 THEN r1 WHEN condition2 THEN r2 ELSE rn END
-- CASE evaluates branches top-to-bottom and returns on the FIRST match.
-- The ELSE handles any row that matched none of the WHEN branches.
-- If ELSE is omitted and no branch matches, the result is NULL.
-- ---------------------------------------------------------------


-- Simple CASE — match dept_id against fixed values.
-- Use this when you are comparing ONE expression against multiple values.
SELECT
    emp_id,
    first_name,
    dept_id,
    CASE dept_id
        WHEN 1 THEN 'Engineering'
        WHEN 2 THEN 'Marketing'
        WHEN 3 THEN 'HR'
        ELSE 'Other'              -- catches any dept_id not listed above
    END AS dept_label
FROM company.employees;


-- Searched CASE — each WHEN has its own independent condition.
-- Use this when the conditions involve inequalities, functions, or multiple columns.
-- Order matters: WHEN salary >= 90000 is checked first.
-- An employee earning 95,000 matches the first branch and never reaches the second.
SELECT
    emp_id,
    first_name,
    salary,
    CASE
        WHEN salary >= 90000 THEN 'Senior'
        WHEN salary >= 70000 THEN 'Mid'      -- only reached if salary < 90000
        WHEN salary >= 50000 THEN 'Junior'   -- only reached if salary < 70000
        ELSE 'Entry'
    END AS salary_band
FROM company.employees;


-- CASE in ORDER BY — custom sort priority without changing the data.
-- Active employees sort first (priority 1), then on_leave, then inactive.
-- Using 4 for ELSE means any unexpected status sorts last.
SELECT emp_id, first_name, status
FROM company.employees
ORDER BY
    CASE status
        WHEN 'active'   THEN 1
        WHEN 'on_leave' THEN 2
        WHEN 'inactive' THEN 3
        ELSE 4
    END;


-- CASE in WHERE — the salary threshold varies by department name.
-- Engineering employees must earn > 80k; everyone else must earn > 60k.
-- This is a valid but uncommon pattern — consider if OR/AND can express it more cleanly.
SELECT e.emp_id, e.first_name, e.salary, d.dept_name
FROM company.employees   e
JOIN company.departments d ON e.dept_id = d.dept_id
WHERE
    CASE d.dept_name
        WHEN 'Engineering' THEN e.salary > 80000
        ELSE                    e.salary > 60000
    END;


-- CASE inside COUNT — conditional aggregation (pivot pattern).
-- COUNT(expr) counts rows where expr is NOT NULL.
-- CASE WHEN status='active' THEN 1 END returns 1 for active rows and NULL for others.
-- So COUNT(...) counts only the active rows — effectively a filtered count.
-- This avoids running multiple separate queries for each status.
SELECT
    dept_id,
    COUNT(*)                                           AS total_employees,
    COUNT(CASE WHEN status = 'active'   THEN 1 END)   AS active_count,
    COUNT(CASE WHEN status = 'inactive' THEN 1 END)   AS inactive_count,
    COUNT(CASE WHEN status = 'on_leave' THEN 1 END)   AS on_leave_count
FROM company.employees
GROUP BY dept_id
ORDER BY dept_id;


-- CASE inside SUM — conditional sum (active payroll only).
-- SUM ignores NULLs, so CASE returns salary for active rows and NULL for others.
-- Result: only active salaries are summed per department.
SELECT
    dept_id,
    SUM(salary)                                       AS total_payroll,
    SUM(CASE WHEN status = 'active' THEN salary END)  AS active_payroll,
    ROUND(
        SUM(CASE WHEN status = 'active' THEN salary END)
        / NULLIF(COUNT(CASE WHEN status = 'active' THEN 1 END), 0)
    , 2)                                              AS active_avg_salary
FROM company.employees
GROUP BY dept_id
ORDER BY dept_id;


-- ===============================================================
-- SECTION 9: COMBINED QUERIES — ALL FILTERS TOGETHER
-- ===============================================================
--
-- Real queries combine WHERE, IN, BETWEEN, LIKE, EXISTS, and CASE together.
-- The examples below show how all the concepts compose.
-- ---------------------------------------------------------------


-- Combined: range + pattern + null check
-- Active employees in Engineering hired in 2022, with a company email.
SELECT
    e.emp_id,
    first_name || ' ' || last_name     AS full_name,
    salary,
    hire_date
FROM company.employees e
WHERE e.status    = 'active'
  AND e.dept_id   = 1
  AND e.hire_date BETWEEN '2022-01-01' AND '2022-12-31'
  AND e.email     LIKE '%@company.com'
  AND e.salary    IS NOT NULL;


-- Combined: IN + NOT EXISTS + CASE label
-- Employees in depts 1 or 2 who do NOT belong to a dept without a location,
-- plus a salary band label.
SELECT
    e.emp_id,
    first_name || ' ' || last_name    AS full_name,
    e.salary,
    CASE
        WHEN e.salary >= 90000 THEN 'Senior'
        WHEN e.salary >= 70000 THEN 'Mid'
        ELSE 'Junior'
    END                               AS salary_band
FROM company.employees e
WHERE e.dept_id IN (1, 2)
  AND NOT EXISTS (
      SELECT 1 FROM company.departments d
      WHERE d.dept_id  = e.dept_id
        AND d.location IS NULL
  )
ORDER BY e.salary DESC;


-- Data quality check using CASE — find employees with bad data.
-- Returns every employee that has at least one problem, with a description of the first issue found.
-- CASE evaluates top-to-bottom so the first matching problem is reported.
SELECT
    emp_id,
    first_name,
    last_name,
    CASE
        WHEN salary IS NULL OR salary <= 0       THEN 'Invalid or missing salary'
        WHEN email NOT LIKE '%@%'                THEN 'Invalid email format'
        WHEN hire_date IS NULL                   THEN 'Missing hire date'
        WHEN dept_id IS NULL                     THEN 'No department assigned'
        ELSE 'OK'
    END AS data_issue
FROM company.employees
WHERE salary IS NULL OR salary <= 0
   OR email NOT LIKE '%@%'
   OR hire_date IS NULL
   OR dept_id IS NULL
ORDER BY data_issue;


-- ---------------------------------------------------------------
-- CLEANUP — nothing to clean up (SELECT-only session; no objects created)
-- ---------------------------------------------------------------
