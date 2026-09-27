# 📝 Project Worksheet - Customer Segmentation & Churn Detection

A self-study guide for anyone who wants to build this project from scratch. Each stage gives you the business context and a challenge to try on your own first - the full solution (with explanatory comments) is included right after, so you can check your work or simply follow along if you'd rather learn by reading.

## Before you start

**You'll need:** Docker (to run PostgreSQL locally), a SQL client (DBeaver, Azure Data Studio, or `psql`), and basic familiarity with `SELECT`, `WHERE`, `JOIN` and `GROUP BY`. No prior experience with window functions or CTEs is required - that's what stages 4 to 7 teach.

**How to use this sheet:** for each stage, read the objective, try writing the SQL yourself from the "Your turn" prompt, then compare with the solution. If you get stuck, read the hint before jumping to the answer.

**Setup:**
```bash
docker run -name pg-churn -e POSTGRES_PASSWORD=your_password -p 5432:5432 -d postgres
```
Connect with host `localhost`, port `5432`, user `postgres`.

-

## Stage 1 - Database schema

**Objective:** design a minimal schema for a business that has customers and orders, making sure the database itself enforces basic data quality rules.

**Your turn:** create two tables, `customers` and `orders`. A customer has a name (required), an email (optional) and a signup date. An order belongs to exactly one customer, has a date, and an amount that must always be positive. Make sure it's impossible to insert an order for a customer that doesn't exist.

**Hint:** you'll need `PRIMARY KEY`, `FOREIGN KEY` / `REFERENCES`, and `CHECK`.

**Solution:**
```sql
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY, - auto-incrementing unique identifier
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100), - no NOT NULL: optional field
    signup_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id), - can't reference a customer that doesn't exist
    order_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0) - database rejects zero/negative amounts
);
```

-

## Stage 2 - Seed data

**Objective:** generate realistic test data without writing dozens of manual `INSERT` statements.

**Your turn:** create 20 customers and give them orders following four different behaviours: some order often and recently ("active"), some used to order regularly but stopped a while ago ("at risk"), some haven't ordered in a very long time ("lost"), and a few just signed up ("new"). Try to do it without typing each row by hand.

**Hint:** PostgreSQL's `generate_series(a, b)` produces a sequence of numbers you can use as if they were rows - combine it with `CROSS JOIN` to generate several orders per customer at once.

**Solution (abridged - full script in `02_seed_data.sql`):**
```sql
INSERT INTO customers (name, email, signup_date)
SELECT
    'Customer ' || i,
    'customer' || i || '@email.com',
    CURRENT_DATE - (300 + (i * 5))::INT * INTERVAL '1 day'
FROM generate_series(1, 20) AS i;

- Example for the "active" group (customer ids 1-5):
INSERT INTO orders (customer_id, order_date, amount)
SELECT
    c.id,
    CURRENT_DATE - (s * 15 + (c.id * 2))::INT * INTERVAL '1 day',
    ROUND((50 + random() * 450)::NUMERIC, 2)
FROM customers c
CROSS JOIN generate_series(0, 11) AS s
WHERE c.id BETWEEN 1 AND 5;
- Repeat with different offsets/ranges for the other 3 groups.
```

-

## Stage 3 - Exploratory queries

**Objective:** get a first feel for the data before building anything more advanced - the same checks any analyst runs on a new dataset.

**Your turn:** write queries to answer: how many customers and orders exist in total? What's the total revenue and average order value? How much has each customer spent, and how many days since their last order?

**Hint:** use `LEFT JOIN` (not a plain `JOIN`) when you want customers with zero orders to still show up in the result.

**Solution (one example - see `03_exploration.sql` for all four):**
```sql
SELECT
    c.id, c.name,
    COUNT(o.id) AS total_orders,
    ROUND(SUM(o.amount), 2) AS total_revenue
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY total_revenue DESC NULLS LAST;
```

-

## Stage 4 - RFM calculation

**Objective:** turn raw order history into three business metrics per customer: **R**ecency, **F**requency and **M**onetary value.

**Your turn:** for each customer, calculate how many days since their last order, how many orders they've placed in total, and how much they've spent in total.

**Hint:** `MAX`, `COUNT` and `SUM`, all inside one `GROUP BY c.id`.

**Solution:**
```sql
SELECT
    c.id AS customer_id,
    c.name,
    CURRENT_DATE - MAX(o.order_date) AS recency_days,
    COUNT(o.id) AS frequency,
    ROUND(SUM(o.amount), 2) AS monetary
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

-

## Stage 5 - Customer segmentation

**Objective:** turn the three raw RFM numbers into comparable 1-5 scores, then combine them into a business label.

**Your turn:** score each customer 1 to 5 on each RFM metric (5 =
best), then write a rule that labels someone a "Champion" if all three scores are high, "At risk" if recency is poor but frequency was historically high, and so on.

**Hint:** `NTILE(5) OVER (ORDER BY ...)` splits customers into 5 equal buckets. Careful with direction: for recency, a LOWER number of days is better, so you need to order `DESC` to keep "5 = best" consistent across all three scores.

**Solution:**
```sql
WITH rfm AS (
    SELECT
        c.id AS customer_id, c.name,
        CURRENT_DATE - MAX(o.order_date) AS recency_days,
        COUNT(o.id) AS frequency,
        SUM(o.amount) AS monetary
    FROM customers c JOIN orders o ON o.customer_id = c.id
    GROUP BY c.id, c.name
)
SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
FROM rfm;
- Then wrap in a CASE statement to assign a segment label - see 05_segmentation.sql
```

-

## Stage 6 - Churn detection

**Objective:** flag customers as "at risk" or "likely churned" based on THEIR OWN typical buying rhythm, not a single fixed rule for everyone.

**Your turn:** for each customer, calculate the typical number of days between their orders, then compare that against how long it's been since their last order.

**Hint:** `LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)` looks at each customer's previous order date. `PARTITION BY` is essential - without it you'd compare orders across different customers.

**Solution (core idea - full version in `06_churn.sql`):**
```sql
WITH gaps AS (
    SELECT
        customer_id,
        order_date - LAG(order_date) OVER (
            PARTITION BY customer_id ORDER BY order_date
        ) AS days_since_previous_order
    FROM orders
)
SELECT customer_id, ROUND(AVG(days_since_previous_order), 1) AS average_cycle_days
FROM gaps
WHERE days_since_previous_order IS NOT NULL
GROUP BY customer_id;
```

-

## Stage 7 - Final consolidated view

**Objective:** package everything into something a BI tool or another analyst could query without knowing any of the underlying logic.

**Your turn:** wrap the full RFM + segmentation + churn query chain inside a `CREATE OR REPLACE VIEW`.

**Solution:** see `07_view_final.sql` - it's the same CTE chain from stages 4-6, with `CREATE OR REPLACE VIEW vw_customer_rfm_churn AS` in front of it.

-

## 📚 Glossary

See the glossary section in `README.md` for a one-line explanation of every SQL term used across this worksheet (`SERIAL`, `FOREIGN KEY`, `CHECK`, `generate_series`, `CROSS JOIN`, `WITH`/CTE, `NTILE`, `LAG`, `CASE`, and more).

## ✅ Self-check

By the end of this project you should be able to explain, without looking anything up:

- Why `PARTITION BY` is necessary when using `LAG` on multi-customer data
- Why the recency score uses `ORDER BY ... DESC` while frequency and monetary use `ASC`
- What problem a `VIEW` solves that a one-off query doesn't
- Why a fixed "90 days = churned" rule is weaker than comparing against each customer's own history