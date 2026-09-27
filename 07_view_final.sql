-- STAGE 7: FINAL CONSOLIDATED VIEW

-- =====================================================================
-- HOW THIS SOLUTION WORKS:
-- Every previous stage (RFM in Stage 4, NTILE scoring/segmentation in Stage 5, and LAG-based churn detection in Stage 6) is combined here into a single CREATE VIEW statement. A VIEW is a saved, named query: once created, it can be queried with a plain "SELECT * FROM vw_customer_rfm_churn" exactly as if it were a normal table — a BI tool (Power BI, Metabase, Tableau) or another analyst can plug into it without ever needing to understand the RFM/NTILE/LAG logic behind it. This is the layer that turns a set of one-off analysis queries into a reusable, production-style asset.

-- The structure is simply the same chain of CTEs used in Stages 4-6, wrapped inside CREATE OR REPLACE VIEW instead of a standalone SELECT. "OR REPLACE" means re-running this script safely updates the view's definition instead of failing because it already exists.
-- =====================================================================

CREATE OR REPLACE VIEW vw_customer_rfm_churn AS
WITH rfm_base AS (
    SELECT
        c.id AS customer_id,
        c.name,
        CURRENT_DATE - MAX(o.order_date) AS recency_days,
        COUNT(o.id) AS frequency,
        SUM(o.amount) AS monetary
    FROM customers c
    JOIN orders o 
        ON o.customer_id = c.id
    GROUP BY 
        c.id, 
        c.name
),
rfm_scores AS (
    SELECT
        customer_id, 
        name, 
        recency_days, 
        frequency,
        ROUND(monetary, 2) AS monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score, -- DESC: recência menor (mais recente) ganha nota 5
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score, -- ASC: frequência maior ganha nota 5
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score  -- ASC: gasto maior ganha nota 5
    FROM rfm_base
),
rfm_segmented AS (
    SELECT
        *, 
        (r_score + f_score + m_score) AS rfm_total,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 THEN 'Champion'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customer'
            WHEN r_score >= 2 AND f_score >= 3 THEN 'At risk'
            WHEN r_score >= 2 AND f_score >= 2 THEN 'Lost'
            ELSE 'New / Occasional'
        END AS segment
    FROM rfm_scores
),
intervals AS (
    SELECT
        customer_id,
        order_date - LAG(order_date) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) AS days_since_previous_order
    FROM orders
),
average_cycle AS (
    SELECT
        customer_id,
        ROUND(AVG(days_since_previous_order), 1) AS average_cycle_days
    FROM intervals
    WHERE days_since_previous_order IS NOT NULL
    GROUP BY customer_id
)
SELECT
    r.customer_id, 
    r.name, 
    r.recency_days, 
    r.frequency, 
    r.monetary, 
    r.r_score, 
    r.f_score, 
    r.m_score, 
    r.rfm_total, 
    r.segment, 
    ac.average_cycle_days,
    ROUND(r.recency_days / NULLIF(ac.average_cycle_days, 0), 2) AS overdue_ratio,
    CASE
        WHEN ac.average_cycle_days IS NULL THEN 'Not enough history'
        WHEN r.recency_days > ac.average_cycle_days * 2 THEN 'Likely churned'
        WHEN r.recency_days > ac.average_cycle_days * 1.5 THEN 'At risk'
        ELSE 'Active'
    END AS churn_status
FROM rfm_segmented r
LEFT JOIN average_cycle ac 
    ON ac.customer_id = r.customer_id;

-- Query the view exactly like a table:
SELECT * FROM vw_customer_rfm_churn ORDER BY rfm_total DESC;