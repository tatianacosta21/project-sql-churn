-- STAGE 3: Exploratory queries

-- =====================================================================
-- HOW THIS SOLUTION WORKS:
-- Before building any RFM or churn logic, it is worth looking at the data the same way any analyst would when handed a new dataset: how much data is there, who is spending the most, and who has gone quiet. These four queries answer exactly that, and double as a sanity check that the seed data from Stage 2 was generated correctly (the four behavioural groups should be clearly visible in the results below).
-- =====================================================================

-- Overall volume: how many customers, orders, total revenue and average order value
SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers, -- counts how many customers exist in total
    (SELECT COUNT(*) FROM orders) AS total_orders, -- counts how many orders exist in total
    (SELECT ROUND(SUM(amount), 2) FROM orders) AS total_revenue, -- sums the amount of every order
    (SELECT ROUND(AVG(amount), 2) FROM orders) AS average_order_value; -- calculates the average order amount

-- Revenue and order count per customer
SELECT 
    c.id,
    c.name,
    COUNT(o.id) AS total_orders, -- counts how many orders each customer has
    ROUND(SUM(o.amount), 2) AS total_revenue, -- sums the amount spent by each customer
    ROUND(AVG(o.amount), 2) AS average_order_value -- calculates that customer's average order value
FROM customers c
LEFT JOIN orders o 
    ON o.customer_id = c.id -- LEFT JOIN keeps the customer in the list even if they have no orders
GROUP BY 
    c.id, 
    c.name -- groups by customer, so the functions above are calculated per customer
ORDER BY 
    total_revenue DESC NULLS LAST; -- orders from highest to lowest spend; customer with no orders (NULL) go last

-- Days since each customer's last order (a preview of "Recency", formalised in Stage 4)
SELECT
    c.id,
    c.name,
    MAX(o.order_date) AS last_order, -- gets the date of the customer's most recent order
    CURRENT_DATE - MAX(o.order_date) AS days_since_last_order -- calculate how many days have passed since then (corrigido order_data -> order_date)
FROM customers c 
JOIN orders o 
    ON o.customer_id = c.id -- a plain JOIN here, since this only makes sense for customers who have orders
GROUP BY 
    c.id, 
    c.name
ORDER BY 
    days_since_last_order DESC; -- orders from the most "gone quiet" customer to the most recent one

-- Distribution of orders (useful for spotting outliers before any modelling)
SELECT
    total_orders,
    COUNT(*) AS number_of_customers
FROM (
    SELECT 
        customer_id, 
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY customer_id 
) sub
GROUP BY total_orders
ORDER BY total_orders;