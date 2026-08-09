import psycopg2


# Topic - Connect database using python driver for postgres
host = 'localhost'
database = 'python_practice'
username = 'postgres'
password = 'hariom'

connection = psycopg2.connect(
    host=host,
    database=database,
    user=username,
    password=password
)

print('Connection Successful')
cursor = connection.cursor()

# cursor.execute('select * from employees')
# row = cursor.fetchone()
# print(row)

# rows = cursor.fetchall()
# print(rows)

# rows = cursor.fetchmany(2)
# print(rows)

# cursor.close()
# connection.close()

# Python(
#     it is used to build a connection with database programatically
# )->connection(
#     it will help us to build connection
# )->cursor(
#         cursor will help us to execute the query
# )->postgresdb


query = """
    INSERT INTO employees (
        name, department, salary, city, joining_date
    )
    VALUES(
        %s, %s, %s, %s, %s
    )
"""

values = (
    "Vikas",
    "Data Engineering",
    90000,
    "Bangalore",
    "2025-01-15"
)

cursor.execute(query, values)
# connection.commit()
connection.rollback()

cursor.execute('select * from employees')
rows = cursor.fetchall()
print(rows)

