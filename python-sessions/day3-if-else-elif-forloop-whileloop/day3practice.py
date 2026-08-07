# if, else, elif, for loop while loop

# if else, elif

# status_code = 201

# if status_code==201:
#     print("Created")

# if status_code==200:
#     print("Get")

# if status_code=='403':
#     print('forbidden')


# number = 1

# if number>8:
#     print('greater>8')
# elif number>5:
#     print('greater>5')
# elif number>2:
#     print('greater>2')
# else:
#     print('less then equal to 1')


# 0 1 2, 3, 4, 5, 6, 7, 8, 9, 10

# for i in range(11):
#     print(i)

# 1, 3, 5, 7, 9

# for i in range(1, 10, 2):
#     print(i)

list1 = [5, 3, 9, 0, 11, 10]

# output = 9, 11, 10

for value in list1:
    if value > 5:
        print(value)

print('===========')
for value in list1[1:3]:
    if value > 5:
        print(value)

# while loop

number = 1
while number < 100:
    print(number)
    number += 1 # number = number+1
