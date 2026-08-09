import requests
import json
import csv
import time
import os

# if you want to call any api in python you need to use request mthod for it

# Get Method- To get the data from API
# POST Method- To Post the data(to fill the data)
# Put Method- To Update all the records of the API
# Patch Method- To Update the partial records in API

# response = requests.get('https://jsonplaceholder.typicode.com/users')
# data = response.json()
# # print(data)
# print(data[0])
# print(data[0].get('username'))
# print(data[0].get('address'))
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

# params = {
#     "userId": 1,
#     "username": "abc"
# }
# response = requests.get(
#     'https://jsonplaceholder.typicode.com/posts',
#     # params=params,
#     timeout=10
# )
# posts = response.json()
# print(posts)

# for post in posts:
#     print(post.get('title'))

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


# Read the files
# with open method we can read the files and we have multiple modes to open the file

# with close method you need to take care of closing
# file = open('sample.txt', 'r')
# data = file.read()
# print(data)
# file.close()


# using with statement you do not need to close the file, it will handled by with clause
# with open('sample.txt', 'r') as file:
#     data = file.read()
#     print(data)

# Read one line from the file
# with open('sample.txt', 'r') as file:
#     data = file.readline()
#     print(data)


# with open('sample.txt', 'r') as file:
#     data = file.readlines()
#     for line in data:
#         print(line)


# write methods in file handling
# with open('sample.txt', 'w') as file:
#     file.write("Hello Sunil!")


# append mode
# with open('sample.txt', 'a') as file:
#     file.write("\nWelcome to Data Engineering Daily!")


# create new file
# with open('sample2.txt', 'x') as file:
#     file.write("Hello Me.")

import csv

# with open('example.csv', 'r') as file:
#     rows = csv.reader(file)
#     header = next(rows)
#     print("header==>", header)
#     for row in rows:
#         print('Row==>', row)

# it is going to convert the csv in dictionary format use column names as key and rows as value

# with open('example.csv', 'r') as file:
#     rows = csv.DictReader(file)
#     for row in rows:
#         print(row)

# write mode in csv files

with open('output.csv', 'w', newline="") as file:
    writer = csv.writer(file)
    writer.writerow(['id', 'name'])
    writer.writerow([1, 'venkatesh'])


# Json data 
import json

with open('sample.json', 'r') as file:
    data = json.load(file)
    print(data[0])

with open('sample2.json', 'a') as file:
    json.dump(data, file, indent=4)



# HTTP METhods
url = "https://jsonplaceholder.typicode.com/posts"

payload = {
    "title": "Python",
    "body": "Learning APIs",
    "userId": 1
}

response = requests.post(url, json=payload)
print(response)
print(response.status_code)

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
