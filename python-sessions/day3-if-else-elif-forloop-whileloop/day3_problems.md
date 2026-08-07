# Day 3 Practice Problems — if / elif / else, for loop, while loop

Difficulty: Medium to Hard. No solutions provided — work through the logic.

---

## Section A — if / elif / else

**P1. HTTP Status Router** *(Easy)*
```python
status_code = 403
```
Write if/elif/else to print:
- `200` → `"OK — data fetched"`
- `201` → `"Created — record inserted"`
- `400` → `"Bad Request — check your query"`
- `403` → `"Forbidden — no access"`
- `404` → `"Not Found — resource missing"`
- `500` → `"Server Error — retry later"`
- anything else → `"Unknown status code"`

---

**P2. Grade Classifier** *(Easy-Medium)*
```python
score = 73
```
Classify using elif:
- `>= 90` → `"A"`
- `>= 80` → `"B"`
- `>= 70` → `"C"`
- `>= 60` → `"D"`
- below 60 → `"F"`

Also print: `"Pass"` if grade is A/B/C/D, `"Fail"` if F.

---

**P3. File Format Validator** *(Medium)*
```python
file_name = "sales_data.xlsx"
allowed_formats = ["csv", "parquet", "json", "orc"]
```
1. Extract the file extension using string methods
2. Check if it is in `allowed_formats`
3. If yes → print `"Valid: <ext> accepted"`
4. If no → print `"Invalid: <ext> not supported. Use: csv, parquet, json, orc"`

---

**P4. Salary Band Classifier** *(Medium)*
```python
employees = [
    ("Alice", 120000),
    ("Bob", 45000),
    ("Carol", 75000),
    ("Dave", 95000),
    ("Eve", 30000),
]
```
For each employee, classify salary:
- `>= 100000` → `"Senior"`
- `>= 70000`  → `"Mid"`
- `>= 50000`  → `"Junior"`
- below       → `"Entry"`

Print: `"Alice — Senior"`, `"Bob — Entry"`, etc.

---

**P5. Pipeline Status Check** *(Medium-Hard)*
```python
row_count   = 1500
error_count = 47
threshold   = 5     # max allowed error %
```
Calculate error percentage. Then:
- If error % > threshold AND error_count > 100 → `"CRITICAL: pipeline failed"`
- If error % > threshold → `"WARNING: high error rate"`
- If row_count == 0 → `"ERROR: no data loaded"`
- Otherwise → `"OK: pipeline healthy"`

---

## Section B — for loop

**P6. FizzBuzz for DE** *(Easy)*
Loop from 1 to 30. Print:
- `"Batch"` if divisible by 3
- `"Window"` if divisible by 5
- `"BatchWindow"` if divisible by both
- the number itself otherwise

---

**P7. Phone Number Extractor** *(Medium)*
```python
phone_numbers = [
    '+91 9393993937',
    '+1 9393993399',
    '+201 9339034252',
    '8838383800',
    '+2103838383830'
]
```
For each number:
1. Remove spaces
2. Extract the last 10 digits
3. Cast to `int`
4. Append to an output list

Expected output: `[9393993937, 9393993399, 9339034252, 8838383800, 3838383830]`

---

**P8. Email Domain Filter** *(Medium)*
```python
emails = [
    'abc@google.com',
    'hariom@dataengineeringdaily.com',
    'syed@gmail.com',
    'ashish@yahoo.com',
    'anurag@dataengineeringdaily.com'
]
```
1. Loop through emails and extract the domain (part after `@`)
2. Collect unique domains into a set
3. Print domains that are NOT `gmail.com` or `yahoo.com`
4. Count how many emails belong to `dataengineeringdaily.com`

---

**P9. Name Normalizer** *(Medium)*
```python
names = [' hAriOm ', ' wjw  lei ', 'RaHu L']
```
For each name:
1. Strip whitespace
2. Remove internal spaces
3. Apply `.title()` or `.capitalize()` to get proper case

Expected output: `['Hariom', 'Wjwlei', 'Rahul']`

---

**P10. Order Filename Generator** *(Medium)*
```python
order_ids = [393993, 773773, 393939]
```
Loop and build: `['order_393993.csv', 'order_773773.csv', 'order_393939.csv']`

Then do the reverse — given:
```python
orders = ['order_393993.csv', 'order_773773.csv', 'order_393939.csv']
```
Extract the integer order IDs back: `[393993, 773773, 393939]`

---

**P11. Column SQL Builder** *(Medium-Hard)*
```python
columns = ["id", "name", "salary", "department", "hire_date"]
table   = "employees"
filter_dept = "Engineering"
```
Using a for loop and string join, build this SQL:
```sql
SELECT id, name, salary, department, hire_date FROM employees WHERE department = 'Engineering';
```

---

**P12. Batch Processor** *(Hard)*
```python
records = list(range(1, 51))   # 50 records
batch_size = 10
```
Using a for loop with `range(start, stop, step)`:
1. Slice records into batches of 10
2. Print each batch with its batch number
3. Print total number of batches processed

Expected output:
```
Batch 1: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
Batch 2: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
...
Batch 5: [41, 42, 43, 44, 45, 46, 47, 48, 49, 50]
Total batches: 5
```

---

## Section C — while loop

**P13. Countdown Timer** *(Easy)*
```python
count = 10
```
Use a while loop to count down from 10 to 1, then print `"Go!"`.

---

**P14. Retry Connection** *(Medium)*
```python
max_retries = 5
```
Simulate a DB connection retry loop:
- On attempt 1, 2, 3 → print `"Attempt <n>: connection failed"`
- On attempt 4 → print `"Attempt 4: connected!"` and stop

Use a while loop with a counter and a `break` when connected.

---

**P15. Pagination Simulator** *(Medium)*
```python
total_records = 237
page_size     = 50
page          = 1
```
Use a while loop to simulate paginating through records:
- Each iteration fetches `page_size` records (or fewer on the last page)
- Print: `"Page 1: records 1–50"`, `"Page 2: records 51–100"`, etc.
- Stop when all records are fetched

---

**P16. Number Guessing Loop** *(Medium)*
```python
secret = 42
guesses = [10, 75, 42, 88]   # simulate user input
```
Use a while loop over the guesses list:
- If guess < secret → `"Too low"`
- If guess > secret → `"Too high"`
- If guess == secret → `"Correct! Found in <n> attempts"` and stop

---

## Section D — Mixed (if + for + while)

**P17. Data Quality Scanner** *(Hard)*
```python
rows = [
    {"id": 1,  "name": "Alice",   "salary": 95000,    "dept": "Engineering"},
    {"id": 2,  "name": "",        "salary": 72000,     "dept": "Finance"},
    {"id": 3,  "name": "Carol",   "salary": -1,        "dept": "Data"},
    {"id": 4,  "name": "Dave",    "salary": 110000,    "dept": ""},
    {"id": 5,  "name": "  Eve  ", "salary": 88000,     "dept": "Engineering"},
]
```
For each row:
1. Strip whitespace from `name`
2. Flag `name` as `"INVALID"` if empty after strip
3. Flag `salary` as invalid if `<= 0`
4. Flag `dept` as `"UNKNOWN"` if empty
5. Print a summary line and count total invalid rows

---

**P18. Log Level Counter** *(Medium-Hard)*
```python
logs = [
    "INFO  | Pipeline started",
    "INFO  | Ingesting file employees.csv",
    "ERROR | File not found: orders.csv",
    "INFO  | Transform complete",
    "WARN  | Null values in salary column",
    "ERROR | DB write failed",
    "INFO  | Pipeline finished",
]
```
Using a for loop with if/elif:
1. Count INFO, WARN, ERROR lines separately
2. Print counts at the end
3. Print the message text of every ERROR line
4. If ERROR count > 1 → print `"Pipeline unstable"`

---

**P19. File Inventory** *(Hard)*
```python
paths = [
    "/data/raw/2024/01/employees.csv",
    "/data/raw/2024/02/employees.csv",
    "/data/processed/2024/01/employees_clean.parquet",
    "/data/raw/2024/03/orders.csv",
    "/data/processed/2024/02/orders_clean.parquet",
    "/data/raw/2024/01/products.json",
]
```
Using for loops and if/else:
1. Separate paths into `raw` and `processed` lists based on the path
2. Count files by extension (`csv`, `parquet`, `json`)
3. Extract unique months from all raw CSV files
4. Print a summary report:
```
Raw files: 4
Processed files: 2
CSV: 3 | Parquet: 2 | JSON: 1
Months in raw CSVs: ['01', '02', '03']
```

---

**P20. Schema Migration Checker** *(Hard)*
```python
old_schema = ["id", "name", "salary", "department", "hire_date"]
new_schema = ["id", "name", "salary", "email", "phone", "hire_date"]
```
Using for loops and set operations:
1. Find columns added in new schema
2. Find columns removed in new schema
3. For each added column → print `"ADDED: <col> — add column migration needed"`
4. For each removed column → print `"DROPPED: <col> — check dependent queries"`
5. If no changes → print `"Schemas match — no migration needed"`

> This is exactly the kind of check a data engineer writes before running an ALTER TABLE in production.
