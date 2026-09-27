-- STAGE 6: CHURN DETECTION (BASED IN EACH CUSTOMER'S OWN CADENCE)

-- =====================================================================
-- HOW THIS SOLUTION WORKS:
-- A fixed rule like "more than 90 days without an order = at risk" is naive: a customer who normally orders every 10 days and has gone quiet for 25 days is more overdue than one who normally orders every 60 days and has gone quiet for 70. This script instead compares how long a customer has been silent against THEIR OWN historical ordering cadence.

-- Step by step:
-- 1. "intervals" uses LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) to look, for each order, at the date of that SAME customer's previous order. PARTITION BY is essential here — without it, LAG would compare orders across different customers. Each customer's very first order naturally produces NULL (there is no earlier order to compare against).
-- 2. "average_cycle" averages those gaps per customer, ignoring the NULL from each customer's first order, giving each customer's typical number of days between orders.
-- 3. The final SELECT compares that typical cycle against how many days have actually passed since the last order, producing an "overdue_ratio" — e.g. 2.3 means the customer has been silent for 2.3x their normal cycle.
-- =====================================================================

WITH intervals AS (
    SELECT
        customer_id,
        order_date,
        order_date - LAG(order_date) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) AS days_since_previous_order
    FROM orders
),
average_cycle AS (
    SELECT
        customer_id,
        ROUND(AVG(days_since_previous_order), 1) AS average_cycle_days -- Calcula o ciclo médio de compras (ignora NULLs)
    FROM intervals
    GROUP BY customer_id
),
last_order AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        CURRENT_DATE - MAX(order_date) AS days_since_last_order -- Calcula dias desde a última compra
    FROM orders
    GROUP BY customer_id
)

SELECT
    c.id,
    c.name,
    ac.average_cycle_days,
    lo.days_since_last_order,
    ROUND(lo.days_since_last_order / NULLIF(ac.average_cycle_days, 0), 2) AS overdue_ratio,
    CASE
        WHEN ac.average_cycle_days IS NULL THEN 'Not enough history'
        WHEN lo.days_since_last_order > ac.average_cycle_days * 2 THEN 'Likely churned'
        WHEN lo.days_since_last_order > ac.average_cycle_days * 1.5 THEN 'At risk'
        ELSE 'Active'
    END AS churn_status
FROM customers c
JOIN last_order lo 
    ON lo.customer_id = c.id
LEFT JOIN average_cycle ac 
    ON ac.customer_id = c.id
ORDER BY 
    overdue_ratio DESC NULLS LAST;