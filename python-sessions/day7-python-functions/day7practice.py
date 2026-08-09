# WHat is python function?
# Python funnction is reusable block of code in your script
name = 'Pratik'
print(f"Hello {name}")


def printFunc():
    print("Hello World Custom")

# printFunc()


def sum_custom(a, b):
    return a+b

# print(sum_custom(3, 2))


def sum_default_custom(a=3, b=3):
    return a+b

print(sum_default_custom(9))

