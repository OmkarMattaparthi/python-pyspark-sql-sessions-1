# Day 8 Notes — filter, map, reduce, copy, deepcopy

## Topics Covered
1. map()
2. filter()
3. reduce()
4. copy vs deepcopy (recap + deeper dive)
5. Combining map, filter, reduce

---

## 1. map()

`map()` applies a function to **every item** in an iterable and returns a map object (convert to list to see results).

```python
# Syntax: map(function, iterable)

numbers = [1, 2, 3, 4, 5, 6]

# Using lambda
squares = map(lambda x: x * x, numbers)
print(list(squares))    # [1, 4, 9, 16, 25, 36]

# Using a named function
def square(x):
    return x * x

result = map(square, numbers)
print(list(result))     # [1, 4, 9, 16, 25, 36]
```

### map() on a list of dicts

```python
employees = [
    {"name": "Alice", "salary": 95000},
    {"name": "Bob",   "salary": 72000},
    {"name": "Carol", "salary": 88000},
]

# Extract just the names
names = list(map(lambda e: e["name"], employees))
print(names)    # ["Alice", "Bob", "Carol"]

# Apply 10% salary raise to all
raised = list(map(lambda e: {**e, "salary": e["salary"] * 1.10}, employees))
print(raised)
```

### map() for data cleaning

```python
raw_columns = ["  employee id  ", "FIRST NAME", "Salary (USD)"]

cleaned = list(map(lambda c: c.strip().lower().replace(" ", "_"), raw_columns))
print(cleaned)   # ["employee_id", "first_name", "salary_(usd)"]
```

> **DE use case:** Apply a transformation to every row in a dataset — normalize column names, cast types, add derived fields.

---

## 2. filter()

`filter()` keeps only the items for which the function returns `True`.

```python
# Syntax: filter(function, iterable)

numbers = [1, 2, 3, 4, 5, 6]

# Keep only even numbers
evens = filter(lambda x: x % 2 == 0, numbers)
print(list(evens))    # [2, 4, 6]
```

### filter() on files

```python
files = ["abc.csv", "def.json", "query.txt", "load.csv", "schema.parquet"]

# Keep only CSV files
csv_files = filter(lambda f: f.split(".")[-1] == "csv", files)
print(list(csv_files))    # ["abc.csv", "load.csv"]

# Or using endswith
csv_files = filter(lambda f: f.endswith(".csv"), files)
```

### filter() on list of dicts

```python
employees = [
    {"name": "Amit",  "salary": 50000},
    {"name": "Rahul", "salary": 75000},
    {"name": "Priya", "salary": 90000},
    {"name": "Raj",   "salary": 45000},
]

# Keep employees earning more than 60000
high_earners = list(filter(lambda e: e["salary"] > 60000, employees))
print(high_earners)
# [{"name": "Rahul", "salary": 75000}, {"name": "Priya", "salary": 90000}]
```

### filter() with a named function

```python
def is_valid_employee(employee):
    return employee.get("salary") and employee["salary"] > 60000

result = list(filter(is_valid_employee, employees))
```

> **DE use case:** Filter out null rows, invalid records, rows outside a date range, records that don't match schema.

---

## 3. reduce()

`reduce()` collapses a list into a **single value** by applying a function cumulatively.

```python
from functools import reduce

# Syntax: reduce(function, iterable)

numbers = [1, 2, 3, 4, 5, 6]

# Sum all numbers
total = reduce(lambda a, b: a + b, numbers)
# Steps: 1+2=3, 3+3=6, 6+4=10, 10+5=15, 15+6=21
print(total)    # 21
```

### reduce() to find max value

```python
numbers = [10, 45, 23, 89, 12]

# Compare pairs and keep the larger
max_val = reduce(lambda a, b: a if a > b else b, numbers)
# Steps: max(10,45)=45, max(45,23)=45, max(45,89)=89, max(89,12)=89
print(max_val)    # 89
```

### reduce() to build a string

```python
words = ["Data", "Engineering", "Pipeline"]

sentence = reduce(lambda a, b: a + " " + b, words)
print(sentence)    # "Data Engineering Pipeline"
```

### reduce() with an initial value

```python
numbers = [1, 2, 3, 4, 5]

# Start from 100 and subtract all numbers
result = reduce(lambda a, b: a - b, numbers, 100)
# 100-1=99, 99-2=97, 97-3=94, 94-4=90, 90-5=85
print(result)    # 85
```

> **DE use case:** Aggregate total revenue, find max/min across records, merge a list of dicts into one.

---

## 4. map vs filter vs reduce — Quick Comparison

| Function | Input | Output | Purpose |
|----------|-------|--------|---------|
| `map()` | list of N items | list of N items | Transform every item |
| `filter()` | list of N items | list of ≤ N items | Keep items matching condition |
| `reduce()` | list of N items | 1 single value | Collapse list to one result |

```python
numbers = [1, 2, 3, 4, 5, 6]

# map    — double each: [2, 4, 6, 8, 10, 12]
# filter — keep evens:  [2, 4, 6]
# reduce — sum all:     21
```

---

## 5. copy vs deepcopy

### The problem with direct assignment

```python
list1 = [1, 2, 3, [4, 5]]
list2 = list1           # NOT a copy — same object in memory

list2.append(99)
print(list1)            # [1, 2, 3, [4, 5], 99]  ← list1 also changed!
```

### shallow copy — `copy()`

Creates a new outer list but **shares** nested objects.

```python
from copy import copy

list1 = [1, 2, 3, [4, 5]]
list3 = copy(list1)

list3.append(99)
print(list1)            # [1, 2, 3, [4, 5]]  ← outer unchanged

list3[3].append(99)     # modify the nested list
print(list1)            # [1, 2, 3, [4, 5, 99]]  ← nested IS shared!
```

### deep copy — `deepcopy()`

Creates a fully independent copy — nested objects are also copied.

```python
from copy import deepcopy

list1 = [1, 2, 3, [4, 5]]
list4 = deepcopy(list1)

list4[3].append(99)
print(list1)            # [1, 2, 3, [4, 5]]  ← completely unchanged
```

### Visual summary

```
list1 = [1, 2, 3, [4, 5]]
          │           │
          ▼           ▼
       outer         inner list (nested)

list2 = list1           → points to SAME outer AND inner
list3 = copy(list1)     → NEW outer, SAME inner
list4 = deepcopy(list1) → NEW outer, NEW inner
```

### When to use which

| Situation | Use |
|-----------|-----|
| Simple flat list/dict, no nesting | `copy()` |
| Nested structures (list of lists, list of dicts) | `deepcopy()` |
| You want both to reflect changes | Direct assignment `=` |
| Pipeline config passed to multiple steps | `deepcopy()` |

---

## 6. Combining map + filter + reduce

```python
from functools import reduce

employees = [
    {"name": "Amit",  "salary": 50000, "dept": "Sales"},
    {"name": "Rahul", "salary": 75000, "dept": "Data"},
    {"name": "Priya", "salary": 90000, "dept": "Data"},
    {"name": "Raj",   "salary": 45000, "dept": "HR"},
    {"name": "Neha",  "salary": 82000, "dept": "Data"},
]

# Step 1 — filter: only Data dept
data_team = filter(lambda e: e["dept"] == "Data", employees)

# Step 2 — map: extract salaries
salaries = map(lambda e: e["salary"], data_team)

# Step 3 — reduce: total salary of Data team
total = reduce(lambda a, b: a + b, salaries)

print(f"Data team total salary: {total}")    # 247000
```

---

## 7. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| `map()` | Transform every row — normalize, cast types, add fields |
| `filter()` | Remove invalid rows, nulls, out-of-range values |
| `reduce()` | Aggregate totals, find max/min across records |
| `copy()` | Safe copy of flat config/schema dicts |
| `deepcopy()` | Safe copy of nested config, pipeline step isolation |
| Chaining all three | Filter bad rows → map/transform → reduce to aggregate |
