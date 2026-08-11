# Day 8 Practice Problems — filter, map, reduce, copy, deepcopy

Difficulty: Medium to Hard. No solutions provided — work through the logic.

---

## Section A — map()

**P1. Square and Cube** *(Easy)*
```python
numbers = [2, 3, 4, 5, 6, 7, 8]
```
Using `map()` with lambda:
1. Create a list of squares
2. Create a list of cubes
3. Create a list of `(number, square, cube)` tuples

---

**P2. Column Name Cleaner** *(Medium)*
```python
raw_columns = ["  Employee ID  ", "FIRST NAME", "last_name", "Salary (USD)", "Hire-Date"]
```
Using a single `map()` call, clean every column name:
1. Strip whitespace
2. Lowercase
3. Replace spaces and hyphens with `_`
4. Remove `(usd)` if present

Expected: `["employee_id", "first_name", "last_name", "salary_", "hire_date"]`

---

**P3. Salary Raise** *(Medium)*
```python
employees = [
    {"name": "Alice", "dept": "Engineering", "salary": 95000},
    {"name": "Bob",   "dept": "Sales",       "salary": 72000},
    {"name": "Carol", "dept": "Data",        "salary": 88000},
    {"name": "Dave",  "dept": "Engineering", "salary": 102000},
]
```
Using `map()`:
1. Apply 15% raise to Engineering employees, 10% to all others
2. Return updated dicts (use `{**e, "salary": new_salary}`)
3. Print each employee's name and new salary

---

**P4. File Path Builder** *(Medium)*
```python
table_names = ["orders", "customers", "payments", "sessions", "products"]
base_path   = "data/raw/2024/01"
```
Using `map()`, build a list of full file paths:
```
["data/raw/2024/01/orders.json", "data/raw/2024/01/customers.json", ...]
```

---

## Section B — filter()

**P5. Filter Even/Odd** *(Easy)*
```python
numbers = list(range(1, 21))
```
Using `filter()`:
1. Keep only even numbers
2. Keep only odd numbers
3. Keep numbers divisible by 3

---

**P6. Filter by File Type** *(Medium)*
```python
files = [
    "employees.csv", "orders.json", "schema.parquet",
    "config.yaml", "audit.csv", "pipeline.log",
    "products.csv", "weather.json", "temp.txt"
]
```
Using `filter()`:
1. Keep only `.csv` files
2. Keep only `.json` or `.parquet` files
3. Remove `.log` and `.txt` files (keep everything else)

---

**P7. Data Quality Filter** *(Medium)*
```python
records = [
    {"id": 1, "name": "Alice",   "salary": 95000,  "dept": "Engineering"},
    {"id": 2, "name": "",        "salary": 72000,  "dept": "Sales"},
    {"id": 3, "name": "Carol",   "salary": -500,   "dept": "Data"},
    {"id": 4, "name": "Dave",    "salary": 102000, "dept": "Engineering"},
    {"id": 5, "name": "Eve",     "salary": 0,      "dept": "HR"},
    {"id": 6, "name": "Frank",   "salary": 78000,  "dept": ""},
]
```
Using `filter()` with a named function `is_valid(record)`:
1. Remove rows where `name` is empty
2. Remove rows where `salary` <= 0
3. Remove rows where `dept` is empty
4. Print how many valid records remain

---

**P8. Filter API Users** *(Medium)*
```python
users = [
    {"id": 1, "name": "Alice",  "email": "alice@gmail.com",   "active": True},
    {"id": 2, "name": "Bob",    "email": "bob@yahoo.com",     "active": False},
    {"id": 3, "name": "Carol",  "email": "carol@company.com", "active": True},
    {"id": 4, "name": "Dave",   "email": "dave@gmail.com",    "active": False},
    {"id": 5, "name": "Eve",    "email": "not-an-email",      "active": True},
]
```
Using `filter()`:
1. Keep only active users
2. From active users, keep only those with valid emails (must contain `@` and `.`)
3. Print name and email of final filtered list

---

## Section C — reduce()

**P9. Reduce Basics** *(Easy)*
```python
from functools import reduce
numbers = [3, 7, 2, 9, 4, 6, 1, 8, 5]
```
Using `reduce()`:
1. Find the sum
2. Find the maximum value
3. Find the minimum value
4. Find the product of all numbers

---

**P10. Longest Word** *(Medium)*
```python
from functools import reduce
words = ["data", "engineering", "pipeline", "transformation", "warehouse"]
```
Using `reduce()`, find the longest word.

---

**P11. Merge Dicts with reduce** *(Medium-Hard)*
```python
from functools import reduce

configs = [
    {"host": "localhost"},
    {"port": 5432},
    {"db": "warehouse"},
    {"user": "admin"},
    {"timeout": 30},
]
```
Using `reduce()`, merge all dicts into one:
```python
{"host": "localhost", "port": 5432, "db": "warehouse", "user": "admin", "timeout": 30}
```

---

## Section D — copy vs deepcopy

**P12. Spot the Difference** *(Medium)*
```python
from copy import copy, deepcopy

schema = {
    "table": "orders",
    "columns": ["id", "amount", "status"],
    "options": {"partition_by": "date", "format": "parquet"}
}
```
1. Create `s2 = schema` (reference)
2. Create `s3 = copy(schema)` (shallow)
3. Create `s4 = deepcopy(schema)` (deep)
4. Append `"customer_id"` to `schema["columns"]`
5. Change `schema["options"]["format"]` to `"csv"`
6. Print `s2`, `s3`, `s4` — explain in comments which changed and why

---

**P13. Safe Config for Multiple Pipelines** *(Hard)*
```python
from copy import deepcopy

base_pipeline = {
    "source": "postgres",
    "target": "s3",
    "tables": ["orders", "customers"],
    "options": {"batch_size": 500, "retry": 3}
}
```
Write a function `create_pipeline(name, overrides=None)` that:
1. Deep copies `base_pipeline`
2. Adds `"name"` key with the pipeline name
3. If `overrides` dict is provided, updates the copy with it (nested-aware)
4. Returns the final config

```python
p1 = create_pipeline("etl_orders",    {"options": {"batch_size": 1000}})
p2 = create_pipeline("etl_payments",  {"target": "redshift", "tables": ["payments"]})
p3 = create_pipeline("etl_daily")

print(base_pipeline)   # must be unchanged
```

---

## Section E — Chaining map + filter + reduce

**P14. Pipeline Salary Report** *(Hard)*
```python
from functools import reduce

employees = [
    {"name": "Amit",  "salary": 50000,  "dept": "Sales",        "active": True},
    {"name": "Rahul", "salary": 75000,  "dept": "Data",         "active": True},
    {"name": "Priya", "salary": 90000,  "dept": "Data",         "active": True},
    {"name": "Raj",   "salary": 45000,  "dept": "HR",           "active": False},
    {"name": "Neha",  "salary": 82000,  "dept": "Data",         "active": True},
    {"name": "Vikas", "salary": 110000, "dept": "Engineering",  "active": True},
    {"name": "Sara",  "salary": 68000,  "dept": "Engineering",  "active": False},
]
```
In a single chain using `filter()`, `map()`, `reduce()`:
1. Keep only active employees
2. Keep only Data and Engineering departments
3. Apply a 12% salary raise (via map)
4. Extract the new salaries
5. Find the total salary bill using reduce

Print the final total.

---

**P15. Log Processor** *(Hard)*
```python
log_lines = [
    "2024-01-15 | INFO  | Pipeline started       | rows=0",
    "2024-01-15 | INFO  | Ingestion complete      | rows=1500",
    "2024-01-15 | ERROR | Validation failed       | rows=1500",
    "2024-01-15 | INFO  | Transform complete      | rows=1480",
    "2024-01-15 | WARN  | Nulls in salary column  | rows=1480",
    "2024-01-15 | ERROR | DB write failed         | rows=0",
    "2024-01-15 | INFO  | Pipeline finished       | rows=1480",
]
```
Using `map()`, `filter()`, and `reduce()`:
1. `map()` — parse each line into a dict: `{date, level, message, rows}`
2. `filter()` — keep only `ERROR` lines
3. `reduce()` — find the max `rows` value across all ERROR lines

Print error messages and the max rows value.
