# Day 6 Practice Problems — PostgreSQL Connection, API to DB, Insert Records

Difficulty: Medium to Hard. Use your local PostgreSQL with these credentials:
```
host=localhost, port=5432, dbname=weekend-project, user=postgres, password=hariom
```
Use `https://jsonplaceholder.typicode.com` for API calls — free, no auth needed.

---

## Section A — Connection and Table Setup

**P1. First Connection** *(Easy)*

Write a script that:
1. Connects to PostgreSQL using credentials from a `.env` file
2. Prints `"Connected successfully to <dbname>"`
3. Prints the PostgreSQL server version using:
   ```sql
   SELECT version();
   ```
4. Closes the connection cleanly in a `finally` block

---

**P2. Create Tables** *(Easy-Medium)*

Create the following two tables (use `CREATE TABLE IF NOT EXISTS` so it's safe to re-run):

```sql
-- Table 1
CREATE TABLE IF NOT EXISTS users (
    id         INT PRIMARY KEY,
    name       VARCHAR(100),
    username   VARCHAR(100),
    email      VARCHAR(150),
    phone      VARCHAR(50),
    website    VARCHAR(100),
    company    VARCHAR(150),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table 2
CREATE TABLE IF NOT EXISTS posts (
    id      INT PRIMARY KEY,
    user_id INT,
    title   VARCHAR(255),
    body    TEXT
);
```

After creating both, print `"Tables created successfully"`.

---

**P3. Drop and Recreate** *(Easy)*

Write a script that:
1. Drops `users` and `posts` tables if they exist (`DROP TABLE IF EXISTS`)
2. Recreates them using the same DDL from P2
3. Prints confirmation after each step

> This is useful at the start of a full reload pipeline — wipe and reload from scratch.

---

## Section B — Insert Records

**P4. Insert Single Row** *(Easy)*

Insert this record manually into the `users` table:
```python
user = {
    "id": 999,
    "name": "Test User",
    "username": "testuser",
    "email": "test@example.com",
    "phone": "000-000-0000",
    "website": "test.com",
    "company": "Test Corp"
}
```
Print the inserted row's `id` using `RETURNING id`.

---

**P5. Bulk Insert with executemany** *(Medium)*

Insert all 10 users from this list using `executemany()`:
```python
users = [
    (1,  "Leanne Graham",     "Bret",       "Sincere@april.biz",        "1-770-736-0988", "hildegard.org",  "Romaguera-Crona"),
    (2,  "Ervin Howell",      "Antonette",  "Shanna@melissa.tv",        "010-692-6593",   "anastasia.net",  "Deckow-Crist"),
    (3,  "Clementine Bauch",  "Samantha",   "Nathan@yesenia.net",        "1-463-123-4447", "ramiro.info",    "Romaguera-Jacobson"),
    (4,  "Patricia Lebsack",  "Karianne",   "Julianne.OConner@kory.org", "493-170-9623",   "kale.biz",       "Robel-Corkery"),
    (5,  "Chelsey Dietrich",  "Kamren",     "Lucio_Hettinger@annie.ca",  "(254)954-1289",  "demarco.info",   "Keebler LLC"),
    (6,  "Mrs. Dennis Schulist","Leopoldo", "Karley_Dach@jasper.info",   "1-477-935-8478", "ola.org",        "Considine-Lockman"),
    (7,  "Kurtis Weissnat",   "Elwyn.Skiles","Telly.Hoeger@billy.biz",  "210.067.6132",   "elvis.io",       "Johns Group"),
    (8,  "Nicholas Runolfsdottir V","Maxime","Sherwood@rosamond.me",    "586.493.6943",   "jacynthe.com",   "Abernathy Group"),
    (9,  "Glenna Reichert",   "Delphine",   "Chaim_McDermott@dana.io",  "(775)976-6794",  "conrad.com",     "Yost and Sons"),
    (10, "Clementina DuBuque","Moriah.Stanton","Rey.Padberg@karina.biz","024-648-3804",   "ambrose.net",    "Hoeger LLC"),
]
```
Print: `"Inserted 10 users"`.

---

**P6. Insert with ON CONFLICT DO NOTHING** *(Medium)*

Run P5's insert again (same data). Without `ON CONFLICT`, it would crash on duplicate primary keys.

Add `ON CONFLICT (id) DO NOTHING` to the INSERT and run it again — confirm it doesn't raise an error and prints `"0 new rows — all already exist"`.

---

## Section C — Querying Data

**P7. Basic SELECT Queries** *(Easy)*

After inserting users, write queries for:
1. Select all users — print `id`, `name`, `email`
2. Count total users: `SELECT COUNT(*) FROM users`
3. Select users whose email ends with `.biz`
4. Select the user with the highest `id`
5. Select users ordered by `name` alphabetically

---

**P8. Query with RealDictCursor** *(Medium)*

Repeat query #1 from P7 but use `psycopg2.extras.RealDictCursor` so each row is a `dict`. Then:
1. Print `row["name"]` and `row["email"]` for each row
2. Build a list of company names from the results
3. Print unique companies using a set

---

**P9. Parameterized Queries** *(Medium)*

Write a function `get_users_by_company(conn, company_name)` that:
1. Takes a connection and a company name
2. Runs: `SELECT id, name, email FROM users WHERE company = %s`
3. Returns a list of dicts

Call it with `"Romaguera-Crona"` and print the results.

---

## Section D — API → Parse → Insert to DB

**P10. Fetch Users from API and Insert** *(Medium)*

Full pipeline:
1. Fetch `GET https://jsonplaceholder.typicode.com/users`
2. For each user, extract: `id`, `name`, `username`, `email`, `phone`, `website`, `company["name"]`
3. Insert all into the `users` table using `executemany()`
4. Use `ON CONFLICT (id) DO NOTHING`
5. Print: `"Fetched 10 users from API — inserted into DB"`

---

**P11. Fetch Posts from API and Insert** *(Medium)*

Full pipeline:
1. Fetch `GET https://jsonplaceholder.typicode.com/posts`
2. Extract: `id`, `userId` (map to `user_id`), `title`, `body`
3. Insert all 100 posts into the `posts` table
4. Use `ON CONFLICT (id) DO NOTHING`
5. Print total inserted

---

**P12. Join Query After Insert** *(Medium-Hard)*

After inserting both users and posts (P10 + P11):

Write a Python script that runs this SQL and prints the result:
```sql
SELECT u.name, u.company, COUNT(p.id) AS post_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.name, u.company
ORDER BY post_count DESC;
```
Print each row as: `"Leanne Graham (Romaguera-Crona) — 10 posts"`

---

## Section E — Upsert and Update

**P13. Upsert — API Re-run** *(Medium)*

Simulate a second API run where data has changed:
```python
updated_user = (1, "Leanne Graham Updated", "Bret", "new_email@updated.com", "999-999-9999", "new.org", "New Company")
```
Use `ON CONFLICT (id) DO UPDATE SET` to update `name`, `email`, `company` for `id=1`.
Then query the row and confirm it was updated.

---

**P14. Update and Delete** *(Medium)*

1. Update salary of all Engineering employees: `UPDATE employees SET salary = salary * 1.10 WHERE department = 'Engineering'`
2. Delete all rows where `department = 'HR'`
3. Print row counts before and after each operation using `SELECT COUNT(*)`

> Note: use the `employees` table from the notes examples, or create it fresh.

---

## Section F — Full End-to-End Pipeline

**P15. Full Ingestion Pipeline** *(Hard)*

Build a complete script `pipeline.py` that:

1. Loads credentials from `.env`
2. Connects to PostgreSQL
3. Creates `users` and `posts` tables (`IF NOT EXISTS`)
4. Fetches users from `https://jsonplaceholder.typicode.com/users`
5. Fetches posts from `https://jsonplaceholder.typicode.com/posts`
6. Inserts users (upsert)
7. Inserts posts (upsert)
8. Runs a summary query:
   ```sql
   SELECT COUNT(*) FROM users;
   SELECT COUNT(*) FROM posts;
   ```
9. Prints a final report:
   ```
   Pipeline complete.
   Users in DB  : 10
   Posts in DB  : 100
   ```
10. Closes connection in `finally` block

---

**P16. Paginated API → DB** *(Hard)*

Use the ReqRes API which has real pagination:
```
GET https://reqres.in/api/users?page=1
GET https://reqres.in/api/users?page=2
```

1. Create table `reqres_users (id INT PRIMARY KEY, email VARCHAR, first_name VARCHAR, last_name VARCHAR, avatar VARCHAR)`
2. Loop through all pages (check `total_pages` from response)
3. For each page, insert all users into `reqres_users`
4. Add `time.sleep(0.3)` between pages
5. After all pages, query and print all rows
6. Print: `"Total pages: X | Total users loaded: Y"`

---

**P17. Error Handling Pipeline** *(Hard)*

Build a robust insert function:
```python
def safe_insert(conn, records, table):
    ...
```
That:
1. Wraps the insert in a `try/except psycopg2.Error`
2. On error — calls `conn.rollback()` and prints the error message
3. On success — calls `conn.commit()` and prints rows inserted
4. Always logs: `"[<table>] Attempted <N> rows — <success/failed>"`

Test it with valid records, then with a record that has a duplicate primary key (without `ON CONFLICT`) to trigger the error path.
