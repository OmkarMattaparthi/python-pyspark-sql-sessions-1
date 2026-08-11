# Day 7 Practice Problems — Python Functions

Difficulty: Medium to Hard. No solutions provided — work through the logic.

---

## Section A — Basic Functions

**P1. Greet Pipeline** *(Easy)*

Write a function `greet(name, role="Data Engineer")` that prints:
`"Hello Alice, welcome to the Data Engineering team!"`

Call it:
1. With only a name — role should default to `"Data Engineer"`
2. With name and a custom role `"ML Engineer"`

---

**P2. Area Calculator** *(Easy)*

Write three functions:
- `area_circle(radius)` → `π * r²`
- `area_rectangle(length, width)` → `l * w`
- `area_triangle(base, height)` → `0.5 * b * h`

Each should `return` the result (not just print). Call each and print the output.

---

**P3. Min, Max, Average** *(Easy-Medium)*

Write a function `stats(numbers)` that returns a tuple of:
`(minimum, maximum, average)`

Call it with `[45, 82, 91, 37, 76, 65, 88, 54]` and unpack the result:
```python
low, high, avg = stats([45, 82, 91, 37, 76, 65, 88, 54])
print(f"Min: {low} | Max: {high} | Avg: {avg:.2f}")
```

---

## Section B — Arguments

**P4. Flexible Sum** *(Medium)*

Write a function `total(*numbers)` that:
1. Accepts any number of integers
2. Returns their sum
3. Also prints how many numbers were passed

Test with:
```python
total(1, 2, 3)
total(10, 20, 30, 40, 50)
total(7)
```

---

**P5. Pipeline Config Builder** *(Medium)*

Write a function `build_config(pipeline_name, **options)` that:
1. Starts with a base dict: `{"name": pipeline_name, "env": "prod", "retry": 3}`
2. Updates it with any kwargs passed
3. Returns the final config dict

```python
cfg = build_config("etl_orders", env="dev", batch_size=500, timeout=30)
print(cfg)
# {"name": "etl_orders", "env": "dev", "retry": 3, "batch_size": 500, "timeout": 30}
```

---

**P6. Column Normalizer** *(Medium)*

Write a function `normalize_column(name, lower=True, replace_spaces=True, strip=True)` that:
1. Strips whitespace if `strip=True`
2. Converts to lowercase if `lower=True`
3. Replaces spaces with `_` if `replace_spaces=True`
4. Returns the cleaned name

Test with:
```python
normalize_column("  Employee ID  ")      # "employee_id"
normalize_column("FIRST NAME")           # "first_name"
normalize_column("Salary", lower=False)  # "Salary"
```

---

## Section C — Lambda Functions

**P7. Lambda Basics** *(Easy)*

Write lambdas for:
1. Square a number: `square = lambda x: ...`
2. Add two numbers: `add = lambda a, b: ...`
3. Check if a number is even: `is_even = lambda x: ...` (returns True/False)
4. Capitalize first letter: `cap = lambda s: ...`

Test each one.

---

**P8. Sort with Lambda** *(Medium)*

```python
employees = [
    {"name": "Dave",  "salary": 102000, "dept": "Engineering"},
    {"name": "Alice", "salary": 95000,  "dept": "Engineering"},
    {"name": "Bob",   "salary": 72000,  "dept": "Sales"},
    {"name": "Carol", "salary": 88000,  "dept": "Data"},
    {"name": "Eve",   "salary": 65000,  "dept": "HR"},
]
```

Using `sorted()` with lambda:
1. Sort by salary ascending
2. Sort by salary descending
3. Sort by department name alphabetically
4. Sort by department first, then by salary descending within each dept

---

**P9. Filter Files with Lambda** *(Medium)*

```python
files = [
    "employees.csv", "orders.json", "products.csv",
    "audit.txt", "payments.parquet", "sessions.csv"
]
```

Using lambda with `filter()`:
1. Get only `.csv` files
2. Get only files that start with a vowel
3. Get files with more than 8 characters in the name (excluding extension)

---

## Section D — Copy vs Deep Copy

**P10. Reference vs Copy** *(Medium)*

```python
from copy import copy, deepcopy

config = {"db": "postgres", "tables": ["orders", "users"]}
```

1. Create `config2 = config` (reference)
2. Create `config3 = copy(config)` (shallow)
3. Create `config4 = deepcopy(config)` (deep)
4. Append `"payments"` to `config["tables"]`
5. Print `config2["tables"]`, `config3["tables"]`, `config4["tables"]`
6. Explain in a comment which ones changed and why

---

**P11. Safe Pipeline Config** *(Medium-Hard)*

```python
from copy import deepcopy

base_config = {
    "source": "postgres",
    "target": "s3",
    "options": {"batch_size": 500, "retry": 3, "timeout": 30}
}
```

Write a function `get_pipeline_config(overrides: dict) -> dict` that:
1. Deep copies `base_config`
2. Updates the copy with any overrides passed
3. Returns the modified copy

Ensure the original `base_config` is never modified:
```python
cfg1 = get_pipeline_config({"options": {"batch_size": 1000}})
cfg2 = get_pipeline_config({"target": "redshift"})
print(base_config)  # must still be original
```

---

## Section E — Mixed / Hard

**P12. Validation Function** *(Medium-Hard)*

Write a function `validate_record(record: dict) -> tuple`:

Rules:
- `name` must not be empty after strip
- `salary` must be a positive number
- `department` must be in `["Engineering", "Data", "Sales", "HR", "Finance"]`

Returns `(True, None)` if valid, `(False, "reason")` if invalid.

```python
records = [
    {"name": "Alice",   "salary": 95000,  "department": "Engineering"},
    {"name": "  ",      "salary": 72000,  "department": "Sales"},
    {"name": "Carol",   "salary": -1,     "department": "Data"},
    {"name": "Dave",    "salary": 88000,  "department": "Marketing"},
]

for r in records:
    valid, reason = validate_record(r)
    print(f"{r['name'].strip() or 'EMPTY'} → {'VALID' if valid else f'INVALID: {reason}'}")
```

---

**P13. Batch Processor Function** *(Hard)*

Write a function `process_in_batches(records, batch_size, process_fn)`:
1. Splits `records` into chunks of `batch_size`
2. Calls `process_fn(batch)` for each chunk
3. Collects and returns all results

```python
def mock_insert(batch):
    print(f"Inserting batch of {len(batch)} records")
    return len(batch)

records = list(range(1, 26))  # 25 records
results = process_in_batches(records, batch_size=10, process_fn=mock_insert)
print(f"Total inserted: {sum(results)}")
# Inserting batch of 10 records
# Inserting batch of 10 records
# Inserting batch of 5 records
# Total inserted: 25
```

---

**P14. Retry Decorator Function** *(Hard)*

Write a function `with_retry(fn, max_retries=3, *args, **kwargs)` that:
1. Calls `fn(*args, **kwargs)`
2. If it raises an exception, retries up to `max_retries` times
3. Prints `"Attempt X failed: <error>"` on each failure
4. Returns the result if successful, raises after max retries

```python
import random

def flaky_api_call():
    if random.random() < 0.7:    # fails 70% of the time
        raise ConnectionError("API timeout")
    return "success"

result = with_retry(flaky_api_call, max_retries=5)
print(result)
```
