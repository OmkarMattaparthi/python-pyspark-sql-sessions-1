import requests
import json
import csv
import time
import os


# ─────────────────────────────────────────────
# 1. Basic GET request
# ─────────────────────────────────────────────

# response = requests.get("https://jsonplaceholder.typicode.com/users", timeout=10)
# print(response.status_code)
# data = response.json()
# print(type(data))
# print(data[0])
# print(data[0]["name"])
# print(data[0]["email"])
# print(data[0]["company"]["name"])   # nested key


# ─────────────────────────────────────────────
# 2. Query params
# ─────────────────────────────────────────────

# params = {"userId": 1}
# response = requests.get(
#     "https://jsonplaceholder.typicode.com/posts",
#     params=params,
#     timeout=10
# )
# posts = response.json()
# print(f"Posts for userId=1: {len(posts)}")
# for post in posts:
#     print(post["id"], post["title"])


# ─────────────────────────────────────────────
# 3. Reading JSON from file
# ─────────────────────────────────────────────

# with open("sample_data/orders.json", "r") as f:
#     orders = json.load(f)

# print(f"Total orders: {len(orders)}")

# for order in orders:
#     print(order["order_id"], order["total"], order["status"])


# ─────────────────────────────────────────────
# 4. Flatten nested JSON
# ─────────────────────────────────────────────

# with open("sample_data/orders.json", "r") as f:
#     orders = json.load(f)

# flat_items = []
# for order in orders:
#     for item in order["items"]:
#         flat_items.append({
#             "order_id": order["order_id"],
#             "product":  item["product"],
#             "qty":      item["qty"],
#             "price":    item["price"]
#         })

# for item in flat_items:
#     print(item)


# ─────────────────────────────────────────────
# 5. Reading CSV file
# ─────────────────────────────────────────────

# with open("sample_data/employees.csv", "r") as f:
#     reader = csv.DictReader(f)
#     employees = list(reader)

# for emp in employees:
#     print(emp["name"], emp["department"], emp["salary"])

# print(f"Total employees: {len(employees)}")


# ─────────────────────────────────────────────
# 6. Filter CSV and convert types
# ─────────────────────────────────────────────

# with open("sample_data/employees.csv", "r") as f:
#     employees = list(csv.DictReader(f))

# for emp in employees:
#     emp["salary"] = int(emp["salary"])   # CSV gives strings, cast to int

# eng = [e for e in employees if e["department"] == "Engineering"]
# print(f"Engineering headcount: {len(eng)}")

# highest_paid = max(employees, key=lambda e: e["salary"])
# print(f"Highest paid: {highest_paid['name']} — {highest_paid['salary']}")

# avg_salary = sum(e["salary"] for e in employees) / len(employees)
# print(f"Average salary: {avg_salary:.2f}")


# ─────────────────────────────────────────────
# 7. Save API response to file
# ─────────────────────────────────────────────

# os.makedirs("data/raw", exist_ok=True)

# response = requests.get("https://jsonplaceholder.typicode.com/users", timeout=10)
# response.raise_for_status()
# users = response.json()

# with open("data/raw/users.json", "w") as f:
#     json.dump(users, f, indent=2)

# print(f"Saved {len(users)} users to data/raw/users.json")


# ─────────────────────────────────────────────
# 8. Pagination — ReqRes API
# ─────────────────────────────────────────────

# BASE_URL = "https://reqres.in/api/users"
# all_users = []
# page = 1

# while True:
#     response = requests.get(BASE_URL, params={"page": page}, timeout=10)
#     response.raise_for_status()
#     data = response.json()

#     all_users.extend(data["data"])
#     print(f"Page {page}/{data['total_pages']} — {len(data['data'])} records")

#     if page >= data["total_pages"]:
#         break

#     page += 1
#     time.sleep(0.5)

# print(f"Total users fetched: {len(all_users)}")
# for user in all_users:
#     print(user["first_name"], user["last_name"], user["email"])


# ─────────────────────────────────────────────
# 9. Throttling — sleep between calls
# ─────────────────────────────────────────────

# BASE_URL = "https://jsonplaceholder.typicode.com/posts"
# all_posts = []

# start = time.time()

# for user_id in range(1, 6):
#     params = {"userId": user_id}
#     response = requests.get(BASE_URL, params=params, timeout=10)
#     response.raise_for_status()
#     posts = response.json()
#     all_posts.extend(posts)
#     print(f"userId={user_id} → {len(posts)} posts")
#     time.sleep(0.3)

# elapsed = time.time() - start
# print(f"Total posts: {len(all_posts)} | Time: {elapsed:.2f}s")


# ─────────────────────────────────────────────
# 10. Retry function
# ─────────────────────────────────────────────

# def get_with_retry(url, params=None, max_retries=3, backoff=2):
#     for attempt in range(1, max_retries + 1):
#         try:
#             response = requests.get(url, params=params, timeout=10)
#             if response.status_code == 429:
#                 wait = backoff ** attempt
#                 print(f"Rate limited. Retry {attempt}/{max_retries} in {wait}s")
#                 time.sleep(wait)
#                 continue
#             if response.status_code == 404:
#                 raise Exception(f"404 Not Found — no retry: {url}")
#             response.raise_for_status()
#             return response.json()
#         except requests.exceptions.Timeout:
#             print(f"Timeout on attempt {attempt}")
#             time.sleep(backoff)
#     raise Exception(f"Failed after {max_retries} retries: {url}")


# result = get_with_retry("https://jsonplaceholder.typicode.com/posts/1")
# print(result["title"])


# ─────────────────────────────────────────────
# Problem solving
# ─────────────────────────────────────────────

# fetch all users and save raw
# fetch posts for users 1-3 with throttle
# read employees.csv and print highest paid per department
