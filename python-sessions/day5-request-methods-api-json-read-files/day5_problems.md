# Day 5 Practice Problems — requests, API, JSON, CSV, Pagination, Throttling

Difficulty: Medium to Hard. Use `https://jsonplaceholder.typicode.com` and `https://reqres.in/api` — both are free, no auth required.

---

## Section A — JSON File Reading

**P1. Read and Print Orders** *(Easy)*

Read `sample_data/orders.json` and print:
1. Total number of orders
2. Order ID and total for each order
3. Only orders with status `"Delivered"`
4. The most expensive order (by `total`)

---

**P2. Flatten Nested Items** *(Medium)*

Read `sample_data/orders.json`. For each order, loop through its `items` list and build a flat list of dicts like:

```python
[
  {"order_id": "ORD-1001", "product": "Laptop",  "qty": 1, "price": 1200.00},
  {"order_id": "ORD-1001", "product": "Mouse",   "qty": 2, "price": 25.00},
  ...
]
```

Then:
1. Print the flat list
2. Find the total revenue across all items (`qty * price` summed)
3. Find the most ordered product (highest total qty across all orders)

---

**P3. Write Processed Orders to JSON** *(Medium)*

Read `sample_data/orders.json`, filter out `"Cancelled"` orders, and write the remaining orders to a new file `sample_data/orders_clean.json`. Include only these fields per order: `order_id`, `customer_name`, `total`, `status`.

---

## Section B — CSV File Reading

**P4. Read and Summarize Employees** *(Easy)*

Read `sample_data/employees.csv` and:
1. Print each employee's name, department, and salary
2. Count employees per department
3. Find the highest-paid employee
4. Calculate average salary across all employees

---

**P5. Filter and Write CSV** *(Medium)*

Read `sample_data/employees.csv`:
1. Filter only Engineering and Data employees
2. Convert `salary` column to `int` (it comes in as string from CSV)
3. Add a new column `salary_band`: `"Senior"` if salary >= 100000, `"Mid"` if >= 80000, else `"Junior"`
4. Write the filtered + enriched rows to `sample_data/tech_employees.csv`

---

**P6. CSV to JSON Conversion** *(Medium)*

Read `sample_data/employees.csv` and convert it to a list of dicts. Then write it to `sample_data/employees.json`. Make sure `salary` is stored as `int`, not a string.

Expected JSON shape:
```json
[
  {"employee_id": "E001", "name": "Alice Johnson", "department": "Engineering", "salary": 95000, ...},
  ...
]
```

---

## Section C — Live API Calls (JSONPlaceholder)

**P7. Fetch All Users** *(Easy)*

```
GET https://jsonplaceholder.typicode.com/users
```

1. Fetch the list of users
2. Print each user's `name` and `email`
3. Print total user count
4. Save the raw response to `data/raw/users.json`

---

**P8. Fetch Posts for a Specific User** *(Medium)*

```
GET https://jsonplaceholder.typicode.com/posts?userId=1
```

1. Fetch all posts for `userId=1`
2. Print post `id` and `title` for each
3. Count how many posts that user has
4. Fetch the same for `userId=2` and `userId=3`
5. Print which user has the most posts

---

**P9. Fetch Todos and Summarize** *(Medium)*

```
GET https://jsonplaceholder.typicode.com/todos
```

1. Fetch all 200 todos
2. Group by `userId` — count completed (`completed=True`) and pending (`completed=False`) per user
3. Find the user with the highest completion rate
4. Print a summary table:
   ```
   userId | total | completed | pending | completion%
   ```

---

**P10. Nested Fetch — Users + Their Posts** *(Medium-Hard)*

```
GET https://jsonplaceholder.typicode.com/users
GET https://jsonplaceholder.typicode.com/posts?userId=<id>
```

1. Fetch all 10 users
2. For each user, fetch their posts (separate API call per user)
3. Build a combined list:
   ```python
   [{"user_id": 1, "name": "Leanne Graham", "post_count": 10, "titles": [...]}, ...]
   ```
4. Add `time.sleep(0.3)` between each user's post fetch (throttle)
5. Save the combined result to `data/raw/users_with_posts.json`

---

## Section D — Pagination (ReqRes API)

**P11. Fetch All Pages — ReqRes Users** *(Medium)*

```
GET https://reqres.in/api/users?page=1
```

Response has `page`, `total_pages`, `data` fields.

1. Fetch page 1 — inspect `total_pages`
2. Loop through all pages and collect every user record
3. Print total users fetched
4. Print each user's `first_name`, `last_name`, `email`

---

**P12. Pagination with Progress Logging** *(Medium)*

Same as P11 but add:
1. Print progress after each page: `"Page 2/2 — fetched 6 records — total so far: 12"`
2. Add `time.sleep(0.5)` between pages
3. Save all pages' raw responses as separate files:
   - `data/raw/users_page_1.json`
   - `data/raw/users_page_2.json`

---

**P13. Simulate Large Pagination** *(Hard)*

Use `https://jsonplaceholder.typicode.com/posts` — it returns 100 posts in one call. Simulate pagination manually:

1. Fetch all 100 posts
2. Split into pages of 10 using list slicing: `posts[0:10]`, `posts[10:20]`, etc.
3. For each "page", print `"Page X: post IDs Y to Z"`
4. Save each page as a separate JSON file in `data/raw/posts/page_1.json`, `page_2.json`, etc.

---

## Section E — Throttling and Retry

**P14. Rate-Limited Fetcher** *(Medium)*

Write a function `fetch_with_delay(url, delay=0.5)` that:
1. Makes a GET request to `url`
2. Sleeps `delay` seconds after each call
3. Returns the parsed JSON

Use it to fetch posts for users 1 through 5:
```
GET https://jsonplaceholder.typicode.com/posts?userId=1
GET https://jsonplaceholder.typicode.com/posts?userId=2
...
```
Print how long the total fetch took using `time.time()`.

---

**P15. Retry on Failure** *(Medium-Hard)*

Write a function `get_with_retry(url, params=None, max_retries=3, backoff=2)` that:
1. Makes a GET request
2. If status is `429` or `500`, waits `backoff ** attempt` seconds and retries
3. If status is `404`, raises immediately (no retry — data doesn't exist)
4. Raises an exception after `max_retries` exhausted

Test it with:
```python
get_with_retry("https://jsonplaceholder.typicode.com/posts/1")   # should succeed
get_with_retry("https://jsonplaceholder.typicode.com/posts/999") # 404 — raise immediately
```

---

## Section F — Mixed / End-to-End

**P16. Full Pipeline: Fetch → Save → Read → Filter** *(Hard)*

Build a small end-to-end pipeline:

1. **Fetch** all users from `https://jsonplaceholder.typicode.com/users`
2. **Save** raw JSON to `data/raw/users.json`
3. **Read** the saved file back using `json.load()`
4. **Filter** users whose email ends with `.com`
5. **Write** filtered users to `data/processed/users_com.csv` with columns: `id`, `name`, `email`, `company_name`

---

**P17. Multi-Endpoint Collector** *(Hard)*

Fetch data from 3 endpoints, save each, then produce a summary:

```
GET https://jsonplaceholder.typicode.com/users    → save to data/raw/users.json
GET https://jsonplaceholder.typicode.com/posts    → save to data/raw/posts.json
GET https://jsonplaceholder.typicode.com/todos    → save to data/raw/todos.json
```

After fetching all 3:
1. Add `time.sleep(0.3)` between each endpoint call
2. Print a summary:
   ```
   users : 10 records saved
   posts : 100 records saved
   todos : 200 records saved
   ```
3. For each user, count: how many posts and how many completed todos they have
4. Print the top 3 users by total activity (posts + completed todos)

---

**P18. Paginate + Throttle + Save — Production Pattern** *(Hard)*

Simulate a real ingestion loop for the ReqRes API:

```
GET https://reqres.in/api/users?page=1
GET https://reqres.in/api/users?page=2
```

Requirements:
1. Fetch all pages with `time.sleep(0.5)` between calls
2. Handle HTTP errors with `raise_for_status()`
3. Save each page's raw response to `data/raw/reqres/page_<n>.json`
4. After all pages, merge all records and save to `data/processed/reqres_users.json`
5. Print a final summary: total pages fetched, total records, time taken

> This is exactly the pattern used in a production data ingestion pipeline.
