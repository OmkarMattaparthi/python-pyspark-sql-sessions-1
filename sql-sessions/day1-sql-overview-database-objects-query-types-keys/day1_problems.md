# Day 1 Problems — SQL Overview: Database Objects, Query Types & Keys

---

## Section 1: DDL Problems

**Q1.** Create a schema called `company` and inside it create two tables:
- `departments` with columns: `dept_id` (auto-increment PK), `dept_name` (required, max 100 chars), `location` (optional, max 100 chars)
- `employees` with columns: `emp_id` (auto-increment PK), `first_name`, `last_name` (both required, max 50 chars), `email` (unique, required), `salary` (must be > 0), `dept_id` (FK to departments), `hire_date` (date), `status` (default `'active'`)

---

**Q2.** After creating the `employees` table:
- Add a column `phone` of type `VARCHAR(20)`
- Rename the column `phone` to `mobile`
- Drop the column `mobile`

---

**Q3.** What is the difference between `DROP TABLE` and `TRUNCATE TABLE`? When would you use each?

---

## Section 2: DML Problems

**Q4.** Insert the following data into `departments`:
| dept_name | location |
|-----------|----------|
| Engineering | Pune |
| Marketing | Mumbai |
| HR | Bangalore |

---

**Q5.** Insert 3 employees into the `employees` table — assign them to departments from Q4. Use actual `dept_id` values from the inserted rows.

---

**Q6.** Give a 15% salary raise to all employees in the `Engineering` department.

---

**Q7.** Delete all employees who have `status = 'inactive'`. How is this different from `TRUNCATE`?

---

## Section 3: DQL Problems

**Q8.** Write a query to retrieve all employees with a salary greater than 70,000, ordered by salary descending.

---

**Q9.** Write a query that displays:
- `full_name` (first_name + space + last_name)
- `monthly_salary`
- `annual_salary` (monthly × 12)

For employees in dept_id = 1.

---

**Q10.** List all employees hired after `2023-01-01`.

---

## Section 4: DCL Problems

**Q11.** Grant `SELECT` and `INSERT` on the `employees` table to a user named `hr_user`.

---

**Q12.** Revoke `INSERT` permission from `hr_user` on the `employees` table.

---

## Section 5: TCL Problems

**Q13.** Write a transaction that:
1. Inserts a new department `'Finance'` with location `'Delhi'`
2. Inserts one employee into that department
3. Commits only if both inserts succeed — otherwise rolls back.

---

**Q14.** What is a SAVEPOINT? Write an example where you use a savepoint to partially rollback within a transaction.

---

## Section 6: Keys Problems

**Q15.** Given this table:

| emp_id | email | ssn | first_name |
|--------|-------|-----|------------|
| 1 | alice@co.com | 111-22-3333 | Alice |
| 2 | bob@co.com | 444-55-6666 | Bob |

- Which columns are **candidate keys**?
- Which would you choose as the **primary key** and why?
- What is a **surrogate key** alternative here?

---

**Q16.** Create a table `order_items` with a **composite primary key** on `(order_id, product_id)`. Add a `quantity` column with a CHECK constraint that quantity must be >= 1.

---

**Q17.** What happens when you try to:
```sql
DELETE FROM departments WHERE dept_id = 1;
```
...if employees exist with `dept_id = 1` and the FK is set to `RESTRICT`? What if it's `CASCADE`?

---

## Section 7: Views & Triggers Problems

**Q18.** Create a view `high_earners` that shows `first_name`, `last_name`, `salary`, and `dept_name` for employees earning more than 80,000. Join `employees` and `departments`.

---

**Q19.** What is the difference between a regular view and a materialized view? Give a real data engineering use case for each.

---

**Q20.** Describe a scenario in a data pipeline where a **trigger** would be useful. What event would fire it and what would it do?

---

## Bonus Challenge

Design the schema for a simple e-commerce database:
- `customers` table
- `products` table
- `orders` table
- `order_items` table (with composite PK)

Write the `CREATE TABLE` statements with all appropriate constraints, keys, and defaults. Identify which keys are surrogate and which are natural.
