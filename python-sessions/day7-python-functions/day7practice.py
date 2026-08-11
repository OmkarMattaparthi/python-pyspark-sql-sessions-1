# WHat is python function?
# Python funnction is reusable block of code in your script
# name = 'Pratik'
# print(f"Hello {name}")


# def printFunc():
#     print("Hello World Custom")

# # printFunc()


# def sum_custom(a, b):
#     return a+b

# # print(sum_custom(3, 2))


# def sum_default_custom(a=3, b=3):
#     return a+b

# print(sum_default_custom(9))

# keyword argument function

# def sumnew(a, b):
#     print(a, b)
#     return a+b

# sumnew(b=6, a=7)


# def sum_all(*numbers):
#     print(numbers)
#     return sum(numbers)

# sum_all(1, 2, 3, 5, 5)


# def sumnew(**info):
#     print(info)
#     return True

# sumnew(b=6, a=7, c=7)

# def do_square(n):
#     return n*n

# print(do_square(8))

# # lambda function
# square = lambda x: x*x
# print(square(7))


from copy import copy, deepcopy

list1 = [1, 2, 3, 4, 5, [6, 7, 9]]
list2 = list1
list3 = copy(list1)
list4 = deepcopy(list1)


print(id(list1), id(list1[5]))
print(id(list2), id(list2[5]))
print(id(list3), id(list3[5]))
print(id(list4), id(list4[5]))
# list1[4][0]=60
# print(list2, list3, list4)
