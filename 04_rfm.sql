-- STAGE 4: Calculating RFM (Recency, Frequency, Monetary)

WITH rfm_base AS (
    SELECT
        c.id AS customer_id,
        c.name,
        CURRENT_DATE - MAX(o.order_date) AS recency_days, -- days since the customer's most recent order (lower is better)
        COUNT(o.id) AS frequency, -- how many orders this customer has placed (higher is better)
        SUM(o.amount) AS monetary -- total amount spent by this customer (higher is better)
    FROM customers c
    JOIN orders o 
        ON o.customer_id = c.id
    GROUP BY 
        c.id, 
        c.name
)

SELECT
    customer_id,
    name,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary
FROM rfm_base
ORDER BY monetary DESC;


-- CHECK THE RANGE OF EACH RFM METRIC BEFORE SCORING
WITH rfm_base AS (
    SELECT
        c.id AS customer_id,
        CURRENT_DATE - MAX(o.order_date) AS recency_days,
        COUNT(o.id) AS frequency,
        SUM(o.amount) AS monetary
    FROM customers c
    JOIN orders o 
        ON o.customer_id = c.id
    GROUP BY c.id
)
SELECT
    MIN(recency_days) AS min_recency, 
    MAX(recency_days) AS max_recency,
    MIN(frequency) AS min_frequency, 
    MAX(frequency) AS max_frequency,
    ROUND(MIN(monetary), 2) AS min_monetary, 
    ROUND(MAX(monetary), 2) AS max_monetary
FROM rfm_base;