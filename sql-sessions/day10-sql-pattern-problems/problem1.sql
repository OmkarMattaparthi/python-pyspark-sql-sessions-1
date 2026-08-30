-- =============================================================
-- Problem 1 — Top N per Group
-- Pattern: ROW_NUMBER / RANK to pick top rows within each group
-- =============================================================
-- Question:
--   Find the top-earning sales rep in each region.
--   Return: region, rep_name, amount.
--   Order by region.
-- =============================================================

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    sale_id    SERIAL PRIMARY KEY,
    rep_name   VARCHAR(50),
    region     VARCHAR(50),
    amount     NUMERIC(10,2),
    sale_date  DATE
);

INSERT INTO sales (rep_name, region, amount, sale_date) VALUES
    ('Alice', 'North', 9500.00,  '2024-01-10'),
    ('Bob',   'North', 8200.00,  '2024-01-15'),
    ('Carol', 'North', 7800.00,  '2024-01-20'),
    ('Dave',  'North', 6100.00,  '2024-01-25'),
    ('Eve',   'South', 11200.00, '2024-01-11'),
    ('Frank', 'South', 9800.00,  '2024-01-16'),
    ('Grace', 'South', 8700.00,  '2024-01-21'),
    ('Hank',  'South', 7400.00,  '2024-01-26'),
    ('Ivy',   'East',  10500.00, '2024-01-12'),
    ('Jack',  'East',  9300.00,  '2024-01-17'),
    ('Karen', 'East',  8100.00,  '2024-01-22');

-- Expected output:
--
--   region | rep_name | amount
--   -------+----------+---------
--   East   | Ivy      | 10500.00
--   North  | Alice    |  9500.00
--   South  | Eve      | 11200.00

-- YOUR ANSWER:
