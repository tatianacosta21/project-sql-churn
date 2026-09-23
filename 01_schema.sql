-- STAGE 1: Database schema

CREATE TABLE IF NOT EXISTS customers ( -- creates only if it doesn't already exist; if it does exist, it does nothing and throws no error
    id SERIAL PRIMARY KEY, -- "id" column: auto-incrementing number (1, 2, 3...) serving as the unique key for each row
    name VARCHAR(100) NOT NULL, -- "name" column: text up to 100 characters, mandatory (cannot be empty)
    email VARCHAR(100), -- "email" column: text up to 100 characters, optional (no NOT NULL constraint)
    signup_date DATE NOT NULL -- "signup_date" column: stores only the date (no time), mandatory
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY, -- "id" column: auto-incrementing number, unique key for each order
    customer_id INTEGER NOT NULL -- "customer_id" column: number identifying which customer placed the order
        REFERENCES customers(id), -- ensures this number must be an "id" that already exists in the "customer" table (prevents "orphan" orders)
    order_date DATE NOT NULL, -- "order_date" column: date the order was placed; mandatory
    amount NUMERIC(10, 2) NOT NULL  -- "amount" column: decimal number with up to 10 total digits and 2 decimal places (e.g., 12345678.90)
        CHECK (amount > 0) -- extra rule: prevents registering an order with a zero or negative value
);

-- ------------------------------------------------------------------------------------
-- SERIAL: it is a handy shortcut that creates a column of auto-incrementing integers.
-- ------------------------------------------------------------------------------------