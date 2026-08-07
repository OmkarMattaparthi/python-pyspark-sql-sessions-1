# Dictionary
# It is a data type with key value pair
# It is mutable
# it will not have index it has key value pairs
# It can have duplicate values but not dupliate keys

# Format of writing dictionary is this below

# {} this it the format

students = {
    "name": "Rahul",
    "course": "DE",
    "duration": "4 Months",
    "age": 23,
    "age2": 23,
    "marks": [93, 93, 34, 93, 33.33],
    "details": [
        {
            "id": 1,
            "address1": "ABC"
        },
        {
            "id": 2,
            "address2": "DEF"
        },

    ]
}
# print(students)
# print(students['age'])
# print(students["details"])
# print(students["details"][0])


# print(students["school"])
# it will help us to get the None if key is not present
# print(students.get("school"))


# it will help us to define the default value if key is missing
# print(students.get("school", "No School"))

# print(students.get("age", "No AGe"))


# it will help you to assign new key to dictionary
students["school"] = ["ABC School", "DEF School"]
# print(students)

# it will help you to update the the value
students["age"] = 55

# print(students)

del students["age2"]
# print(students)

# it will remove the specific key
students.pop("age")
# print(students)

# it will remove latest added item from the dictionary
students.popitem()
# print(students)


# Dictionary methods

# it will list the keys from the dictionary
# print(students.keys())

# it will print the values from the dictionary
# print(students.values())


# How to get nested keys
# print(students.get('details')[0].keys())


# iterate a dictionary

# for key in students:
#     print(key)

# iterate a dictionary

# for key in students:
#     print(students.get(key)) # students[key]


# Iterate a values
# for value in students.values():
#     print(value)

# it will convert key vaue pair in tuple
# print(students.items())

# iterating a dictionary with the help of items method
# for key, value in students.items():
#     print(key, value)

print(students.get("rollno"))
