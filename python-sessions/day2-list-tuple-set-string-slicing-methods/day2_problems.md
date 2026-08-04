# Day 2 Practice Problems — List, Tuple, Set, String

Difficulty: Medium to Hard. No solutions provided — work through the logic.

---

## Section A — List Slicing & Methods

**P1. Batch Window Slicer** *(Medium)*
```python
records = list(range(1, 21))   # [1, 2, 3, ..., 20]
```
Using only slicing (no loops):
1. Extract records 5 through 10 (inclusive by value)
2. Extract the last 5 records
3. Extract every 3rd record from the full list
4. Reverse the entire list
5. Extract records from index 3 to 15 with a step of 2

---

**P2. Schema Normalizer** *(Medium)*
```python
columns = ["  ID ", "Name", "SALARY", "dept", "Hire_Date", "EMAIL  "]
```
Using list methods and string methods together:
1. Strip whitespace from every column name
2. Convert all to lowercase
3. Sort them alphabetically
4. Find the index of `"salary"` in the sorted list
5. Insert `"updated_at"` at position 0

---

**P3. Pipeline Log Manager** *(Medium-Hard)*
```python
logs = ["start", "ingest", "validate", "error", "transform", "error", "load", "error", "end"]
```
1. Count how many times `"error"` appears
2. Find the index of the first `"error"`
3. Remove ALL occurrences of `"error"` from the list (hint: loop + remove, or list comprehension)
4. Reverse the cleaned log list using slicing
5. Print every other step from the cleaned list

---

**P4. Sorted Merge** *(Hard)*
```python
batch_a = [34, 12, 78, 5, 90]
batch_b = [23, 67, 1, 45, 89]
```
Without using `sorted()` on the combined list directly:
1. Sort each batch individually using `.sort()`
2. Merge them using `extend()`
3. Sort the merged list in descending order
4. Slice out only the top 5 values
5. Copy the top 5 into a new list without referencing the original

---

## Section B — Tuple Slicing & Methods

**P5. Config Unpacker** *(Medium)*
```python
pipeline_config = ("warehouse_db", "localhost", 5432, "admin", "readonly", "utf-8", "prod")
```
Using only slicing and unpacking:
1. Unpack `db_name`, `host`, `port` from the first 3 positions
2. Slice out only the last 3 elements as a new tuple
3. Reverse the full config tuple using slicing
4. Count how many times `"readonly"` appears
5. Find the index of `"prod"`

---

**P6. Multi-Return Simulator** *(Medium)*
Write a function `analyze_scores(scores)` that receives a tuple of integers and returns a tuple of:
- minimum value
- maximum value
- sum of all values
- count of values above 70

Call it with:
```python
scores = (45, 82, 91, 37, 76, 65, 88, 54, 93, 60)
```
Unpack and print each result with a label.

---

**P7. Immutability Test** *(Medium-Hard)*
```python
row1 = (1, "Alice", 95000, "Engineering")
row2 = (2, "Bob",   72000, "Finance")
row3 = (3, "Carol", 88000, "Engineering")
rows = [row1, row2, row3]
```
1. Slice only the last 2 rows from `rows`
2. From each row, extract only name and salary using unpacking (ignore id and dept)
3. Find all employees in "Engineering" — check using index access, not a loop method
4. Try to change `row1[2]` to `99000`. What happens? Write the error in a comment.
5. Create a new tuple replacing the salary: `(row1[0], row1[1], 99000, row1[3])`

---

## Section C — Set Methods

**P8. Schema Diff Tool** *(Medium)*
```python
expected = {"id", "name", "salary", "department", "hire_date", "email"}
received = {"id", "name", "salary", "phone", "hire_date", "region"}
```
1. Find columns present in `expected` but missing from `received`
2. Find columns in `received` that were not expected
3. Find columns common to both
4. Find columns that appear in only one of the two (symmetric difference)
5. Check if `{"id", "name"}` is a subset of `received`

> This is a real schema validation pattern used in data ingestion pipelines.

---

**P9. Deduplication Pipeline** *(Medium)*
```python
raw_cities = ["Mumbai", "Delhi", "Mumbai", "Bangalore", "Delhi",
              "Chennai", "Mumbai", "Hyderabad", "Chennai"]
```
1. Convert to a set to get unique cities
2. Add `"Pune"` and `"Kolkata"` to the set
3. Remove `"Delhi"` safely (use `discard`)
4. Check if `"Mumbai"` is still in the set
5. Convert the final set back to a sorted list

---

**P10. Access Control Checker** *(Hard)*
```python
all_tables      = {"orders", "customers", "products", "payments", "logs", "audit", "config"}
analyst_access  = {"orders", "customers", "products"}
engineer_access = {"orders", "customers", "products", "payments", "logs"}
admin_access    = {"orders", "customers", "products", "payments", "logs", "audit", "config"}
```
1. What tables can an analyst see that an engineer cannot? (should be empty)
2. What tables does an engineer have that an analyst doesn't?
3. What tables are restricted (not in analyst or engineer access)?
4. Is `analyst_access` a subset of `engineer_access`?
5. Is `engineer_access` a subset of `admin_access`?
6. Are `analyst_access` and `{"audit", "config"}` disjoint?

---

## Section D — String Slicing & Methods

**P11. Column Name Cleaner** *(Medium)*
```python
raw_columns = [
    "  Employee ID  ",
    "FIRST NAME",
    "last_name",
    "Salary (USD)",
    "Hire-Date",
    "  Department  "
]
```
For each column name:
1. Strip leading/trailing whitespace
2. Convert to lowercase
3. Replace spaces with `_`
4. Replace `-` with `_`
5. Remove `(usd)` if present
6. Print the cleaned name

Expected output:
```
employee_id
first_name
last_name
salary_
hire_date
department
```

---

**P12. SQL Query Builder** *(Medium-Hard)*
```python
table   = "employees"
columns = ["id", "name", "salary", "department"]
filter_col   = "department"
filter_val   = "Engineering"
```
Build this SQL string using only string methods and f-strings:
```sql
SELECT id, name, salary, department FROM employees WHERE department = 'Engineering';
```
Requirements:
- Use `", ".join(columns)` for the column list
- Use `.upper()` on keywords (`SELECT`, `FROM`, `WHERE`)
- The final string must end with `;`

---

**P13. Log Parser** *(Hard)*
```python
log_lines = [
    "2024-01-15 | INFO  | Pipeline started | rows=0",
    "2024-01-15 | INFO  | Ingestion done   | rows=1500",
    "2024-01-15 | ERROR | Validation failed| rows=1500",
    "2024-01-15 | INFO  | Transform done   | rows=1480",
    "2024-01-15 | ERROR | Load failed      | rows=0",
]
```
For each log line:
1. Split on `" | "` to get `[date, level, message, rows_part]`
2. Extract the row count from `rows_part` (e.g. `"rows=1500"` → `1500`) — use `split("=")` and cast to `int`
3. Filter and collect only `ERROR` lines
4. Print total rows processed in the last `INFO` line before each error
5. Print count of ERROR lines

---

**P14. File Path Processor** *(Medium)*
```python
paths = [
    "/data/raw/2024/01/employees.csv",
    "/data/raw/2024/02/employees.csv",
    "/data/processed/2024/01/employees_clean.parquet",
    "/data/raw/2024/03/orders.csv",
    "/data/processed/2024/02/orders_clean.parquet",
]
```
For each path:
1. Extract the filename using `split("/")` and `[-1]`
2. Extract the file extension using `split(".")[-1]`
3. Filter only `.csv` files
4. From each `.csv` path, extract the month (e.g. `"01"`, `"02"`)
5. Check if the filename `startswith("employees")`

---

## Section E — Mixed / Hard

**P15. Schema Comparison Report** *(Hard)*
```python
table_a_cols = ["id", "name", "salary", "department", "hire_date"]
table_b_cols = ["ID", "Name", "Salary", "Email", "Phone", "Hire_Date"]
```
1. Normalize both lists to lowercase using a list comprehension
2. Convert both to sets
3. Find columns in A not in B, B not in A, and common to both
4. Build a report string using `join()`:
```
Missing from B: department
Missing from A: email, phone
Common: hire_date, id, name, salary
```

---

**P16. Data Row Validator** *(Hard)*
```python
raw_rows = [
    ("101", "Alice",   "95000",  "Engineering"),
    ("102", "  Bob  ", "seventy","Finance"),
    ("103", "",        "82000",  "Data"),
    ("104", "Carol",   "110000", ""),
]
```
For each row (a tuple):
1. Strip whitespace from name
2. Check name is not empty — if empty, mark as `"INVALID"`
3. Try to cast salary to `int` — if it fails (non-numeric), mark salary as `-1`
4. Check department is not empty — if empty, mark as `"UNKNOWN"`
5. Print a cleaned summary:
```
ID: 101 | Name: Alice  | Salary: 95000  | Dept: Engineering | Valid: True
ID: 102 | Name: Bob    | Salary: -1     | Dept: Finance     | Valid: False
ID: 103 | Name: INVALID| Salary: 82000  | Dept: Data        | Valid: False
ID: 104 | Name: Carol  | Salary: 110000 | Dept: UNKNOWN     | Valid: False
```

> This pattern — cast, validate, flag — is the foundation of every data quality check in a pipeline.
