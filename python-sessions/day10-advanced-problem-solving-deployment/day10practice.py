import os
import json
import requests
import psycopg2
from dotenv import load_dotenv

load_dotenv("../../weekend-project/config/.env")

DB_CONFIG = {
    "host"    : os.getenv("PG_HOST",     "localhost"),
    "port"    : int(os.getenv("PG_PORT", 5432)),
    "dbname"  : os.getenv("PG_DBNAME",   "weekend-project"),
    "user"    : os.getenv("PG_USER",     "postgres"),
    "password": os.getenv("PG_PASSWORD", "hariom"),
}

BASE_URL = "https://jsonplaceholder.typicode.com"


# ─────────────────────────────────────────────
# 1. List Comprehensions
# ─────────────────────────────────────────────

# numbers = list(range(1, 11))

# squares = [x * x for x in numbers]
# print(squares)

# evens = [n for n in numbers if n % 2 == 0]
# print(evens)

# employees = [
#     {"name": "Alice", "dept": "Engineering", "salary": 95000, "active": True},
#     {"name": "Bob",   "dept": "Sales",       "salary": 72000, "active": False},
#     {"name": "Carol", "dept": "Data",        "salary": 88000, "active": True},
# ]

# names = [e["name"] for e in employees if e["active"]]
# print(names)

# raised = [{**e, "salary": e["salary"] * 1.10} for e in employees if e["active"]]
# print(raised)


# ─────────────────────────────────────────────
# 2. Dictionary Comprehensions
# ─────────────────────────────────────────────

# status_codes = {200: "OK", 201: "Created", 404: "Not Found"}
# inverted = {v: k for k, v in status_codes.items()}
# print(inverted)

# employees_dict = {"Alice": 95000, "Bob": 72000, "Carol": 88000}
# high_earners = {name: sal for name, sal in employees_dict.items() if sal > 80000}
# print(high_earners)


# ─────────────────────────────────────────────
# 3. Exception Handling
# ─────────────────────────────────────────────

# raw_values = ["100", "200.5", "abc", None, "300", ""]

# parsed = []
# for v in raw_values:
#     try:
#         parsed.append(int(v))
#     except (ValueError, TypeError):
#         try:
#             parsed.append(float(v))
#         except (ValueError, TypeError):
#             print(f"Skipping invalid: {v}")

# print(parsed)


# ─────────────────────────────────────────────
# 4. Safe record loop with try/except
# ─────────────────────────────────────────────

# records = ["100", "200", "abc", "300", None]
# parsed = []

# for r in records:
#     try:
#         parsed.append(int(r))
#     except (ValueError, TypeError):
#         print(f"Skipping: {r}")

# print(parsed)


# ─────────────────────────────────────────────
# 5. Fetch API → List comprehension → Insert
# ─────────────────────────────────────────────

# response = requests.get(f"{BASE_URL}/users", timeout=10)
# response.raise_for_status()
# users = response.json()

# valid_users = [u for u in users if u.get("email") and "@" in u["email"]]
# print(f"Valid users: {len(valid_users)}")

# user_map = {u["id"]: u["name"] for u in valid_users}
# print(user_map)


# ─────────────────────────────────────────────
# 6. Full pipeline with error handling
# ─────────────────────────────────────────────

# def fetch_users():
#     response = requests.get(f"{BASE_URL}/users", timeout=10)
#     response.raise_for_status()
#     return response.json()

# def clean_users(users):
#     return [u for u in users if u.get("email") and "@" in u["email"]]

# def insert_users(conn, users):
#     cursor = conn.cursor()
#     cursor.execute("""
#         CREATE TABLE IF NOT EXISTS users (
#             id       INT PRIMARY KEY,
#             name     VARCHAR(100),
#             username VARCHAR(100),
#             email    VARCHAR(150)
#         )
#     """)
#     records = [(u["id"], u["name"], u["username"], u["email"]) for u in users]
#     cursor.executemany(
#         "INSERT INTO users (id, name, username, email) VALUES (%s,%s,%s,%s) ON CONFLICT (id) DO NOTHING",
#         records
#     )
#     conn.commit()
#     return len(records)

# conn = None
# try:
#     conn = psycopg2.connect(**DB_CONFIG)
#     raw   = fetch_users()
#     clean = clean_users(raw)
#     count = insert_users(conn, clean)
#     print(f"Pipeline complete — {count} users inserted")
# except Exception as e:
#     print(f"Pipeline failed: {e}")
# finally:
#     if conn:
#         conn.close()


# ─────────────────────────────────────────────
# 7. Retry function
# ─────────────────────────────────────────────

# import time

# def run_with_retry(fn, max_retries=3):
#     for attempt in range(1, max_retries + 1):
#         try:
#             return fn()
#         except Exception as e:
#             wait = 2 ** attempt
#             print(f"Attempt {attempt} failed: {e}. Retrying in {wait}s...")
#             time.sleep(wait)
#     raise Exception(f"All {max_retries} retries exhausted")


# ─────────────────────────────────────────────
# Problem solving
# ─────────────────────────────────────────────

# build lookup dict from users API and enrich orders with user name
# write preflight_check() that validates .env and DB connection
# run idempotent pipeline 3 times and confirm count stays same
