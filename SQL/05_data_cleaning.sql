-- 05_data_cleaning.sql
-- Creates clean/analytics tables from raw tables. Raw tables remain untouched.
USE ecommerce_analytics;

-- ============================================================
-- DROP OLD CLEAN TABLES IF RE-RUNNING (safe to re-run)
-- ============================================================
DROP TABLE IF EXISTS clean_order_items;
DROP TABLE IF EXISTS clean_payments;
DROP TABLE IF EXISTS clean_orders;
DROP TABLE IF EXISTS clean_products;
DROP TABLE IF EXISTS clean_customers;

-- ============================================================
-- CLEAN CUSTOMERS
-- - remove exact duplicates
-- - standardize city/state casing
-- - handle NULL email/phone
-- ============================================================
CREATE TABLE clean_customers AS
SELECT
    MIN(customer_id) AS customer_id,   -- keep the lowest ID among duplicates
    customer_name,
    COALESCE(email, 'not_provided') AS email,
    COALESCE(phone, 'not_provided') AS phone,
    CONCAT(UPPER(LEFT(TRIM(city),1)), LOWER(SUBSTRING(TRIM(city),2))) AS city,
    state,
    signup_date,
    customer_rating
FROM customers
GROUP BY customer_name, email, phone,
         CONCAT(UPPER(LEFT(TRIM(city),1)), LOWER(SUBSTRING(TRIM(city),2))),
         state, signup_date, customer_rating;

ALTER TABLE clean_customers ADD PRIMARY KEY (customer_id);

-- ============================================================
-- CLEAN PRODUCTS
-- - remove exact duplicates
-- - standardize category casing
-- - fix zero/negative prices (set to category average)
-- - fill NULL cost_price with 60% of price (reasonable estimate)
-- ============================================================
CREATE TABLE clean_products AS
SELECT
    MIN(product_id) AS product_id,
    product_name,
    CONCAT(UPPER(LEFT(TRIM(category),1)), LOWER(SUBSTRING(TRIM(category),2))) AS category,
    price,
    cost_price
FROM products
GROUP BY product_name,
         CONCAT(UPPER(LEFT(TRIM(category),1)), LOWER(SUBSTRING(TRIM(category),2))),
         price, cost_price;

ALTER TABLE clean_products ADD PRIMARY KEY (product_id);

-- Fix zero/negative prices -> replace with category average (excluding bad values)
UPDATE clean_products p
JOIN (
    SELECT category, AVG(price) AS avg_price
    FROM clean_products
    WHERE price > 0
    GROUP BY category
) avgs ON p.category = avgs.category
SET p.price = avgs.avg_price
WHERE p.price <= 0;

-- Fill NULL cost_price with 60% of price
UPDATE clean_products
SET cost_price = ROUND(price * 0.6, 2)
WHERE cost_price IS NULL;

-- ============================================================
-- CLEAN ORDERS
-- - standardize order_status casing
-- - fill NULL status with 'Unknown'
-- - fix invalid dates (outside 2022-2026) -> set to signup-safe fallback
-- ============================================================
CREATE TABLE clean_orders AS
SELECT
    order_id,
    customer_id,
    CASE
        WHEN order_date > CURDATE() OR order_date < '2020-01-01' THEN '2024-01-01'
        ELSE order_date
    END AS order_date,
    CASE
        WHEN order_status IS NULL THEN 'Unknown'
        ELSE CONCAT(UPPER(LEFT(TRIM(order_status),1)), LOWER(SUBSTRING(TRIM(order_status),2)))
    END AS order_status
FROM orders;

ALTER TABLE clean_orders ADD PRIMARY KEY (order_id);

-- ============================================================
-- CLEAN ORDER_ITEMS
-- - remove zero/negative quantities
-- - cap unusually high quantities at 10
-- - fill NULL unit_price from clean_products
-- - calculate revenue and profit columns
-- ============================================================
CREATE TABLE clean_order_items AS
SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    CASE WHEN oi.quantity > 50 THEN 10 ELSE oi.quantity END AS quantity,
    COALESCE(oi.unit_price, cp.price) AS unit_price,
    ROUND(CASE WHEN oi.quantity > 50 THEN 10 ELSE oi.quantity END
          * COALESCE(oi.unit_price, cp.price), 2) AS revenue,
    ROUND((CASE WHEN oi.quantity > 50 THEN 10 ELSE oi.quantity END
          * COALESCE(oi.unit_price, cp.price))
          - (CASE WHEN oi.quantity > 50 THEN 10 ELSE oi.quantity END
          * cp.cost_price), 2) AS profit
FROM order_items oi
JOIN clean_products cp ON oi.product_id = cp.product_id
WHERE oi.quantity > 0;

ALTER TABLE clean_order_items ADD PRIMARY KEY (order_item_id);

-- ============================================================
-- CLEAN PAYMENTS
-- - standardize payment_method casing
-- - fill NULL payment_status with 'Unknown'
-- - fill NULL amount_paid with 0
-- ============================================================
CREATE TABLE clean_payments AS
SELECT
    payment_id,
    order_id,
    CONCAT(UPPER(LEFT(TRIM(payment_method),1)), LOWER(SUBSTRING(TRIM(payment_method),2))) AS payment_method,
    COALESCE(payment_status, 'Unknown') AS payment_status,
    payment_date,
    COALESCE(amount_paid, 0) AS amount_paid
FROM payments;

ALTER TABLE clean_payments ADD PRIMARY KEY (payment_id);

-- ============================================================
-- ADD FOREIGN KEYS TO CLEAN TABLES (referential integrity)
-- ============================================================
ALTER TABLE clean_orders
    ADD CONSTRAINT fk_clean_orders_customer
    FOREIGN KEY (customer_id) REFERENCES clean_customers(customer_id);

ALTER TABLE clean_order_items
    ADD CONSTRAINT fk_clean_orderitems_order
    FOREIGN KEY (order_id) REFERENCES clean_orders(order_id),
    ADD CONSTRAINT fk_clean_orderitems_product
    FOREIGN KEY (product_id) REFERENCES clean_products(product_id);

ALTER TABLE clean_payments
    ADD CONSTRAINT fk_clean_payments_order
    FOREIGN KEY (order_id) REFERENCES clean_orders(order_id);

SELECT 'Clean tables created successfully' AS status;
USE ecommerce_analytics;

CREATE TEMPORARY TABLE customer_id_map AS
SELECT
    customer_id,
    MIN(customer_id) OVER (
        PARTITION BY
            customer_name,
            COALESCE(email, ''),
            COALESCE(phone, ''),
            CONCAT(UPPER(LEFT(TRIM(city),1)), LOWER(SUBSTRING(TRIM(city),2))),
            state, signup_date, customer_rating
    ) AS canonical_id
FROM customers;
UPDATE clean_orders o
JOIN customer_id_map m ON o.customer_id = m.customer_id
SET o.customer_id = m.canonical_id
WHERE o.customer_id <> m.canonical_id;
ALTER TABLE clean_orders
    ADD CONSTRAINT fk_clean_orders_customer
    FOREIGN KEY (customer_id) REFERENCES clean_customers(customer_id);
    
    DROP TEMPORARY TABLE IF EXISTS customer_id_map;

ALTER TABLE clean_order_items
    ADD CONSTRAINT fk_clean_orderitems_order
    FOREIGN KEY (order_id) REFERENCES clean_orders(order_id),
    ADD CONSTRAINT fk_clean_orderitems_product
    FOREIGN KEY (product_id) REFERENCES clean_products(product_id);

ALTER TABLE clean_payments
    ADD CONSTRAINT fk_clean_payments_order
    FOREIGN KEY (order_id) REFERENCES clean_orders(order_id);

SELECT 'Clean tables created successfully' AS status;
SELECT COUNT(*) FROM clean_orders o
LEFT JOIN clean_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;