-- =============================================================
-- Problem 7 Hard — Conditional Aggregation
-- Pattern: Multi-level pivot + resolution rate + ranking agents
-- =============================================================
-- Question:
--   For each agent produce:
--     - total_tickets     : total tickets handled
--     - high_resolved     : High priority tickets that are Resolved
--     - high_open         : High priority tickets that are Open
--     - resolution_rate   : overall % of tickets that are Resolved (rounded to 1 dp)
--     - high_res_rate     : % of High priority tickets that are Resolved (rounded to 1 dp)
--     - overall_rank      : rank by resolution_rate DESC (ties share same rank)
--   Order by overall_rank, agent.
-- =============================================================

DROP TABLE IF EXISTS support_tickets;

CREATE TABLE support_tickets (
    ticket_id  SERIAL PRIMARY KEY,
    agent      VARCHAR(50),
    category   VARCHAR(50),
    status     VARCHAR(20),
    priority   VARCHAR(10),
    created_at DATE
);

INSERT INTO support_tickets (agent, category, status, priority, created_at) VALUES
    ('Alice', 'Billing',   'Resolved', 'High',   '2024-01-05'),
    ('Alice', 'Technical', 'Open',     'Low',    '2024-01-06'),
    ('Alice', 'Billing',   'Resolved', 'Medium', '2024-01-07'),
    ('Alice', 'Technical', 'Resolved', 'High',   '2024-01-08'),
    ('Bob',   'Billing',   'Open',     'High',   '2024-01-05'),
    ('Bob',   'Technical', 'Resolved', 'Medium', '2024-01-06'),
    ('Bob',   'Billing',   'Resolved', 'Low',    '2024-01-07'),
    ('Bob',   'Technical', 'Open',     'High',   '2024-01-08'),
    ('Carol', 'Billing',   'Resolved', 'Low',    '2024-01-05'),
    ('Carol', 'Technical', 'Resolved', 'Medium', '2024-01-06'),
    ('Carol', 'Billing',   'Open',     'High',   '2024-01-07'),
    ('Carol', 'Technical', 'Resolved', 'High',   '2024-01-08');

-- Expected output:
--
--   agent | total_tickets | high_resolved | high_open | resolution_rate | high_res_rate | overall_rank
--   ------+---------------+---------------+-----------+-----------------+---------------+-------------
--   Alice |             4 |             2 |         0 |            75.0 |         100.0 |            1
--   Carol |             4 |             1 |         1 |            75.0 |          50.0 |            1
--   Bob   |             4 |             0 |         2 |            50.0 |           0.0 |            3
--
-- Note: Alice and Carol both have 75% resolution rate → both rank 1.
--       Bob has 50% → ranks 3 (RANK skips 2 after tie at 1).

-- YOUR ANSWER:
