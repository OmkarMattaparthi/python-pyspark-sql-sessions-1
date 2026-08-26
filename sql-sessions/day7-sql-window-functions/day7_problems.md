# Day 7 Problems — SQL Window Functions

> Use the `company` schema created in `day7_practice.sql`.
> Tables: `departments`, `employees`, `orders`, `order_items`, `sales_daily`.

---

## Section 1: Understanding OVER() — The Basics

**Q1.** Write a query that shows every employee's `name`, `salary`, and the **company-wide average salary** on every row. Use `AVG() OVER ()` with an empty OVER clause. Label the column `company_avg`.

---

**Q2.** Write a query that shows every employee's `name`, `dept_name`, `salary`, and the **average salary for their department** on every row. Use `AVG() OVER (PARTITION BY dept_id)`. Label it `dept_avg`.

---

**Q3.** Extend Q2: also add a column `diff_from_dept_avg` showing how much each employee earns above or below their department average (salary − dept_avg). Round to 2 decimal places.

---

**Q4.** Write a query that shows every employee alongside:
- `dept_headcount` — total employees in their department (COUNT OVER PARTITION BY)
- `dept_total_payroll` — total salary in their department (SUM OVER PARTITION BY)
- `dept_max_salary` — highest salary in their department (MAX OVER PARTITION BY)

---

## Section 2: ROW_NUMBER, RANK, DENSE_RANK

**Q5.** Write a query that assigns a `ROW_NUMBER` to each employee ordered by salary descending (company-wide, no partition). Show `name`, `salary`, `row_num`. The highest paid employee gets row 1.

---

**Q6.** Write a query that assigns `RANK` and `DENSE_RANK` to each employee ordered by salary descending. Show `name`, `salary`, `rnk`, `dense_rnk`. Use the employees table to demonstrate a tie (two employees with the same salary).

---

**Q7.** Write a query that ranks employees **within each department** by salary descending. Show `name`, `dept_name`, `salary`, and `rank_in_dept`. Use `RANK()` with `PARTITION BY dept_id`.

---

**Q8.** Using the result of Q7, filter to show only the **top earner in each department** (rank = 1). You cannot use window functions in WHERE — use a subquery or CTE. Show `dept_name`, `name`, `salary`.

---

**Q9.** Write a query that assigns a `ROW_NUMBER` per department ordered by salary descending. Then find all employees who are **ranked 2nd** in their department. If a department has only 1 employee, they should not appear.

---

## Section 3: NTILE

**Q10.** Divide all employees into **4 salary quartiles** using `NTILE(4)` ordered by salary ascending. Show `name`, `salary`, and `quartile`. Quartile 1 = lowest 25%, Quartile 4 = highest 25%.

---

**Q11.** Divide employees into **3 equal groups** by salary within each department. Show `name`, `dept_name`, `salary`, `salary_tier`. Label the tiers using CASE: tier 1 → `'Low'`, tier 2 → `'Medium'`, tier 3 → `'High'`.

---

## Section 4: LAG and LEAD

**Q12.** Write a query using the `orders` table that shows each order's `order_date`, `amount`, the **previous order amount** (`prev_amount` using LAG), and the **next order amount** (`next_amount` using LEAD). Order by `order_date`. Show NULL for missing previous/next.

---

**Q13.** Extend Q12: add a column `change_from_prev` showing `amount − prev_amount`. Show NULL for the first row.

---

**Q14.** Write a query that shows **month-over-month revenue change** using the `sales_daily` table. Group by month first (use a subquery), then use LAG to compare each month to the previous month. Show `month`, `revenue`, `prev_revenue`, `change`, `pct_change` (rounded to 2 decimal places).

---

**Q15.** Write a query that uses `LEAD` to find orders where the **next order for the same customer** was placed more than 30 days later. Show `customer_id`, `order_date`, `next_order_date`, `gap_days`. These customers may have churned between orders.

---

## Section 5: Running Totals and Cumulative Aggregates

**Q16.** Write a query that shows each order with a **running total of amount** ordered by `order_date`. Show `order_id`, `order_date`, `amount`, `running_total`. Each row should show the cumulative sum up to that order.

---

**Q17.** Write a query that shows a **running total of sales per customer** — ordered by order date within each customer. Show `customer_id`, `order_date`, `amount`, `customer_running_total`.

---

**Q18.** Write a query that shows for each employee the **running count of employees hired** in the same department, ordered by hire_date. Show `name`, `dept_name`, `hire_date`, `running_hire_count`.

---

## Section 6: Window Frames — ROWS BETWEEN

**Q19.** Using the `sales_daily` table, write a query that computes a **3-day moving average** of `daily_sales`. The window should be the previous row, current row, and next row. Show `sale_date`, `daily_sales`, `moving_avg_3day`.

---

**Q20.** Using `sales_daily`, write a query that computes a **7-day rolling sum** of `daily_sales` (current day + 6 preceding days). Show `sale_date`, `daily_sales`, `rolling_7day_sum`.

---

**Q21.** Write a query that shows for each employee the **sum of all salaries in their department** (not a running total — the full partition total). Use `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` explicitly. Compare the result with `SUM OVER (PARTITION BY dept_id)` — they should be identical.

---

## Section 7: FIRST_VALUE, LAST_VALUE, NTH_VALUE

**Q22.** Write a query that shows each employee alongside the **name of the highest-paid employee in their department** (`top_earner`). Use `FIRST_VALUE` with `ORDER BY salary DESC` and `PARTITION BY dept_id`.

---

**Q23.** Write a query that shows each employee alongside the **name of the lowest-paid employee in their department** (`bottom_earner`). Use `LAST_VALUE` — remember to include the full frame `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`.

---

**Q24.** Write a query that shows each employee alongside the **name of the second highest paid** in their department. Use `NTH_VALUE(name, 2)` with a full frame. If no second employee exists in the dept, it should show NULL.

---

## Section 8: Named WINDOW Clause

**Q25.** Rewrite this query using a named `WINDOW` clause to avoid repeating the window definition:

```sql
SELECT
    name,
    dept_id,
    salary,
    ROW_NUMBER()  OVER (PARTITION BY dept_id ORDER BY salary DESC),
    RANK()        OVER (PARTITION BY dept_id ORDER BY salary DESC),
    DENSE_RANK()  OVER (PARTITION BY dept_id ORDER BY salary DESC),
    NTILE(3)      OVER (PARTITION BY dept_id ORDER BY salary DESC)
FROM company.employees;
```

---

## Section 9: Combined Problems

**Q26.** Write a query that returns each employee with:
- Their `name`, `dept_name`, `salary`
- `rank_in_dept` — rank by salary within department
- `pct_of_dept_total` — their salary as a percentage of the department's total payroll (rounded to 2 decimal places)
- `above_or_below_avg` — `'Above'` if salary > dept avg, `'Below'` if less, `'Equal'` if same

---

**Q27.** Write a query that shows the **top 2 orders by amount per customer**. Show `customer_id`, `order_id`, `order_date`, `amount`, `rank_in_customer`. Use ROW_NUMBER or RANK in a CTE, then filter.

---

**Q28.** Using `sales_daily`, write a query that shows for each date:
- `sale_date`, `daily_sales`
- `cumulative_sales` — running total from the start
- `running_avg` — running average
- `pct_of_total` — what percentage of the total (all days) sales this day represents

---

## Section 10: NULL Behavior and Mistakes

**Q29.** This query throws an error. Explain why and fix it:
```sql
SELECT name, salary
FROM company.employees
WHERE ROW_NUMBER() OVER (ORDER BY salary DESC) <= 3;
```

---

**Q30.** This query is supposed to show each employee's salary alongside the lowest salary in their department, but `LAST_VALUE` is returning the employee's own salary instead of the department's minimum. Explain why and fix it:
```sql
SELECT
    name,
    dept_id,
    salary,
    LAST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dept_min_salary
FROM company.employees;
```

---

## Bonus Challenges

**B1.** Write a single query (using window functions and no subquery/CTE) that returns each employee with:
- `name`, `dept_name`, `salary`, `hire_date`
- `salary_rank_in_dept` (DENSE_RANK by salary desc within dept)
- `hire_rank_in_dept` (ROW_NUMBER by hire_date asc within dept — who was hired first)
- `is_highest_paid` — `'Yes'` if they are the highest paid in their department, `'No'` otherwise
- `salary_gap_to_top` — difference between the top salary in their dept and their salary

Use a `WINDOW` clause for the two partition windows.

---

**B2.** Identify **consecutive day streaks** in `sales_daily` where `daily_sales > 1000`. For each date, assign a `streak_group` number that increments whenever the streak breaks. Then find the longest streak. Hint: use `ROW_NUMBER()` minus `ROW_NUMBER() OVER (ORDER BY sale_date)` on the filtered rows.

---

**B3.** Write a customer retention query using `orders`. For each customer, use `LAG` and `LEAD` to classify each order as:
- `'First Order'` — no previous order for this customer
- `'Repeat'` — has a previous order within 90 days
- `'Returned'` — has a previous order but it was more than 90 days ago
- `'Last Known Order'` — no next order (most recent order for this customer)

Show `customer_id`, `order_date`, `amount`, `order_type`. A single order can match multiple labels — use the most specific one in this priority: First Order > Returned > Repeat > Last Known Order.
