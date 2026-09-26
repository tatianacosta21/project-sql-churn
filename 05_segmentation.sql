-- STAGE 5: Customer segmentation using NTILE and a scoring rule

-- =====================================================================
-- HOW THIS SOLUTION WORKS:
-- This stage turns the three raw RFM numbers from Stage 4 into something comparable: a score from 1 to 5 for each of Recency,
-- Frequency and Monetary, using the window function NTILE(5). NTILE splits the ordered set of customers into 5 equally-sized buckets — bucket 1 holds the "worst" fifth of customers for that metric, bucket 5 holds the "best" fifth.

-- One detail matters here: recency_days is ordered DESC while frequency and monetary are ordered ASC. This is intentional and not a copy-paste mistake — because a LOWER recency_days is better (the customer bought more recently), ordering it DESC means the rows with the MOST days (the worst) end up in bucket 1, and the most recent buyers end up in bucket 5. This keeps "5 = best" consistent across all three scores, which is what makes it valid to simply add r_score + f_score + m_score together afterwards.

-- The three scores are then combined with a CASE statement into a single business-friendly label (Champion, Loyal customer, At risk,
-- Lost, New/Occasional). This rule is a reasonable starting point, not a fixed industry standard — in a real company these thresholds are usually agreed with the marketing/CRM team rather than hard-coded.
-- =====================================================================

WITH rfm_base AS (
    SELECT 
        c.id AS customer_id,
        c.name,
        CURRENT_DATE - MAX(o.order_date) AS recency_days,  -- Adicionado o '-' que faltava
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
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score, -- NTILE corrigido; recency menor é melhor (pico = 5)
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score, -- Ordenado por frequency
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score -- Ordenado por monetary
    FROM rfm_base
)

SELECT
    *,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal customer'
        WHEN r_score >= 2 AND f_score >= 3 THEN 'At risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'New / Occasional'
    END AS segment
FROM rfm_scores
ORDER BY 
    rfm_total DESC, 
    customer_id;