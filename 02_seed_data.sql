-- STAGE 2: Seed Data

-- First, the 20 customers:
INSERT INTO customers (name, email, signup_date) -- will insert data into these 3 columns of the customers table
SELECT
	'Customer' || i, -- builds the name: "Customer " + the row number (Customer 1, Customer 2...).          || concatenates text
	'customer' || i || '@email.com', -- builds a fake email in the same style: customer1@email.com, customer2@email.com...
	CURRENT_DATE - (300 + (i * 5)) :: INT * INTERVAL '1 day' -- signup date in the past: the higher "i" is, the older the signup
FROM generate_series(1, 20) AS i; -- generates the numbers 1 to 20 automatically, one per customer (no need to write 20 lines by hand)

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
INSERT INTO orders (customer_id, order_date, amount) -- inserts data into these 3 columns of the orders table
SELECT
	c.id, -- uses the customer's id (from the customers table)
	CURRENT_DATE - (s * 15 + (c.id * 2)) :: INT * INTERVAL '1 day',  -- generates dates spaced roughly 15 days apart in the past
	ROUND((50 + random() * 450 ) :: NUMERIC, 2) -- generates a random amount between 50 and 500, rounded to 2 decimal places
FROM customers c
CROSS JOIN generate_series(0, 11) AS s  -- generates 12 orders (s from 0 to 11) for each customer in this group
WHERE c.id BETWEEN 1 AND 5; -- filters only customers with id 1 to 5


	-- GROUP 2 (customer ids 6 to 10): used to order regularly, but stopped roughly 70 days ago
INSERT INTO orders (customer_id, order_date, amount)
SELECT
	c.id,
	CURRENT_DATE - (70 + s * 18 + (c.id * 2)) :: INT * INTERVAL '1 day', -- adds a 70-day "gap" before starting to count the older orders
	ROUND((50 + random() * 450) :: NUMERIC, 2)
FROM customers c
CROSS JOIN generate_series(0, 8) AS s -- 9 orders per customer (s from 0 to 8)
WHERE c.id BETWEEN 6 AND 10;


	-- GROUP 3 (customer ids 11 to 15): lost customers, last order more than 180 days ago
INSERT INTO orders (customer_id, order_date, amount)
SELECT
	c.id,
	CURRENT_DATE - (200 + s * 20 + (c.id * 2)) :: INT * INTERVAL '1 day', -- adds a 200-day "gap" before starting to count the older orders
	ROUND((50 + random() * 450) :: NUMERIC, 2)
FROM customers c
CROSS JOIN generate_series(0, 6) AS s -- 7 orders per customer (s from 0 to 6)
WHERE c.id BETWEEN 11 AND 15;


	-- GROUP 4 (customer ids 16 to 20): new customers, recent signup and few orders
INSERT INTO orders (customer_id, order_date, amount)
SELECT
    c.id,
    CURRENT_DATE - (s * 10 + c.id) :: INT * INTERVAL '1 day', -- fairly recent dates, with no "gap" period
    ROUND((50 + random() * 450)::NUMERIC, 2)
FROM customers c
CROSS JOIN generate_series(0, 2) AS s -- only 3 orders per customer (s from 0 to 2)
WHERE c.id BETWEEN 16 AND 20;


--------------------------------------------------------------------------------------------------------------------

-- CHECKING WHETHER EVERYTHING WORKED
/*
SELECT
    customer_id, -- customer id
    COUNT(*) AS total_orders, -- counts how many orders this customer has
    MIN(order_date) AS first_order, -- date of their oldest order
    MAX(order_date) AS last_order -- date of their most recent order
FROM orders
GROUP BY customer_id -- groups orders by customer, so the functions above calculate per customer
ORDER BY customer_id; -- orders the result by id, just to keep it tidy
*/

--------------------------------------------------------------------------------------------------------------------