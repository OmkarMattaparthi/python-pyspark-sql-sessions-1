import psycopg2
import psycopg2.extras
import requests
import os
from dotenv import load_dotenv

load_dotenv("../../weekend-project/config/.env")

# ─────────────────────────────────────────────
# DB credentials from .env
# ─────────────────────────────────────────────

DB_CONFIG = {
    "host"    : os.getenv("PG_HOST",     "localhost"),
    "port"    : int(os.getenv("PG_PORT", 5432)),
    "dbname"  : os.getenv("PG_DBNAME",   "weekend-project"),
    "user"    : os.getenv("PG_USER",     "postgres"),
    "password": os.getenv("PG_PASSWORD", "hariom"),
}


# ─────────────────────────────────────────────
# 1. Basic connection
# ─────────────────────────────────────────────

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor()
# print("Connected to PostgreSQL!")
# cursor.execute("SELECT version();")
# print(cursor.fetchone()[0])
# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 2. Create table
# ─────────────────────────────────────────────

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor()

# cursor.execute("""
#     CREATE TABLE IF NOT EXISTS users (
#         id         INT PRIMARY KEY,
#         name       VARCHAR(100),
#         username   VARCHAR(100),
#         email      VARCHAR(150),
#         phone      VARCHAR(50),
#         website    VARCHAR(100),
#         company    VARCHAR(150),
#         created_at TIMESTAMP DEFAULT NOW()
#     )
# """)
# conn.commit()
# print("Table created!")
# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 3. Insert single row
# ─────────────────────────────────────────────

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor()

# cursor.execute(
#     """
#     INSERT INTO users (id, name, username, email, phone, website, company)
#     VALUES (%s, %s, %s, %s, %s, %s, %s)
#     RETURNING id
#     """,
#     (999, "Test User", "testuser", "test@example.com", "000-000", "test.com", "Test Corp")
# )
# new_id = cursor.fetchone()[0]
# conn.commit()
# print(f"Inserted row with id = {new_id}")
# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 4. Insert multiple rows — executemany
# ─────────────────────────────────────────────

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor()

# users = [
#     (1, "Leanne Graham",  "Bret",      "Sincere@april.biz",  "1-770-736-0988", "hildegard.org", "Romaguera-Crona"),
#     (2, "Ervin Howell",   "Antonette", "Shanna@melissa.tv",  "010-692-6593",   "anastasia.net", "Deckow-Crist"),
#     (3, "Clementine Bauch","Samantha", "Nathan@yesenia.net", "1-463-123-4447", "ramiro.info",   "Romaguera-Jacobson"),
# ]

# cursor.executemany(
#     """
#     INSERT INTO users (id, name, username, email, phone, website, company)
#     VALUES (%s, %s, %s, %s, %s, %s, %s)
#     ON CONFLICT (id) DO NOTHING
#     """,
#     users
# )
# conn.commit()
# print(f"Inserted {len(users)} users")
# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 5. Query — fetchall as tuples
# ─────────────────────────────────────────────

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor()

# cursor.execute("SELECT id, name, email FROM users")
# rows = cursor.fetchall()
# for row in rows:
#     print(row)

# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 6. Query — fetchall as dicts (RealDictCursor)
# ─────────────────────────────────────────────

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

# cursor.execute("SELECT id, name, email, company FROM users")
# rows = cursor.fetchall()
# for row in rows:
#     print(row["name"], "—", row["email"])

# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 7. Fetch API → Insert to DB
# ─────────────────────────────────────────────

# response = requests.get("https://jsonplaceholder.typicode.com/users", timeout=10)
# response.raise_for_status()
# api_users = response.json()

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor()

# cursor.execute("""
#     CREATE TABLE IF NOT EXISTS users (
#         id         INT PRIMARY KEY,
#         name       VARCHAR(100),
#         username   VARCHAR(100),
#         email      VARCHAR(150),
#         phone      VARCHAR(50),
#         website    VARCHAR(100),
#         company    VARCHAR(150),
#         created_at TIMESTAMP DEFAULT NOW()
#     )
# """)

# records = [
#     (
#         u["id"],
#         u["name"],
#         u["username"],
#         u["email"],
#         u["phone"],
#         u["website"],
#         u["company"]["name"]
#     )
#     for u in api_users
# ]

# cursor.executemany(
#     """
#     INSERT INTO users (id, name, username, email, phone, website, company)
#     VALUES (%s, %s, %s, %s, %s, %s, %s)
#     ON CONFLICT (id) DO NOTHING
#     """,
#     records
# )
# conn.commit()
# print(f"Fetched {len(api_users)} users from API — inserted into DB")
# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 8. Upsert — ON CONFLICT DO UPDATE
# ─────────────────────────────────────────────

# conn = psycopg2.connect(**DB_CONFIG)
# cursor = conn.cursor()

# cursor.execute(
#     """
#     INSERT INTO users (id, name, username, email, phone, website, company)
#     VALUES (%s, %s, %s, %s, %s, %s, %s)
#     ON CONFLICT (id) DO UPDATE SET
#         name    = EXCLUDED.name,
#         email   = EXCLUDED.email,
#         company = EXCLUDED.company
#     """,
#     (1, "Leanne Graham Updated", "Bret", "new_email@updated.com", "999-999", "new.org", "New Company")
# )
# conn.commit()
# print("Upsert done")
# cursor.close()
# conn.close()


# ─────────────────────────────────────────────
# 9. Error handling with try/except/finally
# ─────────────────────────────────────────────

# conn = None
# cursor = None
# try:
#     conn = psycopg2.connect(**DB_CONFIG)
#     cursor = conn.cursor()
#     cursor.execute("SELECT COUNT(*) FROM users")
#     count = cursor.fetchone()[0]
#     print(f"Total users: {count}")
#     conn.commit()
# except psycopg2.Error as e:
#     print(f"DB Error: {e}")
#     if conn:
#         conn.rollback()
# finally:
#     if cursor:
#         cursor.close()
#     if conn:
#         conn.close()


# ─────────────────────────────────────────────
# Problem solving
# ─────────────────────────────────────────────

# fetch posts from jsonplaceholder and insert into posts table
# run join query: users + posts — count posts per user
# build safe_insert() function with error handling
