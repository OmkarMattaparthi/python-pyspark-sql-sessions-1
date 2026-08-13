#PROBLEM SOLVING

# short circuite evaluation
# a = 9

# if a or ldfjlsdjflsdjlfdj:
#     print("inside if")


# list1 = [3, 5, 2, 0, 3, 0, 8, 5]

# expected output = [8, 3, 2, 3]
# print(list1[-2::-2])

# list2 = [[1, 2], [3, 4], [5, 6, 7, [1, 2, 3]]]

# listoutput = [1, 2, 3, 4, 5, 6, 7, 1, 2, 3]


# 1st iteration item = [1, 2] -> flatten([1, 2]) ->


# def flatten(data): 
#     result = []
#     for item in data:
#         try:
#             result.extend(flatten(item)) # try to exted(1)

#         except TypeError:
#             result.append(item)
#     return result

# print(flatten(list2))

# n = 3

# 1st time n=3 it will print - Hello and call hell(n-1=2) 2-1 


# def hell(n):
#     if n == 0:
#         return
#     print(f"Hello {n}")
#     hell(n-1)


# hell(n)

# users = [
#     {"id": 1, "name": "  amit sharma ", "age": 25},
#     {"id": 2, "name": "RAHUL KUMAR", "age": 30},
#     {"id": 3, "name": "", "age": 22},
#     {"id": 4, "name": " priya ", "age": None},
#     {"id": 5, "name": "  raj  ", "age": 28}
# ]

# clean_user = []
# for user in users:
#     name = user["name"].strip()
#     age = user["age"]
#     if name == "":
#         continue
#     if age is None:
#         continue
#     user["name"] = name.title()  # rajesh khanna-> Rajesh Khanna
#     clean_user.append(user)

# print(clean_user)


# Requirements
# Remove records where name is empty.
# Remove records where age is missing.
# Strip spaces from names.
# Convert names to title case.


list1 = [1, 2, 3, 4, 5]

for num in list1:
    if num > 3:
        break
    print(num)


customers = [
    {"id": 101, "name": "Amit", "email": "amit@gmail.com"},
    {"id": 102, "name": "Rahul", "email": "rahul@gmail.com"},
    {"id": 101, "name": "Amit", "email": "amit@gmail.com"},
    {"id": 103, "name": "Priya", "email": "priya@gmail.com"},
    {"id": 102, "name": "Rahul", "email": "rahul@gmail.com"}
]

# Remove duplicates based on id