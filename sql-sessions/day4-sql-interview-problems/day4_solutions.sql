-- ============================================================
-- Day 4 — SQL Interview Problems: SOLUTION SHEET
-- *** For instructor use only — do not share with students ***
-- ============================================================
-- Run day4_problems.sql SETUP section first before running
-- any solution here.
-- ============================================================


-- ------------------------------------------------------------
-- Solution 1 — SELECT + CASE (tier_discount + COALESCE city)
-- ------------------------------------------------------------
SELECT
    name,
    COALESCE(city, 'Unknown') AS city,
    tier,
    CASE tier
        WHEN 'Gold'   THEN '15%'
        WHEN 'Silver' THEN '10%'
        WHEN 'Bronze' THEN '5%'
    END AS tier_discount
FROM store.customers
ORDER BY
    CASE tier
        WHEN 'Gold'   THEN 1
        WHEN 'Silver' THEN 2
        WHEN 'Bronze' THEN 3
    END,
    name;

-- Key concepts tested: simple CASE, COALESCE, CASE in ORDER BY


-- ------------------------------------------------------------
-- Solution 2 — Aggregation + GROUP BY + HAVING
-- ------------------------------------------------------------
SELECT
    category,
    COUNT(*)                     AS total_products,
    ROUND(AVG(price), 2)         AS avg_price,
    SUM(stock)                   AS total_stock
FROM store.products
GROUP BY category
HAVING AVG(price) > 5000
ORDER BY avg_price DESC;

-- Key concepts tested: COUNT(*), AVG, SUM, GROUP BY, HAVING vs WHERE


-- ------------------------------------------------------------
-- Solution 3 — INNER JOIN (3 tables: orders + customers + order_items)
-- ------------------------------------------------------------
SELECT
    o.order_id,
    c.name,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) AS order_total
FROM store.orders        o
JOIN store.customers     c  ON o.customer_id = c.customer_id
JOIN store.order_items   oi ON o.order_id    = oi.order_id
WHERE o.status = 'delivered'
GROUP BY o.order_id, c.name, o.order_date
ORDER BY order_total DESC;

-- Key concepts tested: multi-table INNER JOIN, GROUP BY on joined columns,
-- aggregate on expression (quantity * unit_price)


-- ------------------------------------------------------------
-- Solution 4 — LEFT JOIN anti-join (customers with no orders)
-- ------------------------------------------------------------
SELECT
    c.customer_id,
    c.name,
    c.city
FROM store.customers c
LEFT JOIN store.orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Key concepts tested: LEFT JOIN anti-join pattern (WHERE right side IS NULL)
-- Expected: 0 rows because all 8 customers have at least 1 order.


-- ------------------------------------------------------------
-- Solution 5 — Conditional aggregation with CASE inside COUNT/SUM
-- ------------------------------------------------------------
SELECT
    c.name,
    COUNT(o.order_id)                                            AS total_orders,
    COUNT(CASE WHEN o.status = 'delivered'  THEN 1 END)         AS delivered_count,
    COUNT(CASE WHEN o.status = 'cancelled'  THEN 1 END)         AS cancelled_count
FROM store.customers c
JOIN store.orders    o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_orders DESC, c.name;

-- Key concepts tested: CASE inside COUNT (counts only non-NULL results),
-- conditional aggregation without sub-queries


-- ------------------------------------------------------------
-- Solution 6 — 3-table JOIN + filter on status + top N
-- ------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM store.order_items   oi
JOIN store.orders        o  ON oi.order_id   = o.order_id
JOIN store.products      p  ON oi.product_id = p.product_id
WHERE o.status = 'delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 3;

-- Key concepts tested: 3-way JOIN, aggregate filter via WHERE on joined table,
-- LIMIT for top-N


-- ------------------------------------------------------------
-- Solution 7 — SELF JOIN (employee → manager)
-- ------------------------------------------------------------
SELECT
    e.name  AS employee_name,
    m.name  AS manager_name
FROM store.employees e
LEFT JOIN store.employees m ON e.manager_id = m.employee_id
ORDER BY e.name;

-- Key concepts tested: SELF JOIN with two aliases on the same table,
-- LEFT JOIN so employees with no manager (NULL manager_id) still appear


-- ------------------------------------------------------------
-- Solution 8 — Subquery in WHERE (above-category-average price)
-- ------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    p.price,
    ROUND(cat_avg.avg_price, 2) AS avg_price
FROM store.products p
JOIN (
    SELECT category, AVG(price) AS avg_price
    FROM store.products
    GROUP BY category
) cat_avg ON p.category = cat_avg.category
WHERE p.price > cat_avg.avg_price
ORDER BY p.category, p.price DESC;

-- Key concepts tested: derived table (subquery in FROM), join to aggregate
-- subquery, filter on computed value
-- Expected rows:
--   Laptop Pro 15  | Electronics | 85000.00 | 22900.00
--   Standing Desk  | Furniture   | 25000.00 | 13166.67
--   Notebook Pack  | Stationery  |   350.00 |   250.00


-- ------------------------------------------------------------
-- Solution 9 — FULL OUTER JOIN + CASE label
-- ------------------------------------------------------------
SELECT
    COALESCE(c.customer_id, pc.customer_id) AS customer_id,
    c.name,
    CASE
        WHEN c.customer_id IS NOT NULL AND pc.customer_id IS NOT NULL THEN 'Both'
        WHEN c.customer_id IS NOT NULL AND pc.customer_id IS NULL     THEN 'Store only'
        WHEN c.customer_id IS NULL     AND pc.customer_id IS NOT NULL THEN 'List only'
    END AS label
FROM store.customers         c
FULL OUTER JOIN store.priority_customers pc ON c.customer_id = pc.customer_id
ORDER BY COALESCE(c.customer_id, pc.customer_id);

-- Key concepts tested: FULL OUTER JOIN, COALESCE to merge NULLable IDs,
-- CASE on NULL-check of both sides to classify rows


-- ------------------------------------------------------------
-- Solution 10 — Combined: JOINs + GROUP BY + CASE + filter
-- ------------------------------------------------------------
SELECT
    c.city,
    COUNT(DISTINCT c.customer_id)                                   AS customer_count,
    COUNT(DISTINCT o.order_id)                                      AS total_orders,
    COALESCE(SUM(CASE WHEN o.status = 'delivered'
                      THEN oi.quantity * oi.unit_price END), 0)     AS total_revenue,
    CASE
        WHEN COALESCE(SUM(CASE WHEN o.status = 'delivered'
                               THEN oi.quantity * oi.unit_price END), 0) > 100000 THEN 'High Value'
        WHEN COALESCE(SUM(CASE WHEN o.status = 'delivered'
                               THEN oi.quantity * oi.unit_price END), 0) > 20000  THEN 'Medium Value'
        ELSE 'Low Value'
    END AS city_tier
FROM store.customers     c
JOIN store.orders        o  ON c.customer_id = o.customer_id
JOIN store.order_items   oi ON o.order_id    = oi.order_id
WHERE c.city IS NOT NULL
GROUP BY c.city
ORDER BY total_revenue DESC;

-- Key concepts tested: multi-level JOIN, COUNT DISTINCT, conditional SUM
-- (CASE inside SUM for filtered aggregation), COALESCE on aggregate,
-- CASE on aggregate result for label, WHERE on NULL city
