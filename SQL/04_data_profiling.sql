-- 04_data_profiling.sql
-- Full data-quality audit of raw tables before cleaning
USE ecommerce_analytics;

-- ============================================================
-- SECTION 1: DUPLICATE RECORDS
-- ============================================================
SELECT 'Duplicate customers' AS issue, COUNT(*) AS issue_count
FROM (
    SELECT customer_name, email, phone, city
    FROM customers
    GROUP BY customer_name, email, phone, city
    HAVING COUNT(*) > 1
) d
UNION ALL
SELECT 'Duplicate products', COUNT(*)
FROM (
    SELECT product_name, category, price
    FROM products
    GROUP BY product_name, category, price
    HAVING COUNT(*) > 1
) d;

-- ============================================================
-- SECTION 2: NULL / MISSING VALUES
-- ============================================================
SELECT
    'customers' AS table_name,
    SUM(email IS NULL) AS null_email,
    SUM(phone IS NULL) AS null_phone,
    NULL AS null_col3, NULL AS null_col4
FROM customers
UNION ALL
SELECT 'products', SUM(cost_price IS NULL), SUM(price = 0), NULL, NULL FROM products
UNION ALL
SELECT 'orders', SUM(order_status IS NULL), NULL, NULL, NULL FROM orders
UNION ALL
SELECT 'order_items', SUM(unit_price IS NULL), SUM(quantity <= 0), NULL, NULL FROM order_items
UNION ALL
SELECT 'payments', SUM(payment_status IS NULL), SUM(amount_paid IS NULL), NULL, NULL FROM payments;

-- ============================================================
-- SECTION 3: INCONSISTENT TEXT / CAPITALIZATION
-- ============================================================
-- Distinct city spellings (should show mumbai/Mumbai/MUMBAI type issues)
SELECT DISTINCT city FROM customers ORDER BY city;

-- Distinct category spellings
SELECT DISTINCT category FROM products ORDER BY category;

-- Distinct order_status spellings
SELECT DISTINCT order_status FROM orders ORDER BY order_status;

-- Distinct payment_method spellings
SELECT DISTINCT payment_method FROM payments ORDER BY payment_method;

-- ============================================================
-- SECTION 4: INVALID / UNUSUAL DATES
-- ============================================================
SELECT order_id, order_date
FROM orders
WHERE order_date > CURDATE() OR order_date < '2020-01-01';

-- ============================================================
-- SECTION 5: UNUSUAL PRICES
-- ============================================================
SELECT product_id, product_name, price
FROM products
WHERE price <= 0;

-- ============================================================
-- SECTION 6: UNUSUAL QUANTITIES
-- ============================================================
SELECT order_item_id, order_id, product_id, quantity
FROM order_items
WHERE quantity <= 0 OR quantity > 50;

-- ============================================================
-- SECTION 7: RELATIONSHIP CHECK - orders with no items
-- ============================================================
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_item_id IS NULL;

-- ============================================================
-- SECTION 8: DATA TYPE SANITY CHECK
-- ============================================================
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce_analytics'
ORDER BY TABLE_NAME, ORDINAL_POSITION;