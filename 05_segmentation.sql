-- STAGE 5: Customer segmentation using NTILE and a scoring rule

WITH rfm_base AS (
    SELECT 
        c.id AS customer_id,
        c.name,
        CURRENT_DATE - MAX(o.order_date) AS recency_days,  -- Adicionado o '-' que faltava
        COUNT(o.id)                      AS frequency,
        SUM(o.amount)                    AS monetary
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