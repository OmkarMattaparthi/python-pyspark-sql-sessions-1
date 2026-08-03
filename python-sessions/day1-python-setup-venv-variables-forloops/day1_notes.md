# Day 1 Notes — Python Fundamentals for Data Engineering

## Topics Covered
1. Python Setup & Virtual Environments
2. Variables & Data Types
3. For Loops & Iteration

---

## 1. Python Setup & Virtual Environments

### Why venv matters in Data Engineering
- Each project (PySpark, Airflow, dbt) needs different library versions.
- venv prevents version conflicts between projects.
- Reproducibility: `requirements.txt` lets teammates or CI/CD recreate the exact environment.

### Key commands recap
```python
# Check Python version from inside a script
import sys
print(sys.version)
```

---

## 2. Variables & Data Types

### Variable Assignment
```python
name = "Alice"          # str
age = 30                # int
salary = 95000.50       # float
is_active = True        # bool
nothing = None          # NoneType
```

### Naming Conventions (PEP 8)
- Use `snake_case` for variables and functions: `employee_count`, `total_sales`
- Use `UPPER_SNAKE_CASE` for constants: `MAX_RETRIES = 3`
- Avoid single-letter names except in short loops (`i`, `j`)

### Type Checking & Conversion
```python
x = "42"
print(type(x))          # <class 'str'>

x = int(x)              # cast to int
print(type(x))          # <class 'int'>

# Useful conversions
str(100)                # "100"
float("3.14")           # 3.14
bool(0)                 # False
bool("hello")           # True
```

### Data Engineering Relevance
- Schema inference in PySpark/Pandas depends on Python types.
- Reading CSV data comes in as strings — you must cast to `int`/`float`/`datetime`.
- `None` in Python maps to `NULL` in SQL and `null` in JSON.

---

## 3. Common Data Structures (used constantly in DE)

### List
```python
columns = ["id", "name", "salary", "department"]
columns.append("hire_date")
print(columns[0])           # "id"
print(columns[-1])          # "hire_date"
print(len(columns))         # 5
```

### Dictionary
```python
record = {
    "id": 1,
    "name": "Alice",
    "salary": 95000.50
}
print(record["name"])       # "Alice"
record["department"] = "Engineering"    # add key
```

### Tuple (immutable — good for fixed configs)
```python
db_config = ("localhost", 5432, "my_db")
host, port, db = db_config              # unpacking
```

### Set
```python
unique_depts = {"HR", "Engineering", "Finance", "HR"}
print(unique_depts)         # {'HR', 'Engineering', 'Finance'} — duplicates removed
```

---

## 4. For Loops & Iteration

### Basic for loop
```python
fruits = ["apple", "banana", "cherry"]
for fruit in fruits:
    print(fruit)
```

### range()
```python
for i in range(5):          # 0, 1, 2, 3, 4
    print(i)

for i in range(1, 6):       # 1, 2, 3, 4, 5
    print(i)

for i in range(0, 10, 2):   # 0, 2, 4, 6, 8
    print(i)
```

### enumerate() — get index + value
```python
columns = ["id", "name", "salary"]
for idx, col in enumerate(columns):
    print(f"{idx}: {col}")
# 0: id
# 1: name
# 2: salary
```

### Iterating over a dictionary
```python
record = {"id": 1, "name": "Alice", "salary": 95000.50}

for key in record:
    print(key)

for key, value in record.items():
    print(f"{key} = {value}")
```

### List Comprehension (Pythonic + fast)
```python
# Traditional loop
squares = []
for n in range(1, 6):
    squares.append(n ** 2)

# Comprehension — same result, one line
squares = [n ** 2 for n in range(1, 6)]
# [1, 4, 9, 16, 25]

# With condition
even_squares = [n ** 2 for n in range(1, 11) if n % 2 == 0]
# [4, 16, 36, 64, 100]
```

### Nested loop (common in DE for cross joins / matrix ops)
```python
regions = ["US", "EU"]
products = ["A", "B", "C"]

for region in regions:
    for product in products:
        print(f"{region} - {product}")
```

---

## 5. Data Engineering Patterns Using Loops

### Processing rows from a CSV (before Pandas/PySpark)
```python
import csv

with open("employees.csv") as f:
    reader = csv.DictReader(f)
    for row in reader:
        salary = float(row["salary"])
        if salary > 80000:
            print(row["name"], salary)
```

### Building a transformation pipeline manually
```python
raw_records = [
    {"name": "  Alice ", "salary": "95000"},
    {"name": "Bob",      "salary": "72000"},
]

cleaned = []
for record in raw_records:
    cleaned.append({
        "name":   record["name"].strip(),
        "salary": int(record["salary"]),
    })

print(cleaned)
```

### Aggregation with a dict (manual GROUP BY)
```python
sales = [
    {"region": "US", "amount": 100},
    {"region": "EU", "amount": 200},
    {"region": "US", "amount": 150},
]

totals = {}
for row in sales:
    region = row["region"]
    totals[region] = totals.get(region, 0) + row["amount"]

print(totals)   # {'US': 250, 'EU': 200}
```

---

## 6. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| `venv` | Isolate PySpark, Airflow, dbt environments |
| Variables & Types | Schema definitions, type casting from raw sources |
| `None` | Maps to SQL NULL — handle carefully in transforms |
| Lists / Dicts | Row-level data before loading into DataFrames |
| `for` loop | Row iteration, batch processing, config generation |
| List comprehension | Fast column transforms, filtering before PySpark |
| `enumerate` | Tracking row numbers, building indexed lookups |
| `dict.items()` | Iterating schema maps, config dicts |

---

## Practice Exercises

1. Create a list of 10 numbers. Use a loop to print only the even ones.
2. Given a list of strings (employee names), build a dictionary mapping each name to its character length.
3. Read a hardcoded list of dicts (fake employee records). Filter only those with salary > 70000 and print their names.
4. Write a list comprehension that converts a list of string salaries `["50000", "80000", "120000"]` to integers.
5. Build a manual GROUP BY — given a list of `{"dept": ..., "salary": ...}` dicts, calculate the average salary per department.
