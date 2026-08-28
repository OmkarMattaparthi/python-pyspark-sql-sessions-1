-- =============================================================
-- Problem 5 — Find Missing IDs  (LeetCode #1613)
-- DATA ENGINEER SQL INTERVIEW CHALLENGE
-- =============================================================
-- Question:
--   Find the missing customer IDs. Missing IDs are those that
--   are NOT in the table but are strictly between 1 and the
--   maximum customer_id in the table.
--   Return the result ordered by ids ascending.
-- =============================================================

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id    INT PRIMARY KEY,
    customer_name  VARCHAR(50)
);

INSERT INTO customers (customer_id, customer_name) VALUES
    (1, 'Alice'),
    (4, 'Bob'),
    (5, 'Charlie');

-- Expected output:
--
--   ids
--   ---
--     2
--     3
--
-- Note: max customer_id = 5, so we check 1 to 5.
--       IDs 2 and 3 are missing from the table.

-- YOUR ANSWER:
