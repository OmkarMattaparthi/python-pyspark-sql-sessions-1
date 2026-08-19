# Day 2 Problems — SQL: Stored Procedures, Materialized Views & Sequences

> Use the `company` schema and tables created in Day 1 as your base.

---

## Section 1: Stored Procedures

**Q1.** Create a procedure `add_department` that accepts `dept_name` and `location` as parameters and inserts a new row into `company.departments`. Call it to insert `'Data Engineering'` in `'Hyderabad'`.

---

**Q2.** Create a procedure `deactivate_employee` that accepts an `emp_id` and sets that employee's `status` to `'inactive'`. Add a check — if the employee does not exist, raise an exception with a meaningful message.

---

**Q3.** Create a procedure `bulk_salary_update` that:
- Accepts a `dept_id` and a `raise_percent`
- Updates salary for all active employees in that department
- Raises a NOTICE showing how many rows were updated
- COMMITs on success, ROLLBACKs on error

---

**Q4.** Create a procedure `move_employee` that transfers an employee to a new department AND updates their salary in a single transaction. Both updates must succeed together or neither should apply.

---

**Q5.** What is the difference between using `RAISE NOTICE`, `RAISE WARNING`, and `RAISE EXCEPTION` inside a procedure? When would you use each?

---

**Q6.** Create a procedure `archive_inactive_employees` that:
- Copies all `status = 'inactive'` rows from `company.employees` into a new table `company.employees_archive`
- Deletes those rows from `company.employees`
- Commits after both steps complete

---

## Section 2: Materialized Views

**Q7.** Create a materialized view `company.dept_headcount_mv` that shows:
- `dept_name`
- `headcount` (number of active employees)
- `avg_salary` (rounded to 2 decimal places)

Refresh it after inserting a new employee and verify the counts changed.

---

**Q8.** Add a `UNIQUE INDEX` on `dept_id` to the `company.dept_salary_summary` materialized view from the notes. Then perform a `REFRESH MATERIALIZED VIEW CONCURRENTLY`. Why does CONCURRENTLY require a unique index?

---

**Q9.** What happens when you query a materialized view that was created with `WITH NO DATA`? How do you fix it?

---

**Q10.** Create a materialized view `company.top_earners_mv` that lists the top 5 employees by salary with their department name. Refresh it after giving a 20% raise to the Engineering department.

---

**Q11.** You have a heavy aggregation query that joins 4 tables and takes 8 seconds to run. BI users query it every 30 seconds. What would you do? Write the solution.

---

**Q12.** Explain the tradeoff between `REFRESH MATERIALIZED VIEW` and `REFRESH MATERIALIZED VIEW CONCURRENTLY`. When would stale data from a non-concurrent refresh be acceptable?

---

## Section 3: Sequences

**Q13.** Create a sequence `company.batch_run_seq` that starts at 1, increments by 1, and has no maximum. Use `nextval()` to simulate generating 3 batch run IDs.

---

**Q14.** Create a table `company.pipeline_runs` with:
- `run_id` sourced from `company.batch_run_seq`
- `pipeline_name` (VARCHAR, NOT NULL)
- `status` (VARCHAR, default `'running'`)
- `started_at` (TIMESTAMP, default NOW())

Insert 3 rows for different pipeline names using `nextval()`.

---

**Q15.** A bulk migration inserted 50,000 rows manually (bypassing the sequence) with IDs 1–50000. The sequence is still at 1. What problem will this cause, and how do you fix it?

---

**Q16.** Roll back a transaction after calling `nextval()`. What value does the sequence show after the rollback? What does this tell you about sequences and transactions?

```sql
BEGIN;
SELECT nextval('company.batch_run_seq');
ROLLBACK;
-- What is the sequence's current value now?
```

---

**Q17.** Create a sequence `company.order_ref_seq` starting at 5000, incrementing by 5. Generate 4 values and explain the output.

---

**Q18.** A single sequence `company.event_seq` is shared by two tables: `login_events` and `purchase_events`. Insert 2 rows into each table using this sequence. Show that the `event_id` values are globally unique across both tables.

---

## Section 4: Combined Problems

**Q19.** Design a procedure `company.run_daily_refresh` that:
1. Refreshes `company.dept_salary_summary` materialized view
2. Refreshes `company.dept_headcount_mv` materialized view
3. Logs a row into a `company.refresh_log` table with `(view_name, refreshed_at)`
4. Does all 3 steps in a single transaction

---

**Q20.** A pipeline inserts employee data in batches. Each batch needs a unique `batch_id` from a sequence. Design:
- A sequence for batch IDs
- A procedure that accepts `batch_size` and `source_file_name`, generates a batch ID, inserts a log row, and returns the batch ID via an OUT parameter

---

## Bonus Challenge

You are building a data warehouse load pipeline. Design the following:

1. A sequence `dw.load_run_seq` for unique load run IDs
2. A table `dw.load_runs` tracking: `run_id`, `table_name`, `rows_inserted`, `rows_updated`, `started_at`, `completed_at`, `status`
3. A procedure `dw.start_load_run(p_table_name, OUT p_run_id)` that creates a load run record and returns the run_id
4. A procedure `dw.complete_load_run(p_run_id, p_rows_inserted, p_rows_updated)` that updates the record with final stats and sets status to `'completed'`
5. A materialized view `dw.load_summary_mv` showing total rows loaded per table per day

Write all DDL and procedures. Show a sample call sequence simulating one full load run.
