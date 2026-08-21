# Day 3 Problems — SQL JOINs: INNER, LEFT, RIGHT, FULL, SELF, CROSS

> Use the `company` schema: `employees`, `departments`.
> For some problems you'll extend the schema with `projects` and `employee_projects`.

---

## Section 1: INNER JOIN

**Q1.** Write a query that returns each employee's `first_name`, `last_name`, `salary`, and their `dept_name`. Only include employees who have a department.

---

**Q2.** Write a query that lists employees along with their department name and location. Only show employees in departments located in `'Pune'` or `'Mumbai'`.

---

**Q3.** How many employees does each department have? Show `dept_name` and `headcount`, sorted by headcount descending. Only include departments that have at least one employee.

---

**Q4.** What is the average salary per department? Show `dept_name` and `avg_salary` (rounded to 2 decimal places). Use INNER JOIN so empty departments are excluded.

---

## Section 2: LEFT JOIN

**Q5.** Write a query that returns ALL departments, along with the count of employees in each. Departments with no employees should show `0`.

---

**Q6.** Write a query that returns all employees and their department name. Employees who have no department assigned should still appear, with `dept_name` showing as `'No Department'` using COALESCE.

---

**Q7.** Find all employees who have NO department assigned. Use the LEFT JOIN anti-join pattern (check where the right side is NULL).

---

**Q8.** Find all departments that have NO employees. Use the LEFT JOIN anti-join pattern.

---

**Q9.** Explain what happens when you add `WHERE d.dept_name = 'Engineering'` to a LEFT JOIN query. How do you fix it so the LEFT JOIN behaviour is preserved?

---

## Section 3: RIGHT JOIN

**Q10.** Rewrite Q5 using RIGHT JOIN instead of LEFT JOIN (swap the table order). The result should be identical.

---

**Q11.** Write a query using RIGHT JOIN that shows all departments and the first_name of any employee in that department. Departments with no employees should appear with NULL for first_name.

---

**Q12.** Convert this RIGHT JOIN into an equivalent LEFT JOIN:
```sql
SELECT e.first_name, d.dept_name
FROM company.employees e
RIGHT JOIN company.departments d ON e.dept_id = d.dept_id;
```

---

## Section 4: FULL OUTER JOIN

**Q13.** Write a FULL OUTER JOIN between `employees` and `departments`. Show `emp_id`, `first_name`, `dept_id` (from employees), `dept_name`. All rows from both tables should appear.

---

**Q14.** Using the result from Q13, filter to show only:
- Employees who have no department, OR
- Departments that have no employees

---

**Q15.** You have two tables: `system_a_customers` and `system_b_customers`, both with a `customer_email` column. Write a FULL OUTER JOIN query that identifies:
- Emails that exist in A but not B
- Emails that exist in B but not A
- Emails that exist in both

Use a CASE statement to label each row as `'A only'`, `'B only'`, or `'Both'`.

---

## Section 5: SELF JOIN

**Q16.** Add a `manager_id` column to the `employees` table that references `emp_id`. Set employee 2 as the manager of employees 3 and 4. Write a SELF JOIN query that shows each employee's name alongside their manager's name. Employees with no manager should still appear.

---

**Q17.** Using a SELF JOIN, find all pairs of employees who work in the same department. Show `employee_1`, `employee_2`, and `dept_id`. Avoid duplicate pairs (e.g. don't show both (Alice, Bob) and (Bob, Alice)).

---

**Q18.** Using a SELF JOIN, find employees whose salary is higher than their manager's salary.

---

## Section 6: CROSS JOIN

**Q19.** Write a CROSS JOIN between `departments` and a manually listed set of quarters: `('Q1', 'Q2', 'Q3', 'Q4')`. The result should be every department paired with every quarter — useful as a reporting scaffold.

---

**Q20.** How many rows does a CROSS JOIN produce if `employees` has 5 rows and `departments` has 3 rows? Write the query and verify.

---

**Q21.** A company wants to create a skills matrix showing every employee paired with every possible skill from a `skills` table. Write the CROSS JOIN query. Why is CROSS JOIN the right choice here?

---

## Section 7: Multiple JOINs

**Q22.** Create these tables and insert sample data:
```sql
CREATE TABLE company.projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INT REFERENCES company.departments(dept_id)
);

CREATE TABLE company.employee_projects (
    emp_id     INT REFERENCES company.employees(emp_id),
    project_id INT REFERENCES company.projects(project_id),
    role       VARCHAR(50),
    PRIMARY KEY (emp_id, project_id)
);
```
Then write a query showing: `employee full_name`, `dept_name`, `project_name`, `role`.

---

**Q23.** Extend Q22: include ALL employees even if they have no projects assigned. What JOIN type do you use for the employee → project step?

---

**Q24.** Write a query that counts how many projects each employee is assigned to. Include employees with 0 projects. Show `full_name` and `project_count`.

---

## Section 8: JOIN + Aggregation + CASE

**Q25.** Write a query that returns per department:
- `dept_name`
- `headcount`
- `avg_salary`
- `payroll_status`: `'High'` if total salary > 200,000, `'Medium'` if > 100,000, `'Low'` otherwise

Use LEFT JOIN so empty departments appear with 0 headcount and `'Low'` payroll status.

---

**Q26.** Write a query that returns each employee with:
- Their `full_name`
- Their `dept_name` (or `'Unassigned'` if no dept)
- A `salary_vs_dept_avg` label: `'Above average'` / `'Below average'` / `'Average'` compared to their department's average

This requires joining `employees` to `departments` and using a subquery or CTE to get the dept average. (Use a subquery for now — we'll cover CTEs in a later session.)

---

## Section 9: NULL Behavior and Mistakes

**Q27.** This query is supposed to return all departments with their employee count, but it's returning wrong numbers. Find and fix the bug:
```sql
SELECT d.dept_name, COUNT(*) AS headcount
FROM company.departments d
LEFT JOIN company.employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name;
```

---

**Q28.** This query intends to return all employees with their Engineering department info only, but it's accidentally turning the LEFT JOIN into an INNER JOIN. Explain why and fix it:
```sql
SELECT e.first_name, d.dept_name
FROM company.employees e
LEFT JOIN company.departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering';
```

---

**Q29.** You join employees to projects and notice the result has more rows than employees. Explain why this happens and how you diagnose it.

---

## Bonus Challenges

**B1.** Write a single query (no CTEs or subqueries in FROM) that shows:
- All departments (even empty)
- For each department: headcount, avg salary, min salary, max salary
- A `dept_size` label: `'Large'` (≥ 5 employees), `'Medium'` (2–4), `'Small'` (1), `'Empty'` (0)
- Sorted: largest departments first

---

**B2.** Find employees who earn more than the average salary of their own department. Use a SELF-style join where you join employees to a subquery that calculates per-department averages.

```sql
-- Hint structure:
SELECT e.first_name, e.salary, dept_avg.avg_salary
FROM company.employees e
JOIN (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM company.employees
    GROUP BY dept_id
) dept_avg ON e.dept_id = dept_avg.dept_id
WHERE e.salary > dept_avg.avg_salary;
```

---

**B3.** Data reconciliation challenge: You have `staging.employees` (new data from a source system) and `company.employees` (current production data). Write a FULL OUTER JOIN query that identifies:
- New employees in staging not yet in production (INSERT candidates)
- Employees in production no longer in staging (DELETE candidates)
- Employees in both but with a different salary (UPDATE candidates)

Label each row with an `action` column: `'INSERT'`, `'DELETE'`, or `'UPDATE'`.
