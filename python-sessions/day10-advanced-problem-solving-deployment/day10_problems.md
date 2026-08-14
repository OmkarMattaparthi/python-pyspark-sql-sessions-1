# Day 10 Practice Problems — Advanced Problem Solving & Deployment

Difficulty: Medium to Hard. No solutions provided — work through the logic.

---

## Section A — List Comprehensions

**P1. Comprehension Basics** *(Easy)*
```python
numbers = list(range(1, 11))
```
Using list comprehensions (one line each):
1. Squares of all numbers
2. Only odd numbers
3. Cubes of numbers divisible by 3
4. Strings: `["num_1", "num_2", ..., "num_10"]`

---

**P2. Employee Comprehensions** *(Medium)*
```python
employees = [
    {"name": "Alice", "dept": "Engineering", "salary": 95000, "active": True},
    {"name": "Bob",   "dept": "Sales",       "salary": 72000, "active": False},
    {"name": "Carol", "dept": "Data",        "salary": 88000, "active": True},
    {"name": "Dave",  "dept": "Engineering", "salary": 102000,"active": True},
    {"name": "Eve",   "dept": "HR",          "salary": 65000, "active": False},
]
```
Using list comprehensions:
1. Names of all active employees
2. All employees with salary > 80000
3. Apply 10% raise to active Engineering employees only — return updated dicts
4. List of `"Name (Dept)"` strings for active employees

---

**P3. Flatten with Comprehension** *(Medium)*
```python
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
```
1. Flatten to `[1, 2, 3, 4, 5, 6, 7, 8, 9]` using a comprehension
2. Extract only values > 5: `[6, 7, 8, 9]`
3. Transpose the matrix using nested comprehension

---

**P4. File Path Builder** *(Medium)*
```python
tables  = ["orders", "customers", "payments", "sessions"]
months  = ["2024-01", "2024-02", "2024-03"]
```
Using a list comprehension, build every combination:
```
["data/raw/orders/2024-01.json", "data/raw/orders/2024-02.json", ..., "data/raw/sessions/2024-03.json"]
```
Total: 12 paths.

---

## Section B — Dictionary Comprehensions

**P5. Dict Comprehension Basics** *(Easy)*
```python
names = ["Alice", "Bob", "Carol", "Dave"]
```
Using dict comprehensions:
1. `{name: len(name) for ...}` — name → length
2. `{name: name.upper() for ...}` — name → uppercase
3. `{i: name for i, name in enumerate(names)}` — index → name

---

**P6. Build Lookup Dict** *(Medium)*
```python
users = [
    {"id": 101, "name": "Alice", "dept": "Engineering"},
    {"id": 102, "name": "Bob",   "dept": "Sales"},
    {"id": 103, "name": "Carol", "dept": "Data"},
]
orders = [
    {"order_id": "ORD-001", "user_id": 101, "amount": 250},
    {"order_id": "ORD-002", "user_id": 102, "amount": 180},
    {"order_id": "ORD-003", "user_id": 101, "amount": 320},
]
```
1. Build `user_map = {user["id"]: user for user in users}`
2. For each order, enrich with user name and dept using `user_map`
3. Print: `"ORD-001 | Alice | Engineering | 250"`

---

**P7. Invert and Filter** *(Medium)*
```python
scores = {"Alice": 85, "Bob": 60, "Carol": 92, "Dave": 74, "Eve": 88}
```
1. Invert to `{score: name}` — what problem arises with duplicate scores?
2. Filter only scores >= 80
3. Build `{name: "Pass" if score >= 70 else "Fail" for ...}`

---

## Section C — Exception Handling

**P8. Safe Type Casting** *(Medium)*
```python
raw_values = ["100", "200.5", "abc", None, "300", "", "999"]
```
Loop through values. For each:
1. Try `int(v)` first
2. If that fails, try `float(v)`
3. If that fails, skip and log: `"Skipping invalid: <v>"`
4. Collect valid numbers in a list and print the total

---

**P9. Safe Record Inserter** *(Medium-Hard)*

Write a function `safe_insert(records, insert_fn)` that:
1. Loops through records
2. Calls `insert_fn(record)` for each
3. Catches any `Exception` per record — logs it and continues
4. Returns `(success_count, fail_count)`

Test with:
```python
def mock_insert(record):
    if record["amount"] < 0:
        raise ValueError(f"Negative amount: {record['amount']}")
    print(f"Inserted: {record['order_id']}")

records = [
    {"order_id": "ORD-001", "amount": 250},
    {"order_id": "ORD-002", "amount": -50},
    {"order_id": "ORD-003", "amount": 180},
]
ok, fail = safe_insert(records, mock_insert)
print(f"Success: {ok} | Failed: {fail}")
```

---

**P10. DB Connection with Error Handling** *(Medium)*

Write a function `get_connection(config)` that:
1. Tries to connect to PostgreSQL using `psycopg2`
2. If connection fails (`psycopg2.OperationalError`) → prints the error, returns `None`
3. If host is missing from config → raises `ValueError("host is required")`
4. On success → returns the connection

---

## Section D — Modules and Project Structure

**P11. Split into Modules** *(Medium-Hard)*

Take this single-file script and split it into a proper project structure:

```python
# everything in one file — refactor this
import requests, psycopg2, json

BASE_URL = "https://jsonplaceholder.typicode.com"
DB_CONFIG = {"host": "localhost", "port": 5432, "dbname": "practice", "user": "postgres", "password": "hariom"}

def fetch_users():
    r = requests.get(f"{BASE_URL}/users", timeout=10)
    r.raise_for_status()
    return r.json()

def clean_users(users):
    return [u for u in users if u.get("email") and "@" in u["email"]]

def insert_users(conn, users):
    cur = conn.cursor()
    for u in users:
        cur.execute("INSERT INTO users (id, name, email) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
                    (u["id"], u["name"], u["email"]))
    conn.commit()
    return len(users)

conn = psycopg2.connect(**DB_CONFIG)
users = fetch_users()
clean = clean_users(users)
count = insert_users(conn, clean)
conn.close()
print(f"Done: {count} users")
```

Create this structure:
```
day10_project/
├── config.py       ← DB_CONFIG, BASE_URL
├── api.py          ← fetch_users()
├── transform.py    ← clean_users()
├── db.py           ← insert_users(), get_connection()
└── main.py         ← orchestrates everything
```

---

## Section E — End-to-End Pipeline Problems

**P12. Full Pipeline: API → Clean → DB** *(Hard)*

Build a complete pipeline in `main.py` using the module structure from P11:

1. Load credentials from `.env`
2. Fetch users from `https://jsonplaceholder.typicode.com/users`
3. Clean: skip users with invalid emails
4. Insert into PostgreSQL `users` table (upsert)
5. Fetch posts from `/posts`
6. For each post, enrich with user name using a lookup dict (dict comprehension)
7. Insert posts into `posts` table
8. Print final summary:
   ```
   Users fetched   : 10
   Users inserted  : 10
   Posts fetched   : 100
   Posts inserted  : 100
   Pipeline done.
   ```

---

**P13. Retry Pipeline** *(Hard)*

Write `run_with_retry(pipeline_fn, max_retries=3)` that:
1. Calls `pipeline_fn()`
2. On any `Exception`, waits `2 ** attempt` seconds and retries
3. Logs each attempt: `"Attempt 1 failed: <error>. Retrying in 2s..."`
4. If all retries exhausted, raises the last exception
5. Returns the result on success

```python
import time

def flaky_pipeline():
    import random
    if random.random() < 0.6:
        raise ConnectionError("DB connection dropped")
    return "Pipeline complete"

result = run_with_retry(flaky_pipeline, max_retries=5)
print(result)
```

---

**P14. Deployment Checklist Script** *(Hard)*

Write a `preflight_check.py` script that verifies the environment before deploying:

1. Check `.env` file exists — print `"[OK] .env found"` or `"[FAIL] .env missing"`
2. Check all required env vars are set: `PG_HOST`, `PG_PORT`, `PG_DBNAME`, `PG_USER`, `PG_PASSWORD`
3. Try connecting to PostgreSQL — print `"[OK] DB connected"` or `"[FAIL] DB unreachable: <error>"`
4. Try fetching `https://jsonplaceholder.typicode.com/users` — print `"[OK] API reachable"` or `"[FAIL] API down"`
5. Print a final summary: `"Preflight passed"` or `"Preflight FAILED — fix issues above before deploying"`

---

**P15. Idempotent Pipeline** *(Hard)*

A pipeline is **idempotent** if running it multiple times gives the same result as running it once.

Write a `run_pipeline()` function that:
1. Creates the `users` table with `CREATE TABLE IF NOT EXISTS`
2. Fetches users from the API
3. Inserts with `ON CONFLICT (id) DO NOTHING` — safe to re-run
4. Logs: `"Run 1: X new rows inserted"`, `"Run 2: 0 new rows inserted"`

Run it 3 times in a loop and verify the DB count stays at 10 each time:
```python
for i in range(1, 4):
    print(f"--- Run {i} ---")
    run_pipeline()
```
