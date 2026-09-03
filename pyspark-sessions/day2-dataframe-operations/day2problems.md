# Day 2 - Practice Problems

**Topics covered:** select, filter/where, withColumn, groupBy+agg, orderBy, lazy evaluation, toPandas

Use this employee dataset for all problems:

```python
data = [
    ("Alice",   "Engineering",  85000, 30),
    ("Bob",     "Sales",        60000, 25),
    ("Carol",   "Engineering",  92000, 35),
    ("Dave",    "Sales",        58000, 28),
    ("Eve",     "HR",           55000, 32),
    ("Frank",   "Engineering",  78000, 40),
    ("Grace",   "HR",           61000, 29),
    ("Hank",    "Sales",        67000, 45),
]
columns = ["name", "department", "salary", "age"]
df = spark.createDataFrame(data, columns)
```

---

## Problem 1 — select

1. Select only `name` and `department` columns.
2. Select `name`, `salary`, and a new column `salary_usd` = salary divided by 83, cast to integer.
3. Select all columns plus a new column `age_group`:
   - "Young" if age < 30
   - "Mid" if age is 30–39
   - "Senior" if age >= 40

---

## Problem 2 — filter

1. Filter employees with salary greater than 70000.
2. Filter employees in the `Engineering` department.
3. Filter employees who are in `Engineering` AND have salary > 80000.
4. Filter employees who are either in `HR` OR have age less than 27.
5. Filter employees whose department is one of: `Sales`, `HR` — use `isin()`.

---

## Problem 3 — withColumn

1. Add a new column `tax` = 10% of salary (salary * 0.10), rounded to 2 decimal places.
2. Add a new column `net_salary` = salary - tax. (chain two withColumn calls)
3. Add a column `experience_band`:
   - "Junior"  if age < 28
   - "Mid"     if 28 <= age < 35
   - "Senior"  if age >= 35
4. Replace the `department` column with its lowercase version.

---

## Problem 4 — groupBy + aggregation

1. Count the number of employees in each department.
2. Find the average salary per department.
3. For each department, show:
   - headcount
   - average salary (rounded to 0 decimal places)
   - maximum salary
   - minimum age
4. Sort the result from Problem 3 by average salary descending.

---

## Problem 5 — orderBy

1. Show all employees sorted by salary ascending.
2. Show all employees sorted by department ascending, then age descending.
3. Show the top 3 highest-paid employees. (hint: orderBy + show(3) or limit(3))

---

## Problem 6 — Chaining transformations

Write a single chain that:
1. Filters employees with salary >= 60000
2. Adds a column `hike` = salary * 1.15
3. Selects only `name`, `department`, `salary`, `hike`
4. Orders by `hike` descending
5. Shows the result

---

## Problem 7 — Lazy evaluation

1. Create a transformation plan (don't call show yet):
   - Filter age > 30
   - Add column `seniority = "Senior"`
   - Select name, department, salary, seniority
2. Call `explain()` on the plan and observe the output.
3. Call `show()` to trigger execution.
4. How many actions did you call in total?

---

## Problem 8 — toPandas

1. Filter the Engineering department and convert to a Pandas DataFrame.
2. Print the Pandas DataFrame and its type.
3. What happens if you call `toPandas()` without filtering first? Try it and observe.

---

## Problem 9 — Rename and Drop

1. Rename the `name` column to `employee_name` using `withColumnRenamed`.
2. Drop the `age` column and show the result.
3. Use `select` with `.alias()` to rename `department` to `dept` and `salary` to `ctc` in one step.

---

## Bonus — Count NULL values

Add a column `bonus` with value `None` for all rows:
```python
from pyspark.sql.functions import lit
df2 = df.withColumn("bonus", lit(None).cast("int"))
```

Then:
1. Filter rows where `bonus` is NULL.
2. Filter rows where `bonus` is NOT NULL.
3. Count how many rows have NULL bonus. (hint: filter + count)
