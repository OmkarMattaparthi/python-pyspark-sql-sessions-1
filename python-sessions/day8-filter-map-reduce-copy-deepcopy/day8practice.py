
# map, filter and reduce methods
numbers = [1, 2, 3, 4, 5, 6]
# expected_output = [1, 4, 9, 16, 25, 36]

# map function # map(function, iterable)
# squares = map(lambda x: x*x, numbers)
# print(list(squares))

# def square(x):
#     return x*x

# data = map(lambda x: x*x, numbers)
# print(list(data))


# filter function
# filter(function, iterable)

# files = ['abc.csv', 'def.json', 'quie.txt']
# csv_files = filter(lambda file_name: file_name.split(".")[-1] == 'csv', files)
# print(list(csv_files))

# map reduce
# numbers = [1, 2, 3, 4, 5, 6]
# from functools import reduce

# total = reduce(lambda a, b: a+b, numbers) # 1, 2= 3, 3= 6, 4=10, 5 = 15,6 = 21
# print(total)


# numbers = [10, 45, 23, 89, 12]

# first [10, 45]
# second [45, 23]
# third [45, 89]
# fourth [89, 12]
# max value = 89

# value = reduce(lambda a, b: a if a > b else b, numbers) # 10, 45, 45, 23= 45, 89, 89, 12
# print(value)

from functools import reduce

employees = [
    {"name": "Amit", "salary": 50000},
    {"name": "Rahul", "salary": 75000},
    {"name": "Priya", "salary": 90000},
    {"name": "Raj", "salary": 45000}
]


def filter_employees_earning_60000_plus(employee):
    if employee.get('salary') and employee.get('salary')>60000:
        return employee


data = filter(filter_employees_earning_60000_plus, employees)
print(list(data))



# from copy import copy, deepcopy

# list1 = [1, 2, 3, 4, 5, [6, 7, 9]]
# list2 = list1
# list3 = copy(list1)
# list4 = deepcopy(list1)


# print(id(list1), id(list1[5]))
# print(id(list2), id(list2[5]))
# print(id(list3), id(list3[5]))
# print(id(list4), id(list4[5]))
# list1[4][0]=60
# print(list2, list3, list4)



