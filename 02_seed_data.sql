-- STAGE 2: Seed Data

-- =====================================================================
-- HOW THIS SOLUTION WORKS:
-- Rather than writing dozens of manual INSERT statements, this script uses PostgreSQL's generate_series() function to generate rows programmatically. generate_series(1, 20) produces the numbers 1 to 20 as if they were rows in a table, and the SELECT around it uses each number to build one customer's name, email and signup date.
-- The same idea is reused with CROSS JOIN to generate multiple orders per customer at once, instead of writing one INSERT per order.

-- The 20 customers are deliberately split into four behavioural
-- groups (5 customers each), each with a different order pattern:
--   - Group 1 (ids 1-5): ACTIVE customers - frequent, recent orders
--   - Group 2 (ids 6-10): AT RISK customers - used to order regularly, but stopped roughly 70 days ago
--   - Group 3 (ids 11-15): LOST customers - last order was more than 180 days ago
--   - Group 4 (ids 16-20): NEW customers - recent signup, only a handful of orders so far
-- This is what gives the later RFM and churn-detection stages something meaningful to distinguish between — with random, unstructured data there would be nothing interesting to segment.
-- =====================================================================


-- 1. Insert 20 customers
INSERT INTO customers (name, email, signup_date)
SELECT
    'Customer ' || i, -- builds the name: "Customer 1", "Customer 2"... (adicionado espaço após 'Customer')
    'customer' || i || '@email.com', -- builds a fake email: customer1@email.com...
    CURRENT_DATE - (300 + (i * 5))::INT * INTERVAL '1 day' -- signup date in the past
FROM generate_series(1, 20) AS i;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- CURRENT_DATE - (300 + (i * 5))::INT * INTERVAL '1 day'

-- Calculation steps
	-- 1. i * 5: multiplies the current row number by 5.
		-- For i = 1, the result is 5.
		-- For i = 20, the result is 100.
	-- 2. 300 + (i * 5): adds a fixed offset of 300 to the result. This guarantees that even the first customer (i = 1) was already signed up more than 300 days ago.
		-- For i = 1: 300 + 5 = 305.
		-- For i = 20: 300 + 100 = 400.
	-- 3. ::INT * INTERVAL '1 day': converts the resulting integer into a day interval in PostgreSQL (e.g. 305 * INTERVAL '1 day' becomes the 305-day interval).
	-- 4. CURRENT_DATE - ...: subtracts that day interval from the system's current date (CURRENT_DATE).

-- Each new customer ends up 5 days older (in signup terms) than the previous one.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	-- GROUP 1 (customer ids 1 to 5): active customers, with recent and frequent orders
INSERT INTO orders (customer_id, order_date, amount)
SELECT
    c.id,
    CURRENT_DATE - (s * 15 + (c.id * 2))::INT * INTERVAL '1 day', -- generates dates spaced roughly 15 days apart
    ROUND((50 + random() * 450)::NUMERIC, 2) -- generates a random amount between 50 and 500
FROM customers c
CROSS JOIN generate_series(0, 11) AS s -- 12 orders per customer
WHERE c.id BETWEEN 1 AND 5;


-- GROUP 2 (customer ids 6 to 10): used to order regularly, but stopped roughly 70 days ago
INSERT INTO orders (customer_id, order_date, amount)
SELECT
    c.id,
    CURRENT_DATE - (70 + s * 18 + (c.id * 2))::INT * INTERVAL '1 day', -- 70-day "gap" before starting older orders
    ROUND((50 + random() * 450)::NUMERIC, 2)
FROM customers c
CROSS JOIN generate_series(0, 8) AS s -- 9 orders per customer
WHERE c.id BETWEEN 6 AND 10;


-- GROUP 3 (customer ids 11 to 15): lost customers, last order more than 180 days ago
INSERT INTO orders (customer_id, order_date, amount)
SELECT
    c.id,
    CURRENT_DATE - (200 + s * 20 + (c.id * 2))::INT * INTERVAL '1 day', -- 200-day "gap" before starting older orders
    ROUND((50 + random() * 450)::NUMERIC, 2)
FROM customers c
CROSS JOIN generate_series(0, 6) AS s -- 7 orders per customer
WHERE c.id BETWEEN 11 AND 15;


-- GROUP 4 (customer ids 16 to 20): low activity customers (3 recent orders)
INSERT INTO orders (customer_id, order_date, amount)
SELECT
    c.id,
    CURRENT_DATE - (s * 10 + c.id)::INT * INTERVAL '1 day', -- recent dates, no gap
    ROUND((50 + random() * 450)::NUMERIC, 2)
FROM customers c
CROSS JOIN generate_series(0, 2) AS s -- 3 orders per customer
WHERE c.id BETWEEN 16 AND 20;

-- --------------------------------------------------------------------------------------------------------------------
-- VERIFICATION QUERY
-- Confirms the four behavioural groups were seeded correctly.
-- Run this separately, after the inserts above.
-- --------------------------------------------------------------------------------------------------------------------

SELECT
    customer_id, -- customer id
    COUNT(*) AS total_orders, -- counts how many orders this customer has
    MIN(order_date) AS first_order, -- date of their oldest order
    MAX(order_date) AS last_order -- date of their most recent order
FROM orders
GROUP BY customer_id -- groups orders by customer, so the functions above calculate per customer
ORDER BY customer_id; -- orders the result by id, just to keep it tidy