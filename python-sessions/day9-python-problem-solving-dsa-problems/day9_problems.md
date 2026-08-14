# Day 9 Practice Problems — Python Problem Solving & DSA

Difficulty: Medium to Hard. No solutions provided — work through the logic.

---

## Section A — Short Circuit Evaluation

**P1. Safe Field Reader** *(Easy)*
```python
records = [
    {"name": "Alice",  "salary": 95000},
    {"name": "",       "salary": 72000},
    {"name": None,     "salary": 88000},
    {"name": "Dave",   "salary": 0},
]
```
For each record, use short circuit `or` to print:
- `name or "UNKNOWN"` — if name is empty/None, show UNKNOWN
- `salary or "NO SALARY"` — if salary is 0/None, show NO SALARY

---

**P2. Safe Config Loader** *(Medium)*
```python
config = {
    "host": "localhost",
    "port": None,
    "timeout": 0,
    "db": "",
}
```
Using `or` short circuit, build a final config with safe defaults:
- `port` → default `5432`
- `timeout` → default `30`
- `db` → default `"postgres"`
- `host` → use as-is (already set)

Print the final config dict.

---

## Section B — List Slicing Tricks

**P3. Slicing Puzzle** *(Medium)*
```python
list1 = [3, 5, 2, 0, 3, 0, 8, 5]
```
Using only slicing (no loops):
1. Reverse the entire list
2. Get every 2nd element starting from index 0
3. Get the last 3 elements
4. Remove the first and last element
5. Get elements from index 2 to 5 (inclusive)
6. Get `[8, 3, 0, 5]` — figure out the slice

---

**P4. Batch Window Slicer** *(Medium)*
```python
records = list(range(1, 26))   # 25 records
batch_size = 5
```
Using slicing in a loop:
1. Split into batches of 5
2. Print each batch with its batch number
3. Print total batches

```
Batch 1: [1, 2, 3, 4, 5]
Batch 2: [6, 7, 8, 9, 10]
...
Batch 5: [21, 22, 23, 24, 25]
```

---

## Section C — Recursion & Flatten

**P5. Flatten Nested List** *(Medium)*
```python
nested = [[1, 2], [3, 4], [5, 6, 7, [8, 9, [10, 11]]]]
# expected: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
```
Write `flatten(data)` using recursion and `try/except TypeError`. Test it on the above.

---

**P6. Recursive Sum** *(Medium)*
```python
data = [1, [2, 3], [4, [5, 6]], 7]
# expected total: 28
```
Write `recursive_sum(data)` that sums all numbers regardless of nesting depth.

---

**P7. Countdown with Recursion** *(Easy)*

Write `countdown(n)` that prints:
```
3
2
1
Go!
```
Base case: when `n == 0`, print `"Go!"` and return. No loops allowed.

---

**P8. Recursive Flatten JSON** *(Hard)*
```python
api_response = {
    "results": [
        {"id": 1, "tags": ["csv", "parquet"]},
        {"id": 2, "tags": ["json"]},
        {"id": 3, "tags": ["parquet", "orc", "avro"]},
    ]
}
```
Extract all tags into a single flat list: `["csv", "parquet", "json", "parquet", "orc", "avro"]`
Then get unique tags as a sorted list: `["avro", "csv", "json", "orc", "parquet"]`

---

## Section D — Data Cleaning

**P9. User Cleaner** *(Medium)*
```python
users = [
    {"id": 1, "name": "  amit sharma ", "age": 25},
    {"id": 2, "name": "RAHUL KUMAR",    "age": 30},
    {"id": 3, "name": "",               "age": 22},
    {"id": 4, "name": " priya ",        "age": None},
    {"id": 5, "name": "  raj  ",        "age": 28},
    {"id": 6, "name": "neha",           "age": -1},
]
```
Clean the list — skip and count invalid records:
1. Skip if name is empty after strip
2. Skip if age is `None`
3. Skip if age is negative
4. Strip and title-case valid names
5. Print cleaned records and: `"Removed X invalid records"`

---

**P10. Order Data Cleaner** *(Medium-Hard)*
```python
orders = [
    {"order_id": "ORD-001", "amount": 250.00,  "status": "SUCCESS",  "customer_id": 101},
    {"order_id": "ORD-002", "amount": -50.00,  "status": "success",  "customer_id": 102},
    {"order_id": "ORD-003", "amount": 0,        "status": "PENDING",  "customer_id": None},
    {"order_id": "ORD-004", "amount": 180.00,  "status": "FAILED",   "customer_id": 103},
    {"order_id": "ORD-005", "amount": 320.00,  "status": "SUCCESS",  "customer_id": 104},
    {"order_id": "",         "amount": 100.00,  "status": "SUCCESS",  "customer_id": 105},
]
```
Clean rules:
1. Skip if `order_id` is empty
2. Skip if `amount` <= 0
3. Skip if `customer_id` is `None`
4. Normalize `status` to uppercase
5. Print valid orders and count of skipped

---

## Section E — Deduplication

**P11. Deduplicate by ID** *(Medium)*
```python
customers = [
    {"id": 101, "name": "Amit",  "email": "amit@gmail.com"},
    {"id": 102, "name": "Rahul", "email": "rahul@gmail.com"},
    {"id": 101, "name": "Amit",  "email": "amit@gmail.com"},
    {"id": 103, "name": "Priya", "email": "priya@gmail.com"},
    {"id": 102, "name": "Rahul", "email": "rahul@gmail.com"},
]
```
Remove duplicates keeping the **first** occurrence. Print count before and after.

---

**P12. Deduplicate Keep Last** *(Medium)*

Same data as P11. Remove duplicates keeping the **last** occurrence (simulate "latest record wins" — CDC pattern).

---

**P13. Deduplicate on Multiple Keys** *(Hard)*
```python
transactions = [
    {"order_id": "ORD-001", "customer_id": 101, "amount": 250.00},
    {"order_id": "ORD-002", "customer_id": 102, "amount": 180.00},
    {"order_id": "ORD-001", "customer_id": 101, "amount": 250.00},   # duplicate
    {"order_id": "ORD-003", "customer_id": 101, "amount": 320.00},
    {"order_id": "ORD-002", "customer_id": 102, "amount": 180.00},   # duplicate
]
```
Deduplicate on the combination of `(order_id, customer_id)`. Keep first occurrence.

---

## Section F — Mixed Hard Problems

**P14. Pipeline Log Analyzer** *(Hard)*
```python
logs = [
    "2024-01-15 | INFO  | Pipeline started    | rows=0",
    "2024-01-15 | INFO  | Ingestion complete  | rows=1500",
    "2024-01-15 | ERROR | Validation failed   | rows=1500",
    "2024-01-15 | INFO  | Transform complete  | rows=1480",
    "2024-01-15 | ERROR | DB write failed     | rows=0",
    "2024-01-15 | INFO  | Pipeline finished   | rows=1480",
]
```
1. Parse each line into `{date, level, message, rows}` (split on `" | "`)
2. Extract `rows` as int from `"rows=1500"`
3. Use `break` to stop at the first ERROR and print its message
4. Use `continue` to skip INFO lines and collect only ERROR and WARN lines
5. Print total rows from the last INFO line

---

**P15. Inventory Reconciler** *(Hard)*
```python
expected = [
    {"sku": "A001", "qty": 100},
    {"sku": "A002", "qty": 50},
    {"sku": "A003", "qty": 75},
    {"sku": "A004", "qty": 30},
]
actual = [
    {"sku": "A001", "qty": 95},
    {"sku": "A002", "qty": 50},
    {"sku": "A004", "qty": 35},
    {"sku": "A005", "qty": 20},
]
```
1. Find SKUs in `expected` but missing from `actual` — `"MISSING"`
2. Find SKUs in `actual` but not in `expected` — `"UNEXPECTED"`
3. Find SKUs in both where `qty` differs — `"MISMATCH"`
4. Find SKUs in both where `qty` matches — `"OK"`
5. Print a reconciliation report
