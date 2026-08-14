# Day 10 Notes — Advanced Problem Solving & Deployment

## Topics Covered
1. List Comprehensions
2. Dictionary Comprehensions
3. Exception Handling (try/except/finally)
4. Modules and Imports
5. Virtual Environments and requirements.txt
6. Deployment — what it means and how to structure a project
7. Running a Python project end-to-end

---

## 1. List Comprehensions

A concise way to build a list using a single line — replaces `for` loop + `append`.

```python
# Regular loop
squares = []
for x in range(1, 6):
    squares.append(x * x)

# List comprehension — same result
squares = [x * x for x in range(1, 6)]
print(squares)    # [1, 4, 9, 16, 25]
```

### With condition (filter inside comprehension)

```python
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Keep only even numbers
evens = [n for n in numbers if n % 2 == 0]
print(evens)    # [2, 4, 6, 8, 10]

# Square only even numbers
even_squares = [n * n for n in numbers if n % 2 == 0]
print(even_squares)    # [4, 16, 36, 64, 100]
```

### On a list of dicts

```python
employees = [
    {"name": "Alice", "dept": "Engineering", "salary": 95000},
    {"name": "Bob",   "dept": "Sales",       "salary": 72000},
    {"name": "Carol", "dept": "Engineering", "salary": 88000},
]

# Extract names
names = [e["name"] for e in employees]

# Filter Engineering only
eng = [e for e in employees if e["dept"] == "Engineering"]

# Build new list with raise applied
raised = [{**e, "salary": e["salary"] * 1.10} for e in employees]
```

### Flatten nested list with comprehension

```python
nested = [[1, 2], [3, 4], [5, 6]]
flat = [item for sublist in nested for item in sublist]
print(flat)    # [1, 2, 3, 4, 5, 6]
```

---

## 2. Dictionary Comprehensions

Build a dict in one line.

```python
# Squares dict: {1: 1, 2: 4, 3: 9, ...}
squares = {x: x * x for x in range(1, 6)}
print(squares)    # {1: 1, 2: 4, 3: 9, 4: 16, 5: 25}

# Invert a dict
status_codes = {200: "OK", 201: "Created", 404: "Not Found"}
inverted = {v: k for k, v in status_codes.items()}
print(inverted)   # {"OK": 200, "Created": 201, "Not Found": 404}

# Filter dict — keep only high earners
employees = {"Alice": 95000, "Bob": 72000, "Carol": 88000}
high = {name: sal for name, sal in employees.items() if sal > 80000}
print(high)   # {"Alice": 95000, "Carol": 88000}
```

### Build lookup dict from list of dicts

```python
users = [
    {"id": 1, "name": "Alice"},
    {"id": 2, "name": "Bob"},
    {"id": 3, "name": "Carol"},
]

# id → user lookup
user_map = {u["id"]: u for u in users}
print(user_map[2])    # {"id": 2, "name": "Bob"}
```

> **DE use case:** Build fast O(1) lookup dicts to join data from two API responses without nested loops.

---

## 3. Exception Handling

Handle errors gracefully so your pipeline doesn't crash on bad data.

```python
# Basic try/except
try:
    result = 10 / 0
except ZeroDivisionError as e:
    print(f"Error: {e}")

# Multiple exception types
try:
    value = int("abc")
except ValueError as e:
    print(f"ValueError: {e}")
except TypeError as e:
    print(f"TypeError: {e}")

# Generic exception catch-all
try:
    data = {}
    print(data["missing_key"])
except Exception as e:
    print(f"Something went wrong: {e}")

# finally — always runs (cleanup)
conn = None
try:
    conn = psycopg2.connect(...)
    # do work
except Exception as e:
    print(f"DB error: {e}")
finally:
    if conn:
        conn.close()    # always close even if error
```

### try/except inside a loop — skip bad records

```python
records = ["100", "200", "abc", "300", None]
parsed = []

for r in records:
    try:
        parsed.append(int(r))
    except (ValueError, TypeError):
        print(f"Skipping invalid record: {r}")

print(parsed)    # [100, 200, 300]
```

> **DE rule:** Never let one bad record crash the entire pipeline. Wrap per-row processing in try/except and log the bad record.

---

## 4. Modules and Imports

Split code into multiple files — each file is a **module**.

```
project/
├── config.py       ← settings, credentials
├── db.py           ← database connection logic
├── api.py          ← API fetching logic
├── transform.py    ← data cleaning/transformation
└── main.py         ← entry point — runs everything
```

### Importing from another file

```python
# config.py
DB_HOST = "localhost"
DB_PORT = 5432
DB_NAME = "warehouse"

# db.py
import config
import psycopg2

conn = psycopg2.connect(
    host=config.DB_HOST,
    port=config.DB_PORT,
    dbname=config.DB_NAME
)
```

### Import specific names

```python
from config import DB_HOST, DB_PORT
from db import get_connection
from transform import clean_record
```

### Useful built-in modules

| Module | Use |
|--------|-----|
| `os` | File paths, environment variables |
| `json` | Read/write JSON |
| `csv` | Read/write CSV |
| `time` | Sleep, measure elapsed time |
| `datetime` | Date and time operations |
| `functools` | `reduce()`, `partial()` |
| `collections` | `Counter`, `defaultdict` |
| `re` | Regular expressions |

---

## 5. Virtual Environments and requirements.txt

### Why virtual environments

Each project has its own package versions — isolated from other projects.

```bash
# Create venv
python -m venv venv

# Activate — Windows
venv\Scripts\activate

# Activate — Mac/Linux
source venv/bin/activate

# Install packages
pip install requests psycopg2-binary python-dotenv

# Save installed packages to file
pip freeze > requirements.txt

# Install from requirements.txt (on a new machine or for a teammate)
pip install -r requirements.txt
```

### requirements.txt example

```
requests==2.32.3
psycopg2-binary==2.9.9
python-dotenv==1.0.1
pyspark==3.5.3
```

> **DE rule:** Always commit `requirements.txt` to git — never commit the `venv/` folder itself (add to `.gitignore`).

---

## 6. Deployment — Project Structure

A deployable Python project follows a standard layout:

```
my-pipeline/
├── .env                  ← credentials (NOT committed to git)
├── .gitignore            ← excludes venv/, .env, __pycache__/
├── requirements.txt      ← all dependencies
├── README.md             ← how to run the project
├── config/
│   └── settings.py       ← loads .env, defines constants
├── src/
│   ├── api.py            ← fetch data from API
│   ├── transform.py      ← clean and transform
│   ├── db.py             ← DB connection and queries
│   └── utils.py          ← helper functions
├── data/
│   ├── raw/              ← raw API responses saved here
│   └── processed/        ← cleaned data
└── main.py               ← entry point — orchestrates the pipeline
```

### .gitignore for Python projects

```
venv/
__pycache__/
*.pyc
.env
data/raw/
data/processed/
*.log
```

---

## 7. Running a Project End-to-End

### main.py — orchestrator pattern

```python
import os
from dotenv import load_dotenv
from src.api import fetch_users
from src.transform import clean_users
from src.db import get_connection, insert_users

load_dotenv(".env")

def main():
    print("Step 1: Fetching data from API...")
    raw_users = fetch_users()
    print(f"  Fetched {len(raw_users)} users")

    print("Step 2: Cleaning data...")
    clean = clean_users(raw_users)
    print(f"  {len(clean)} valid records after cleaning")

    print("Step 3: Inserting into DB...")
    conn = get_connection()
    inserted = insert_users(conn, clean)
    conn.close()
    print(f"  Inserted {inserted} records")

    print("Pipeline complete.")

if __name__ == "__main__":
    main()
```

### Running the project

```bash
# Activate venv
source venv/bin/activate     # Mac/Linux
venv\Scripts\activate        # Windows

# Install dependencies
pip install -r requirements.txt

# Run
python main.py
```

---

## 8. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| List comprehension | Clean, transform rows in one line |
| Dict comprehension | Build id→record lookup maps for fast joins |
| `try/except` in loop | Skip bad records without crashing the pipeline |
| `finally` | Always close DB connections and file handles |
| Project structure | Separates concerns — each module has one job |
| `requirements.txt` | Reproducible installs across machines |
| `.env` + `.gitignore` | Credentials never go to GitHub |
| `main.py` orchestrator | One entry point — clear pipeline flow |
| `if __name__ == "__main__"` | Allows module to be imported without running |
