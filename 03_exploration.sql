-- STAGE 3: Exploratory queries

-- Overall volume: how many customers, orders, total revenue and average order value
SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers, -- counts how many customers exist in total
    (SELECT COUNT(*) FROM orders) AS total_orders, -- counts how many orders exist in total
    (SELECT ROUND(SUM(amount), 2) FROM orders) AS total_revenue, -- sums the amount of every order
    (SELECT ROUND(AVG(amount), 2) FROM orders) AS average_order_value; -- calculates the average order amount

-- Revenue and order count per costumer
SELECT 
	c.id,
	c.name,
	COUNT(o.id) AS total_orders,
	ROUND(SUM(o.amount), 2) AS total_revenue,
	ROUND(AVG(o.amount), 2) AS average_order_value;
FROM costumers c
LEFT JOIN