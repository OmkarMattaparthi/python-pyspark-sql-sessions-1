-- ============================================================
-- Day 4 — Easy Problems: SOLUTION SHEET
-- *** For instructor use only — do not share with students ***
-- ============================================================

-- Solution 1 — Filter by city
SELECT name, city
FROM shop.customers
WHERE city = 'Mumbai';

-- Solution 2 — Top 3 most expensive products
SELECT product_name, price
FROM shop.products
ORDER BY price DESC
LIMIT 3;

-- Solution 3 — Multiple conditions with AND + OR
SELECT name, city, age
FROM shop.customers
WHERE age > 30
  AND city IN ('Pune', 'Delhi');

-- Solution 4 — CASE for price_range
SELECT
    product_name,
    price,
    CASE
        WHEN price >= 20000 THEN 'Expensive'
        WHEN price >= 5000  THEN 'Moderate'
        ELSE 'Cheap'
    END AS price_range
FROM shop.products
ORDER BY price DESC;

-- Solution 5 — GROUP BY with COUNT and AVG
SELECT
    category,
    COUNT(*)             AS product_count,
    ROUND(AVG(price), 2) AS avg_price
FROM shop.products
GROUP BY category
ORDER BY product_count DESC;

-- Solution 6 — INNER JOIN across 3 tables
SELECT
    o.order_id,
    c.name,
    p.product_name,
    o.order_date
FROM shop.orders    o
JOIN shop.customers c ON o.customer_id = c.customer_id
JOIN shop.products  p ON o.product_id  = p.product_id
ORDER BY o.order_id;

-- Solution 7 — LEFT JOIN with COUNT
SELECT
    c.name,
    COUNT(o.order_id) AS order_count
FROM shop.customers c
LEFT JOIN shop.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY order_count DESC, c.name;

-- Solution 8 — GROUP BY + HAVING on AVG
SELECT
    city,
    ROUND(AVG(age), 1) AS avg_age
FROM shop.customers
GROUP BY city
HAVING AVG(age) > 30
ORDER BY avg_age DESC;

-- Solution 9 — JOIN + WHERE on status
SELECT
    c.name,
    p.product_name,
    o.quantity,
    o.order_date
FROM shop.orders    o
JOIN shop.customers c ON o.customer_id = c.customer_id
JOIN shop.products  p ON o.product_id  = p.product_id
WHERE o.status = 'delivered'
ORDER BY o.order_date;

-- Solution 10 — JOIN + GROUP BY + expression (quantity * price)
SELECT
    c.name,
    SUM(o.quantity * p.price) AS total_spent
FROM shop.orders    o
JOIN shop.customers c ON o.customer_id = c.customer_id
JOIN shop.products  p ON o.product_id  = p.product_id
WHERE o.status = 'delivered'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;
