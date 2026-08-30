-- =============================================================
-- Problem 6 — Previous and Next Record Comparison
-- Pattern: LAG to pull previous row value into the current row
-- =============================================================
-- Question:
--   For each department and month, show the current revenue and
--   the previous month's revenue (prev_revenue).
--   First month per department should show NULL for prev_revenue.
--   Order by dept, month.
-- =============================================================

DROP TABLE IF EXISTS monthly_revenue;

CREATE TABLE monthly_revenue (
    rev_id   SERIAL PRIMARY KEY,
    dept     VARCHAR(50),
    month    DATE,
    revenue  NUMERIC(12,2)
);

INSERT INTO monthly_revenue (dept, month, revenue) VALUES
    ('Engineering', '2024-01-01', 120000.00),
    ('Engineering', '2024-02-01', 135000.00),
    ('Engineering', '2024-03-01', 128000.00),
    ('Engineering', '2024-04-01', 142000.00),
    ('Sales',       '2024-01-01',  95000.00),
    ('Sales',       '2024-02-01',  88000.00),
    ('Sales',       '2024-03-01', 102000.00),
    ('Sales',       '2024-04-01',  97000.00);

-- Expected output:
--
--   dept        | month      | revenue    | prev_revenue
--   ------------+------------+------------+-------------
--   Engineering | 2024-01-01 | 120000.00  | NULL
--   Engineering | 2024-02-01 | 135000.00  | 120000.00
--   Engineering | 2024-03-01 | 128000.00  | 135000.00
--   Engineering | 2024-04-01 | 142000.00  | 128000.00
--   Sales       | 2024-01-01 |  95000.00  | NULL
--   Sales       | 2024-02-01 |  88000.00  |  95000.00
--   Sales       | 2024-03-01 | 102000.00  |  88000.00
--   Sales       | 2024-04-01 |  97000.00  | 102000.00

-- YOUR ANSWER:
