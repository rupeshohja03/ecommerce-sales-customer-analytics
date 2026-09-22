-- 02_create_tables.sql
-- Creates all core tables with primary keys, foreign keys, and data types

USE ecommerce_analytics;

-- ========================
-- CUSTOMERS TABLE
-- ========================
CREATE TABLE customers (
    customer_id     INT AUTO_INCREMENT PRIMARY KEY,
    customer_name   VARCHAR(100),
    email           VARCHAR(100),
    phone           VARCHAR(20),
    city            VARCHAR(50),
    state           VARCHAR(50),
    signup_date     DATE,
    customer_rating DECIMAL(2,1)
);

-- ========================
-- PRODUCTS TABLE
-- ========================
CREATE TABLE products (
    product_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_name    VARCHAR(150),
    category        VARCHAR(50),
    price           DECIMAL(10,2),
    cost_price      DECIMAL(10,2)
);

-- ========================
-- ORDERS TABLE
-- ========================
CREATE TABLE orders (
    order_id        INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT,
    order_date      DATE,
    order_status    VARCHAR(30),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ========================
-- ORDER_ITEMS TABLE
-- ========================
CREATE TABLE order_items (
    order_item_id   INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT,
    product_id      INT,
    quantity        INT,
    unit_price      DECIMAL(10,2),
    CONSTRAINT fk_orderitems_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_orderitems_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ========================
-- PAYMENTS TABLE
-- ========================
CREATE TABLE payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT,
    payment_method  VARCHAR(30),
    payment_status  VARCHAR(30),
    payment_date    DATE,
    amount_paid     DECIMAL(10,2),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

SELECT 'All 5 tables created successfully' AS status;