-- =============================================================
-- Problem 1 — Count Salary Categories  (LeetCode #1907)
-- DATA ENGINEER SQL INTERVIEW CHALLENGE
-- =============================================================
-- Question:
--   Calculate the number of bank accounts in each salary category.
--   Categories:
--     Low Salary     : income < 20000
--     Average Salary : income >= 20000 AND income <= 50000
--     High Salary    : income > 50000
--   Include ALL categories in the output even if the count is 0.
-- =============================================================

DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    account_id  INT PRIMARY KEY,
    income      INT
);

INSERT INTO accounts (account_id, income) VALUES
    (3, 108939),
    (2,  12747),
    (8,  87709),
    (6,  91796);

-- Expected output:
--
--   category       | accounts_count
--   ---------------+---------------
--   Low Salary     |      1
--   Average Salary |      0
--   High Salary    |      3

-- YOUR ANSWER:
