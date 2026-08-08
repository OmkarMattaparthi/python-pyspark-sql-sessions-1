# Day 5 Notes — requests, API, JSON, CSV, Pagination, Throttling

## Topics Covered
1. HTTP Methods and the `requests` library
2. Reading and working with JSON
3. Reading CSV files
4. Working with a real public API (JSONPlaceholder)
5. Pagination — fetching all pages
6. Throttling — rate limiting between requests

---

## 1. HTTP Methods

| Method | Purpose | Example |
|--------|---------|---------|
| `GET` | Fetch data | Get a list of users |
| `POST` | Create new data | Submit a form, login |
| `PUT` | Replace existing data | Update full record |
| `PATCH` | Update part of a record | Update one field |
| `DELETE` | Remove data | Delete a record |

> **DE use case:** You will mostly use `GET` to fetch data from APIs and `POST` for auth (login to get a token).

---

## 2. The `requests` Library

```python
import requests

# GET request
response = requests.get("https://jsonplaceholder.typicode.com/users")

# Check status code
print(response.status_code)    # 200 = OK, 404 = Not Found, 500 = Server Error

# Get response as JSON (dict/list)
data = response.json()

# Get response as raw text
text = response.text

# Raise an exception automatically if status is 4xx or 5xx
response.raise_for_status()
```

### Adding query parameters

```python
params = {"page": 1, "page_size": 10}
response = requests.get("https://api.example.com/data", params=params)
# builds URL: https://api.example.com/data?page=1&page_size=10
```

### Adding headers (e.g. auth token)

```python
headers = {"Authorization": "Token abc123xyz"}
response = requests.get("https://api.example.com/data", headers=headers)
```

### Timeout — always set it

```python
response = requests.get("https://api.example.com/data", timeout=10)
# raises requests.exceptions.Timeout if no response in 10 seconds
```

> **DE rule:** Always use `timeout`. Without it, a hung API call blocks your pipeline forever.

---

## 3. JSON — JavaScript Object Notation

JSON is the standard format for API responses. In Python, JSON maps to:

| JSON | Python |
|------|--------|
| `{ }` object | `dict` |
| `[ ]` array | `list` |
| `"string"` | `str` |
| `123` number | `int` / `float` |
| `true` / `false` | `True` / `False` |
| `null` | `None` |

### Reading JSON from API response

```python
import requests

response = requests.get("https://jsonplaceholder.typicode.com/users/1")
user = response.json()          # dict

print(user["name"])             # "Leanne Graham"
print(user["email"])            # "Sincere@april.biz"
print(user["company"]["name"])  # nested key access
```

### Reading JSON from a file

```python
import json

with open("sample_data/orders.json", "r") as f:
    orders = json.load(f)       # parses JSON → Python list/dict

for order in orders:
    print(order["order_id"], order["total"], order["status"])
```

### Writing JSON to a file

```python
import json

data = [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]

with open("output.json", "w") as f:
    json.dump(data, f, indent=2)
```

### Extracting nested values

```python
# orders.json structure:
# [ { "order_id": "ORD-1001", "items": [ {"product": "Laptop", "qty": 1, "price": 1200} ] } ]

with open("sample_data/orders.json") as f:
    orders = json.load(f)

for order in orders:
    for item in order["items"]:
        print(order["order_id"], item["product"], item["price"])
```

---

## 4. Reading CSV Files

### Using built-in `csv` module

```python
import csv

with open("sample_data/employees.csv", "r") as f:
    reader = csv.DictReader(f)          # reads header row as keys
    for row in reader:
        print(row["name"], row["department"], row["salary"])
```

### Useful patterns

```python
import csv

# Read all rows into a list of dicts
with open("sample_data/employees.csv", "r") as f:
    employees = list(csv.DictReader(f))

# Filter rows
eng_employees = [e for e in employees if e["department"] == "Engineering"]

# Get all unique departments
departments = set(e["department"] for e in employees)
```

### Writing CSV

```python
import csv

rows = [
    {"name": "Alice", "score": 95},
    {"name": "Bob",   "score": 88},
]

with open("output.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "score"])
    writer.writeheader()
    writer.writerows(rows)
```

> **DE use case:** Reading raw CSV dumps from databases, writing cleaned data back to CSV for downstream teams.

---

## 5. Public Test APIs

These APIs are free, require no auth, and are great for practice:

| API | Base URL | What it has |
|-----|----------|-------------|
| JSONPlaceholder | `https://jsonplaceholder.typicode.com` | users, posts, todos, comments, albums |
| ReqRes | `https://reqres.in/api` | users with pagination built-in |
| Open Meteo | `https://api.open-meteo.com/v1/forecast` | weather data, no auth |

### JSONPlaceholder — key endpoints

```
GET /users          → list of 10 users
GET /users/1        → single user by id
GET /posts          → 100 posts
GET /posts/1        → single post
GET /todos          → 200 todos
GET /posts?userId=1 → filter posts by user
```

### ReqRes — has real pagination

```
GET https://reqres.in/api/users?page=1  → page 1 of users
GET https://reqres.in/api/users?page=2  → page 2 of users
```

Response shape:
```json
{
  "page": 1,
  "per_page": 6,
  "total": 12,
  "total_pages": 2,
  "data": [ { "id": 1, "email": "george.bluth@reqres.in", ... } ]
}
```

---

## 6. Pagination — Fetching All Pages

Most real APIs don't return everything in one call. You must loop through pages.

### Pattern: loop until last page

```python
import requests

BASE_URL = "https://reqres.in/api/users"
all_users = []
page = 1

while True:
    response = requests.get(BASE_URL, params={"page": page}, timeout=10)
    response.raise_for_status()
    data = response.json()

    all_users.extend(data["data"])          # add this page's results

    print(f"Fetched page {page}/{data['total_pages']} — {len(data['data'])} records")

    if page >= data["total_pages"]:         # stop when last page reached
        break

    page += 1

print(f"Total records fetched: {len(all_users)}")
```

### Pattern: use total_pages from first response

```python
import requests

BASE_URL = "https://reqres.in/api/users"
all_records = []

# First call to find total pages
first = requests.get(BASE_URL, params={"page": 1}, timeout=10)
first.raise_for_status()
first_data = first.json()
total_pages = first_data["total_pages"]
all_records.extend(first_data["data"])

# Remaining pages
for page in range(2, total_pages + 1):
    response = requests.get(BASE_URL, params={"page": page}, timeout=10)
    response.raise_for_status()
    all_records.extend(response.json()["data"])
    print(f"Page {page} done")

print(f"Total: {len(all_records)} records")
```

---

## 7. Throttling — Rate Limiting

APIs limit how many requests you can make per second/minute. Sending too fast causes `429 Too Many Requests`.

### Basic throttle with `time.sleep`

```python
import requests
import time

BASE_URL = "https://reqres.in/api/users"
all_records = []
page = 1

while True:
    response = requests.get(BASE_URL, params={"page": page}, timeout=10)

    if response.status_code == 429:
        print("Rate limited — sleeping 5 seconds")
        time.sleep(5)
        continue                    # retry same page

    response.raise_for_status()
    data = response.json()
    all_records.extend(data["data"])

    if page >= data["total_pages"]:
        break

    page += 1
    time.sleep(0.5)                 # 0.5s between each call = max 2 req/sec

print(f"Done: {len(all_records)} records")
```

### Retry with backoff — production pattern

```python
import requests
import time

def get_with_retry(url, params=None, max_retries=3, backoff=2):
    for attempt in range(1, max_retries + 1):
        try:
            response = requests.get(url, params=params, timeout=10)
            if response.status_code == 429:
                wait = backoff ** attempt       # 2, 4, 8 seconds
                print(f"Rate limited. Retry {attempt}/{max_retries} in {wait}s")
                time.sleep(wait)
                continue
            response.raise_for_status()
            return response.json()
        except requests.exceptions.Timeout:
            print(f"Timeout on attempt {attempt}")
            time.sleep(backoff)
    raise Exception(f"Failed after {max_retries} retries: {url}")
```

---

## 8. Saving API Data Locally (Raw Layer)

In a real pipeline, always save raw API responses to disk before processing.

```python
import requests
import json
import os

RAW_DIR = "data/raw"
os.makedirs(RAW_DIR, exist_ok=True)

BASE_URL = "https://jsonplaceholder.typicode.com/users"
response = requests.get(BASE_URL, timeout=10)
response.raise_for_status()

data = response.json()

with open(f"{RAW_DIR}/users.json", "w") as f:
    json.dump(data, f, indent=2)

print(f"Saved {len(data)} records to {RAW_DIR}/users.json")
```

> **DE rule:** Save raw → transform → load. Never transform in-flight without saving the raw response. If the transform fails, you can reprocess without re-calling the API.

---

## 9. Key Takeaways for Data Engineering

| Concept | DE Application |
|---------|---------------|
| `requests.get()` | Pull data from REST APIs — sources, webhooks, SaaS exports |
| `response.raise_for_status()` | Fail fast — don't silently process a bad response |
| `timeout=10` | Always set; prevents pipelines hanging forever |
| `json.load()` / `json.dump()` | Read raw API responses; write to landing zone |
| `csv.DictReader` | Read CSV exports from databases or flat files |
| Pagination loop | Never assume one call = all data; always check `total_pages` |
| `time.sleep()` | Respect API rate limits; prevent 429 errors |
| Retry with backoff | Resilience for transient failures (timeout, 500, 429) |
| Save raw to disk | Reproducible pipelines — reprocess without re-calling API |
