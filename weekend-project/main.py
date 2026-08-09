from dotenv import load_dotenv
from database.connection import get_connection

load_dotenv()

connection = get_connection()
cursor = connection.cursor()
cursor.execute('select * from employees')
rows = cursor.fetchall()
print(rows)
