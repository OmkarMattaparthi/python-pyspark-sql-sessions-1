-- ============================================================
-- Day 4 — SQL Easy Problems (Beginner Level)
-- Topics: SELECT, Filters, CASE, JOINs, GROUP BY
-- This file is STANDALONE — run it top to bottom in one go.
-- ============================================================
-- Instructions for students:
--   1. Run the SETUP section first (creates tables + inserts data).
--   2. Read each problem carefully.
--   3. Write your answer in the space provided under each problem.
--   4. Check your result against the expected output.
-- ============================================================


-- ============================================================
-- SETUP — Schema, Tables, Data
-- Run this entire block before attempting any problem.
-- ============================================================

DROP SCHEMA IF EXISTS shop CASCADE;
CREATE SCHEMA shop;

CREATE TABLE shop.customers (
    customer_id  SERIAL PRIMARY KEY,
    name         VARCHAR(100),
    city         VARCHAR(50),
    age          INT
);

CREATE TABLE shop.products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    price        NUMERIC(10,2)
);

CREATE TABLE shop.orders (
    order_id     SERIAL PRIMARY KEY,
    customer_id  INT REFERENCES shop.customers(customer_id),
    product_id   INT REFERENCES shop.products(product_id),
    quantity     INT,
    order_date   DATE,
    status       VARCHAR(20)
);

INSERT INTO shop.customers (name, city, age) VALUES
    ('Alice',   'Mumbai',    28),
    ('Bob',     'Pune',      35),
    ('Carol',   'Mumbai',    22),
    ('David',   'Delhi',     40),
    ('Eva',     'Pune',      31),
    ('Frank',   'Delhi',     26),
    ('Grace',   'Bangalore', 45),
    ('Henry',   'Mumbai',    19);

INSERT INTO shop.products (product_name, category, price) VALUES
    ('Laptop',       'Electronics', 60000.00),
    ('Phone',        'Electronics', 25000.00),
    ('Headphones',   'Electronics',  3000.00),
    ('Desk',         'Furniture',   15000.00),
    ('Chair',        'Furniture',    8000.00),
    ('Notebook',     'Stationery',    200.00),
    ('Pen',          'Stationery',     50.00),
    ('Monitor',      'Electronics', 18000.00);

INSERT INTO shop.orders (customer_id, product_id, quantity, order_date, status) VALUES
    (1, 1, 1, '2024-01-05', 'delivered'),
    (1, 3, 2, '2024-02-10', 'delivered'),
    (2, 2, 1, '2024-01-20', 'pending'),
    (3, 6, 5, '2024-03-01', 'delivered'),
    (4, 1, 1, '2024-01-15', 'delivered'),
    (4, 4, 1, '2024-02-20', 'cancelled'),
    (5, 5, 2, '2024-03-10', 'delivered'),
    (6, 7, 10,'2024-02-05', 'delivered'),
    (7, 8, 1, '2024-01-25', 'shipped'),
    (8, 2, 1, '2024-03-15', 'pending');


-- ============================================================
-- PROBLEMS
-- ============================================================


-- ------------------------------------------------------------
-- Problem 1 — SELECT with filter
-- ------------------------------------------------------------
-- Write a query that returns the name and city of all customers
-- who live in 'Mumbai'.
--
-- Expected output (3 rows):
-- name  | city
-- ------+--------
-- Alice | Mumbai
-- Carol | Mumbai
-- Henry | Mumbai
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 2 — SELECT with ORDER BY and LIMIT
-- ------------------------------------------------------------
-- Write a query that returns the top 3 most expensive products.
-- Show product_name and price. Sort by price descending.
--
-- Expected output (3 rows):
-- product_name | price
-- -------------+----------
-- Laptop       | 60000.00
-- Phone        | 25000.00
-- Monitor      | 18000.00
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 3 — WHERE with multiple conditions
-- ------------------------------------------------------------
-- Write a query that returns customers who are older than 30
-- AND live in 'Pune' or 'Delhi'.
-- Show name, city, and age.
--
-- Expected output (3 rows):
-- name  | city  | age
-- ------+-------+-----
-- Bob   | Pune  | 35
-- David | Delhi | 40
-- Eva   | Pune  | 31
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 4 — CASE statement
-- ------------------------------------------------------------
-- Write a query that returns all products with a new column
-- called price_range:
--   price >= 20000  → 'Expensive'
--   price >= 5000   → 'Moderate'
--   otherwise       → 'Cheap'
-- Show product_name, price, and price_range.
-- Sort by price descending.
--
-- Expected output (8 rows):
-- product_name | price     | price_range
-- -------------+-----------+------------
-- Laptop       | 60000.00  | Expensive
-- Phone        | 25000.00  | Expensive
-- Monitor      | 18000.00  | Moderate
-- Desk         | 15000.00  | Moderate
-- Chair        |  8000.00  | Moderate
-- Headphones   |  3000.00  | Cheap
-- Notebook     |   200.00  | Cheap
-- Pen          |    50.00  | Cheap
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 5 — GROUP BY
-- ------------------------------------------------------------
-- Write a query that shows how many products are in each
-- category and what the average price is (rounded to 2 places).
-- Show category, product_count, avg_price.
-- Sort by product_count descending.
--
-- Expected output (3 rows):
-- category    | product_count | avg_price
-- ------------+---------------+-----------
-- Electronics |       4       | 26500.00
-- Furniture   |       2       | 11500.00
-- Stationery  |       2       |   125.00
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 6 — INNER JOIN
-- ------------------------------------------------------------
-- Write a query that shows each order with the customer name
-- and the product name they ordered.
-- Show order_id, customer name, product name, and order_date.
-- Sort by order_id.
--
-- Expected output (10 rows):
-- order_id | name  | product_name | order_date
-- ---------+-------+--------------+------------
--        1 | Alice | Laptop       | 2024-01-05
--        2 | Alice | Headphones   | 2024-02-10
--        3 | Bob   | Phone        | 2024-01-20
--        4 | Carol | Notebook     | 2024-03-01
--        5 | David | Laptop       | 2024-01-15
--        6 | David | Desk         | 2024-02-20
--        7 | Eva   | Chair        | 2024-03-10
--        8 | Frank | Pen          | 2024-02-05
--        9 | Grace | Monitor      | 2024-01-25
--       10 | Henry | Phone        | 2024-03-15
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 7 — LEFT JOIN
-- ------------------------------------------------------------
-- Write a query that shows all customers and the number of
-- orders they have placed. Customers with no orders should
-- show 0.
-- Show name and order_count. Sort by order_count descending,
-- then name ascending.
--
-- Expected output (8 rows):
-- name  | order_count
-- ------+------------
-- Alice |      2
-- David |      2
-- Bob   |      1
-- Carol |      1
-- Eva   |      1
-- Frank |      1
-- Grace |      1
-- Henry |      1
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 8 — GROUP BY + HAVING
-- ------------------------------------------------------------
-- Write a query that returns cities where the average customer
-- age is greater than 30.
-- Show city and avg_age (rounded to 1 decimal place).
-- Sort by avg_age descending.
--
-- Expected output (3 rows):
-- city      | avg_age
-- ----------+---------
-- Bangalore |   45.0
-- Delhi     |   33.0
-- Pune      |   33.0
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 9 — JOIN + WHERE filter
-- ------------------------------------------------------------
-- Write a query that lists all DELIVERED orders.
-- Show customer name, product name, quantity, and order_date.
-- Sort by order_date.
--
-- Expected output (6 rows):
-- name  | product_name | quantity | order_date
-- ------+--------------+----------+------------
-- Alice | Laptop       |    1     | 2024-01-05
-- David | Laptop       |    1     | 2024-01-15
-- Frank | Pen          |   10     | 2024-02-05
-- Alice | Headphones   |    2     | 2024-02-10
-- Carol | Notebook     |    5     | 2024-03-01
-- Eva   | Chair        |    2     | 2024-03-10
-- ------------------------------------------------------------

-- YOUR ANSWER:


-- ------------------------------------------------------------
-- Problem 10 — JOIN + GROUP BY + expression
-- ------------------------------------------------------------
-- Write a query that calculates the total amount spent by each
-- customer (quantity × price). Only include delivered orders.
-- Show customer name and total_spent. Sort by total_spent desc.
--
-- Expected output (5 rows):
-- name  | total_spent
-- ------+------------
-- Alice | 66000.00
-- David | 60000.00
-- Frank |    500.00
-- Eva   |  16000.00
-- Carol |   1000.00
-- ------------------------------------------------------------

-- YOUR ANSWER:
