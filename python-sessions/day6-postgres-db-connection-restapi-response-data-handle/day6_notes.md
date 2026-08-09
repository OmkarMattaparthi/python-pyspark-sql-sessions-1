# Day 6 Notes — PostgreSQL Connection, API Response to DB, Insert Records

## Topics Covered
1. What is PostgreSQL and why use it
2. Connecting to PostgreSQL using `psycopg2`
3. Reading credentials from `.env` file
4. Creating tables
5. Inserting records (single and bulk)
6. Querying data
7. Converting API JSON response → DB rows
8. Full pipeline: Fetch API → Parse → Insert to DB

---

## 1. What is PostgreSQL

- **Relational database** — stores data in tables with rows and columns
- **Open source** — free and production-grade
- Supports **SQL** — `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE TABLE`
- Used widely in data engineering for staging, bronze/silver layers, analytics

### Key concepts

| Term | Meaning |
|------|---------|
| Database | Container — holds all your tables |
| Schema | Namespace inside a database (like a folder) |
| Table | Stores rows of data with fixed columns |
| Row | One record |
| Column | One field in a record |
| Primary Key | Unique identifier for each row |

---

## 2. The `psycopg2` Library

`psycopg2` is the standard Python library for connecting to PostgreSQL.

```bash
pip install psycopg2-binary
```

### Basic connection

```python
import psycopg2

conn = psycopg2.connect(
    host     = "localhost",
    port     = 5432,
    dbname   = "weekend-project",
    user     = "postgres",
    password = "hariom"
)

cursor = conn.cursor()

print("Connected to PostgreSQL!")

cursor.close()
conn.close()
```

### Key objects

| Object | Purpose |
|--------|---------|
| `conn` | The connection to the database |
| `cursor` | Executes SQL queries |
| `conn.commit()` | Saves changes (INSERT/UPDATE/DELETE need this) |
| `conn.rollback()` | Undo changes if something went wrong |
| `conn.close()` | Close the connection when done |

> **Rule:** Always close your connection when done. Use a `try/finally` or `with` block to guarantee it.

---

## 3. Reading Credentials from `.env`

Never hardcode DB credentials in your code. Store them in a `.env` file and read with `python-dotenv`.

```bash
pip install python-dotenv
```

**.env file:**
```
PG_HOST=localhost
PG_PORT=5432
PG_DBNAME=weekend-project
PG_USER=postgres
PG_PASSWORD=hariom
```

**Python:**
```python
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv("config/.env")   # loads .env into environment variables

conn = psycopg2.connect(
    host     = os.getenv("PG_HOST"),
    port     = int(os.getenv("PG_PORT")),
    dbname   = os.getenv("PG_DBNAME"),
    user     = os.getenv("PG_USER"),
    password = os.getenv("PG_PASSWORD")
)
print("Connected!")
conn.close()
```

> **DE rule:** `.env` files go in `.gitignore` — never commit credentials to GitHub.

---

## 4. Creating a Table

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost", port=5432,
    dbname="weekend-project", user="postgres", password="hariom"
)
cursor = conn.cursor()

create_table_sql = """
CREATE TABLE IF NOT EXISTS employees (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100),
    department  VARCHAR(100),
    salary      NUMERIC(10, 2),
    hire_date   DATE,
    created_at  TIMESTAMP DEFAULT NOW()
);
"""

cursor.execute(create_table_sql)
conn.commit()
print("Table created!")

cursor.close()
conn.close()
```

### Common column types

| PostgreSQL Type | Python Type | Use for |
|----------------|-------------|---------|
| `SERIAL` | auto int | Auto-incrementing primary key |
| `INT` | `int` | Integer numbers |
| `NUMERIC(10,2)` | `float` | Money, precise decimals |
| `VARCHAR(n)` | `str` | Text up to n characters |
| `TEXT` | `str` | Unlimited text |
| `DATE` | `datetime.date` | Dates only |
| `TIMESTAMP` | `datetime.datetime` | Date + time |
| `BOOLEAN` | `bool` | True/False |
| `JSONB` | `dict` | JSON data stored in DB |

---

## 5. Inserting Records

### Insert a single row

```python
cursor.execute(
    """
    INSERT INTO employees (name, department, salary, hire_date)
    VALUES (%s, %s, %s, %s)
    """,
    ("Alice Johnson", "Engineering", 95000.00, "2022-03-15")
)
conn.commit()
print("1 row inserted")
```

> **Important:** Always use `%s` placeholders — NEVER build SQL by string concatenation. That causes SQL injection.

### Insert multiple rows — `executemany`

```python
employees = [
    ("Bob Smith",   "Sales",        72000.00, "2021-07-01"),
    ("Carol White", "Data",         88000.00, "2023-01-10"),
    ("Dave Brown",  "Engineering", 102000.00, "2020-11-20"),
    ("Eve Davis",   "HR",           65000.00, "2022-08-05"),
]

cursor.executemany(
    """
    INSERT INTO employees (name, department, salary, hire_date)
    VALUES (%s, %s, %s, %s)
    """,
    employees
)
conn.commit()
print(f"{cursor.rowcount} rows inserted")
```

### Insert and get back the new ID

```python
cursor.execute(
    """
    INSERT INTO employees (name, department, salary, hire_date)
    VALUES (%s, %s, %s, %s)
    RETURNING id
    """,
    ("Frank Miller", "Sales", 78000.00, "2021-04-12")
)
new_id = cursor.fetchone()[0]
conn.commit()
print(f"Inserted row with id = {new_id}")
```

---

## 6. Querying Data

### Fetch all rows

```python
cursor.execute("SELECT id, name, department, salary FROM employees")
rows = cursor.fetchall()        # list of tuples

for row in rows:
    print(row)
# (1, 'Alice Johnson', 'Engineering', 95000.00)
# (2, 'Bob Smith', 'Sales', 72000.00)
```

### Fetch as dict using RealDictCursor

```python
import psycopg2.extras

conn = psycopg2.connect(...)
cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

cursor.execute("SELECT * FROM employees")
rows = cursor.fetchall()        # list of dicts

for row in rows:
    print(row["name"], row["department"])
```

### Filter with WHERE

```python
cursor.execute(
    "SELECT name, salary FROM employees WHERE department = %s",
    ("Engineering",)        # note: single-value tuple needs trailing comma
)
rows = cursor.fetchall()
for row in rows:
    print(row)
```

### fetchone vs fetchall vs fetchmany

```python
cursor.execute("SELECT * FROM employees ORDER BY salary DESC")

first     = cursor.fetchone()       # one row as tuple
top_five  = cursor.fetchmany(5)     # next 5 rows
rest      = cursor.fetchall()       # all remaining rows
```

---

## 7. Converting API JSON Response → DB Rows

Real-world pattern: fetch from API → parse JSON → insert each record into DB.

```python
import requests
import psycopg2

# Step 1: Fetch from API
response = requests.get("https://jsonplaceholder.typicode.com/users", timeout=10)
response.raise_for_status()
users = response.json()     # list of dicts

# Step 2: Connect to DB
conn = psycopg2.connect(
    host="localhost", port=5432,
    dbname="weekend-project", user="postgres", password="hariom"
)
cursor = conn.cursor()

# Step 3: Create table
cursor.execute("""
    CREATE TABLE IF NOT EXISTS api_users (
        id       INT PRIMARY KEY,
        name     VARCHAR(100),
        username VARCHAR(100),
        email    VARCHAR(150),
        company  VARCHAR(150)
    )
""")

# Step 4: Insert each API record
for user in users:
    cursor.execute(
        """
        INSERT INTO api_users (id, name, username, email, company)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (id) DO NOTHING
        """,
        (
            user["id"],
            user["name"],
            user["username"],
            user["email"],
            user["company"]["name"]     # nested key
        )
    )

conn.commit()
print(f"Inserted {len(users)} users into api_users table")

cursor.close()
conn.close()
```

> `ON CONFLICT (id) DO NOTHING` — safe re-run: if the row already exists, skip it instead of crashing.

---

## 8. Upsert — Insert or Update

When re-running a pipeline, records may already exist. Use upsert to update existing rows.

```python
cursor.execute(
    """
    INSERT INTO api_users (id, name, username, email, company)
    VALUES (%s, %s, %s, %s, %s)
    ON CONFLICT (id) DO UPDATE SET
        name    = EXCLUDED.name,
        email   = EXCLUDED.email,
        company = EXCLUDED.company
    """,
    (user["id"], user["name"], user["username"], user["email"], user["company"]["name"])
)
```

> `EXCLUDED` refers to the row that was rejected by the conflict — it holds the new values you tried to insert.

---

## 9. Using `with` for Safe Connection Handling

```python
import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost", port=5432,
        dbname="weekend-project", user="postgres", password="hariom"
    )
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM employees")
    count = cursor.fetchone()[0]
    print(f"Total employees: {count}")

    conn.commit()

except psycopg2.Error as e:
    print(f"DB Error: {e}")
    conn.rollback()

finally:
    cursor.close()
    conn.close()
```

---

## 10. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| `psycopg2.connect()` | Connect to staging/warehouse DB from Python pipeline |
| `.env` for credentials | Never hardcode — always load from environment |
| `CREATE TABLE IF NOT EXISTS` | Idempotent setup — safe to run multiple times |
| `%s` placeholders | SQL injection prevention — always use parameterized queries |
| `executemany()` | Bulk insert — much faster than looping `execute()` |
| `ON CONFLICT DO NOTHING` | Safe re-runs — skip already-loaded records |
| `ON CONFLICT DO UPDATE` | Upsert — update records that changed since last load |
| `RealDictCursor` | Get rows as dicts — easier to work with than tuples |
| `try/finally` | Always close connection — prevents connection leaks |
| API → parse → insert | Core ingestion pattern: every REST API pipeline does this |
