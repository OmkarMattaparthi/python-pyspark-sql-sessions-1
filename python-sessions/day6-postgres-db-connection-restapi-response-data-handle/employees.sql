CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    salary NUMERIC(10,2),
    city VARCHAR(50),
    joining_date DATE
);

INSERT INTO employees
(name, department, salary, city, joining_date)
VALUES
('Rahul', 'Data Engineering', 75000, 'Bangalore', '2023-01-10'),
('Priya', 'Data Analytics', 65000, 'Pune', '2022-06-15'),
('Amit', 'Data Engineering', 85000, 'Hyderabad', '2021-08-20'),
('Neha', 'HR', 55000, 'Delhi', '2024-02-12'),
('Rohit', 'Data Analytics', 70000, 'Mumbai', '2023-11-05');