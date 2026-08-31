-- =============================================================
-- Problem 1 Medium — Top N per Group
-- Pattern: RANK to pick top 2 per group, handle ties
-- =============================================================
-- Question:
--   Find the top 2 sales reps by amount in each region.
--   If there is a tie for 2nd place, include both.
--   Return: region, rank, rep_name, amount.
--   Order by region, rank.
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
--   region | rank | rep_name | amount
--   -------+------+----------+---------
--   East   |    1 | Ivy      | 10500.00
--   East   |    2 | Jack     |  9300.00
--   North  |    1 | Alice    |  9500.00
--   North  |    2 | Bob      |  8200.00
--   South  |    1 | Eve      | 11200.00
--   South  |    2 | Frank    |  9800.00
--
-- Note: Use RANK (not ROW_NUMBER) so ties at rank 2 both appear.

-- YOUR ANSWER:
