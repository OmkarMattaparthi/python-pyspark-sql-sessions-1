# Day 2 Problems — SQL SELECT: Filters, Operators & CASE

> Use the `company` schema tables (`employees`, `departments`) from Day 1.

---

## Section 1: SELECT — Columns, Aliases, Expressions

**Q1.** Write a query that returns only `first_name`, `last_name`, and `email` from `employees`. Do not use `SELECT *`.

---

**Q2.** Write a query that shows:
- `full_name` — first and last name joined with a space
- `monthly_salary` — the salary column aliased
- `annual_salary` — salary multiplied by 12
- `daily_rate` — salary divided by 30, rounded to 2 decimal places

---

**Q3.** Write a query that returns all employees, sorted by `last_name` ascending, then by `first_name` ascending. Return only the first 3 rows.

---

**Q4.** Write a query that returns all unique combinations of `dept_id` and `status` from the `employees` table.

---

## Section 2: WHERE — Comparison Operators

**Q5.** Find all employees whose salary is greater than 80,000.

---

**Q6.** Find all employees who were hired before `'2022-01-01'`.

---

**Q7.** Find all employees who are NOT in department 2. Use two different ways: `<>` and `!=`.

---

**Q8.** Find all employees whose salary is exactly 75,000 OR whose hire_date is after `'2023-01-01'`.

---

## Section 3: AND, OR, NOT

**Q9.** Find all employees who are:
- in department 1
- AND have status `'active'`
- AND earn more than 70,000

---

**Q10.** Find all employees who are either in department 1 with salary > 85,000, OR in department 3 with any salary. Use parentheses to make the grouping explicit.

---

**Q11.** Find all employees who are NOT active. Write it using both `NOT` and `<>`.

---

**Q12.** Given this query — what does it actually filter? Rewrite it with parentheses to make the intent clearer:
```sql
SELECT * FROM company.employees
WHERE dept_id = 1 OR dept_id = 2 AND salary > 70000;
```

---

## Section 4: BETWEEN, IN, NOT IN

**Q13.** Find all employees with salary between 65,000 and 85,000 (inclusive).

---

**Q14.** Find all employees hired between `'2021-01-01'` and `'2022-12-31'` (inclusive).

---

**Q15.** Find all employees in departments 1, 2, or 4 using `IN`.

---

**Q16.** Find all employees whose status is NOT `'inactive'` or `'on_leave'` using `NOT IN`.

---

**Q17.** Why does this query potentially return no rows even if matching employees exist?
```sql
SELECT * FROM company.employees
WHERE dept_id NOT IN (SELECT dept_id FROM company.departments);
```
What is the fix?

---

## Section 5: LIKE, ILIKE

**Q18.** Find all employees whose first name starts with `'A'`.

---

**Q19.** Find all employees whose email ends with `'.com'`.

---

**Q20.** Find all employees whose last name contains the letters `'son'` anywhere.

---

**Q21.** Find all employees whose first name is exactly 5 characters long using `_` wildcards.

---

**Q22.** Find all employees whose email does NOT contain `'company'`.

---

**Q23.** Find all employees whose first name is `'alice'`, `'Alice'`, or `'ALICE'` using a single filter (case-insensitive).

---

## Section 6: IS NULL, IS NOT NULL, COALESCE, NULLIF

**Q24.** Find all employees who have no department assigned (`dept_id IS NULL`).

---

**Q25.** Find all employees who have a hire date recorded.

---

**Q26.** Write a query that shows all departments. For departments with no location, display `'Location TBD'` instead of NULL.

---

**Q27.** You have a summary table with `total_salary` and `headcount`. Write a SELECT that calculates `avg_salary = total_salary / headcount` but avoids a division-by-zero error when headcount is 0.

---

## Section 7: EXISTS, NOT EXISTS

**Q28.** Find all departments that have at least one active employee using `EXISTS`.

---

**Q29.** Find all departments that have NO employees at all using `NOT EXISTS`.

---

**Q30.** Find all employees who belong to a department that has at least 2 active employees. Use `EXISTS` with a subquery that uses `COUNT`.

---

**Q31.** Rewrite this query using `NOT EXISTS` to fix the NULL safety issue:
```sql
SELECT * FROM company.employees
WHERE dept_id NOT IN (SELECT dept_id FROM company.departments WHERE location IS NULL);
```

---

## Section 8: CASE

**Q32.** Write a query that returns all employees with an extra column `salary_band`:
- `'Senior'` if salary >= 90,000
- `'Mid'` if salary >= 70,000
- `'Junior'` if salary >= 50,000
- `'Entry'` otherwise

---

**Q33.** Write a query that returns all employees with an extra column `dept_label` based on `dept_id`:
- 1 → `'Engineering'`
- 2 → `'Marketing'`
- 3 → `'HR'`
- anything else → `'Other'`
Use the **simple CASE** form.

---

**Q34.** Write a query that orders employees by status: active first, then on_leave, then inactive, using CASE in ORDER BY.

---

**Q35.** Write a single query that returns per `dept_id`:
- `total` — count of all employees
- `active_count` — count of active employees only
- `inactive_count` — count of inactive employees only
- `active_payroll` — sum of salaries for active employees only

Use `CASE` inside aggregate functions.

---

**Q36.** Write a query that selects all employees where:
- If the employee is in Engineering: salary must be > 80,000
- Otherwise: salary must be > 55,000

Use `CASE` in the `WHERE` clause.

---

## Bonus Challenges

**B1.** Write a single query that shows each employee's `full_name`, `salary_band` (Senior/Mid/Junior/Entry), whether they have a department (`'Yes'`/`'No'` using CASE on dept_id IS NULL), and sorts the result: Senior first, then by salary descending within each band.

---

**B2.** Find all employees who:
- Have a salary in the range 60,000–90,000
- AND their first name starts with a vowel (A, E, I, O, U — case-insensitive)
- AND they are NOT in a department that has no location

Use BETWEEN, ILIKE, and NOT EXISTS together.

---

**B3.** Write a query to detect data quality issues in the employees table. Return one row per employee that has at least one of these problems:
- salary is NULL or <= 0
- email does not contain `'@'`
- hire_date is NULL
- dept_id is NULL

Add a `problem` column using CASE that describes what the issue is (if multiple, show the first one found).
