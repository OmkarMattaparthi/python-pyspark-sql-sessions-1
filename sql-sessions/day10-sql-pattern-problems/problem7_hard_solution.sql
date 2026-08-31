-- =============================================================
-- Problem 7 Hard Solution — Multi-Metric Agent Ranking
-- *** Instructor use only ***
-- =============================================================


-- =============================================================
-- APPROACH 1 — CTE: conditional aggregation → RANK on resolution_rate
-- =============================================================

WITH agent_stats AS (
    SELECT
        agent,
        COUNT(*)                                                             AS total_tickets,
        COUNT(CASE WHEN priority = 'High' AND status = 'Resolved' THEN 1 END) AS high_resolved,
        COUNT(CASE WHEN priority = 'High' AND status = 'Open'     THEN 1 END) AS high_open,
        ROUND(
            COUNT(CASE WHEN status = 'Resolved' THEN 1 END) * 100.0 / COUNT(*),
            1
        )                                                                    AS resolution_rate,
        ROUND(
            COUNT(CASE WHEN priority = 'High' AND status = 'Resolved' THEN 1 END) * 100.0
            / NULLIF(COUNT(CASE WHEN priority = 'High' THEN 1 END), 0),
            1
        )                                                                    AS high_res_rate
    FROM support_tickets
    GROUP BY agent
)
SELECT
    agent,
    total_tickets,
    high_resolved,
    high_open,
    resolution_rate,
    high_res_rate,
    RANK() OVER (ORDER BY resolution_rate DESC) AS overall_rank
FROM agent_stats
ORDER BY overall_rank, agent;


-- =============================================================
-- APPROACH 2 — FILTER clause (PostgreSQL shorthand for CASE WHEN)
-- =============================================================

WITH agent_stats AS (
    SELECT
        agent,
        COUNT(*)                                                              AS total_tickets,
        COUNT(*) FILTER (WHERE priority = 'High' AND status = 'Resolved')    AS high_resolved,
        COUNT(*) FILTER (WHERE priority = 'High' AND status = 'Open')        AS high_open,
        ROUND(
            COUNT(*) FILTER (WHERE status = 'Resolved') * 100.0 / COUNT(*),
            1
        )                                                                     AS resolution_rate,
        ROUND(
            COUNT(*) FILTER (WHERE priority = 'High' AND status = 'Resolved') * 100.0
            / NULLIF(COUNT(*) FILTER (WHERE priority = 'High'), 0),
            1
        )                                                                     AS high_res_rate
    FROM support_tickets
    GROUP BY agent
)
SELECT
    agent,
    total_tickets,
    high_resolved,
    high_open,
    resolution_rate,
    high_res_rate,
    RANK() OVER (ORDER BY resolution_rate DESC) AS overall_rank
FROM agent_stats
ORDER BY overall_rank, agent;


-- =============================================================
-- APPROACH 3 — Two-level aggregation: separate High subquery joined back
-- =============================================================
-- Compute overall stats and High-priority stats separately, then join.
-- More verbose but makes each sub-problem independently readable.

WITH overall AS (
    SELECT
        agent,
        COUNT(*)  AS total_tickets,
        COUNT(*) FILTER (WHERE status = 'Resolved') AS total_resolved,
        ROUND(COUNT(*) FILTER (WHERE status = 'Resolved') * 100.0 / COUNT(*), 1) AS resolution_rate
    FROM support_tickets
    GROUP BY agent
),
high_priority AS (
    SELECT
        agent,
        COUNT(*) FILTER (WHERE status = 'Resolved') AS high_resolved,
        COUNT(*) FILTER (WHERE status = 'Open')     AS high_open,
        COUNT(*)                                     AS total_high,
        ROUND(
            COUNT(*) FILTER (WHERE status = 'Resolved') * 100.0
            / NULLIF(COUNT(*), 0),
            1
        ) AS high_res_rate
    FROM support_tickets
    WHERE priority = 'High'
    GROUP BY agent
)
SELECT
    o.agent,
    o.total_tickets,
    COALESCE(h.high_resolved, 0) AS high_resolved,
    COALESCE(h.high_open, 0)     AS high_open,
    o.resolution_rate,
    COALESCE(h.high_res_rate, 0) AS high_res_rate,
    RANK() OVER (ORDER BY o.resolution_rate DESC) AS overall_rank
FROM overall o
LEFT JOIN high_priority h ON o.agent = h.agent
ORDER BY overall_rank, o.agent;

-- Note:
--   NULLIF(…, 0) protects the high_res_rate division: an agent with no High
--   tickets would cause division-by-zero without it.
--   RANK() is used (not DENSE_RANK / ROW_NUMBER) so tied agents share the same
--   rank and the next rank is skipped (Alice and Carol both get rank 1 → Bob gets 3).
--   COALESCE in Approach 3 handles agents who have zero High-priority tickets
--   (they won't appear in the high_priority CTE).
