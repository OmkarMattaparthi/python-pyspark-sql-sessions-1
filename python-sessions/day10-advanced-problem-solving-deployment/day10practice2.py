# HASH MAP PROBLEM

# Two sum problem
# input_list = [2, 7, 11, 15]
# target = 13
# output = [0, 1]

# start = 0

# # value = 7
# # target = 9
# # target-value =  9 - 7 = 2
# storage = {}

# 1st iteration=> i=0, value=2, complement=target-value=11, storage={2: 0 }
# 2nd iteration=> i=1, value=7, complement=target-value=> 13 - 7 = 6, storage={2: 0, 7: 1}
# 3rd iteration=> i=2, value11, complement=target-value => 13-11 = 2
# for i, value in enumerate(input_list):

#     complement = target-value

#     if complement in storage: # 11, 2

#         print([storage[complement], i])
#         break

#     storage[value] = i


# # CHARACTER FREQUENCY FROM THE STRING
# string_value = "programming"
# freq = {}

# # iteration 1=> s=p => freq= {"p": 1, "r": 2, "o": 1, "g": 1, "a": 1, "m": 2}
# for s in string_value:

#     if freq.get(s) is None:
#         freq[s] = 1

#     else:
#         freq[s] += 1

# for char in string_value:
#     if freq[char] == 1:
#         print(char)
#         break

# print(freq)




# # non repeating 1st character from the string
# string_value = "aabbcde"



# # Valid Anagram
# string1 = "listen"
# string2 = "silent"
# freq = {}


# def anagram(string1, string2):

#     if len(string1) != len(string2):
#         return False

#     for s in string1:

#         if freq.get(s) is None:
#             freq[s] = 1

#         else:
#             freq[s] += 1

#     for char in string2:

#         if char not in freq:
#             return False
        
#         # string 1 has 2 times h and string 2 also has h 2 times 2-3=-1


#         freq[char]-=1 # freq = {'l': -1, 'i': 1, 's': 1, 't': 1, 'e': 1, 'n': 1}

#         if freq[char]<0:
#             return False
        
#     return True
# anagram(string1, string2)


# string1 = ["Haarioom"]
# string2 = ["aariomoHa"]

# freq = {"H": 0, "a": 0, "r": 0, "i": 0, "o": 0, "m": 0}


# Two Sum II
# Two pointer problem
nums = [2, 3, 4, 7, 8]

target = 11

pointer1 = 0
pointer2 = len(nums)-1

while pointer1 < pointer2:
    total = nums[pointer1] + nums[pointer2]

    if total == target:
        print([pointer1, pointer2])
        break
    elif total < target:
        pointer1 += 1
    else:
        pointer2 -= 1
