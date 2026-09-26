-- STAGE 4: Calculating RFM (Recency, Frequency, Monetary)

-- =====================================================================
-- HOW THIS SOLUTION WORKS:
-- RFM is a standard customer-analysis technique built from three numbers, calculated per customer from the "orders" table:
--		- Recency:  how many days since their last order (lower = better)
--		- Frequency: how many orders they have placed  (higher = better)
--		- Monetary: how much they have spent in total  (higher = better)
-- The CTE (WITH clause) below computes all three in a single pass over the data using standard aggregate functions (MAX, COUNT, SUM) grouped by customer. Keeping this logic in its own named CTE ("rfm_base") means later stages (5 and 6) can build directly on top of it instead of repeating the same GROUP BY logic every time.

-- The second query below is a data-quality check: before turning these raw numbers into 1-5 scores (Stage 5), it is worth knowing the actual range of each metric, the same way an analyst would before deciding where to draw the cut-off points.
-- =====================================================================

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

-- ---------------------------------------------------------------------------------------------------
-- DATA-QUALITY CHECK: confirms the range of each RFM metric before any scoring is applied in Stage 5.
-- ---------------------------------------------------------------------------------------------------

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