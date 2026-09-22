-- 06_analytics.sql
-- Business analysis queries built on clean_ tables
USE ecommerce_analytics;

-- ============================================================
-- 1. TOTAL REVENUE
-- ============================================================
SELECT ROUND(SUM(revenue), 2) AS total_revenue
FROM clean_order_items;

-- ============================================================
-- 2. TOTAL PROFIT
-- ============================================================
SELECT ROUND(SUM(profit), 2) AS total_profit
FROM clean_order_items;

-- ============================================================
-- 3. TOTAL ORDERS
-- ============================================================
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM clean_orders;

-- ============================================================
-- 4. TOTAL CUSTOMERS
-- ============================================================
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM clean_customers;

-- ============================================================
-- 5. AVERAGE ORDER VALUE
-- ============================================================
SELECT ROUND(SUM(oi.revenue) / COUNT(DISTINCT oi.order_id), 2) AS avg_order_value
FROM clean_order_items oi;

-- ============================================================
-- 6. MONTHLY REVENUE
-- ============================================================
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    ROUND(SUM(oi.revenue), 2) AS monthly_revenue
FROM clean_orders o
JOIN clean_order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- ============================================================
-- 7. MONTHLY PROFIT
-- ============================================================
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    ROUND(SUM(oi.profit), 2) AS monthly_profit
FROM clean_orders o
JOIN clean_order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- ============================================================
-- 8. DAILY SALES
-- ============================================================
SELECT
    o.order_date,
    ROUND(SUM(oi.revenue), 2) AS daily_revenue
FROM clean_orders o
JOIN clean_order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_date
ORDER BY o.order_date;

-- ============================================================
-- 9. SALES BY CATEGORY
-- ============================================================
SELECT
    p.category,
    ROUND(SUM(oi.revenue), 2) AS category_revenue,
    ROUND(SUM(oi.profit), 2) AS category_profit
FROM clean_order_items oi
JOIN clean_products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- ============================================================
-- 10. SALES BY PRODUCT
-- ============================================================
SELECT
    p.product_name,
    ROUND(SUM(oi.revenue), 2) AS product_revenue,
    SUM(oi.quantity) AS total_quantity_sold
FROM clean_order_items oi
JOIN clean_products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY product_revenue DESC;

-- ============================================================
-- 11. SALES BY CITY
-- ============================================================
SELECT
    c.city,
    ROUND(SUM(oi.revenue), 2) AS city_revenue
FROM clean_order_items oi
JOIN clean_orders o ON oi.order_id = o.order_id
JOIN clean_customers c ON o.customer_id = c.customer_id
GROUP BY c.city
ORDER BY city_revenue DESC;

-- ============================================================
-- 12. SALES BY STATE
-- ============================================================
SELECT
    c.state,
    ROUND(SUM(oi.revenue), 2) AS state_revenue
FROM clean_order_items oi
JOIN clean_orders o ON oi.order_id = o.order_id
JOIN clean_customers c ON o.customer_id = c.customer_id
GROUP BY c.state
ORDER BY state_revenue DESC;

-- ============================================================
-- 13. TOP 10 PRODUCTS (BY REVENUE)
-- ============================================================
SELECT
    p.product_name,
    ROUND(SUM(oi.revenue), 2) AS total_revenue
FROM clean_order_items oi
JOIN clean_products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================
-- 14. TOP 10 CUSTOMERS (BY SPEND)
-- ============================================================
SELECT
    c.customer_name,
    c.city,
    ROUND(SUM(oi.revenue), 2) AS total_spent
FROM clean_order_items oi
JOIN clean_orders o ON oi.order_id = o.order_id
JOIN clean_customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_spent DESC
LIMIT 10;

-- ============================================================
-- 15. PAYMENT METHOD ANALYSIS
-- ============================================================
SELECT
    payment_method,
    COUNT(*) AS num_payments,
    ROUND(SUM(amount_paid), 2) AS total_collected
FROM clean_payments
GROUP BY payment_method
ORDER BY total_collected DESC;

-- ============================================================
-- 16. REPEAT CUSTOMERS (customers with more than 1 order)
-- ============================================================
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT customer_id
    FROM clean_orders
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) r;

-- ============================================================
-- 17. CUSTOMER SEGMENTATION (High / Medium / Low spenders)
-- ============================================================
SELECT
    CASE
        WHEN total_spent >= 10000 THEN 'High Value'
        WHEN total_spent >= 3000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment,
    COUNT(*) AS num_customers
FROM (
    SELECT c.customer_id, SUM(oi.revenue) AS total_spent
    FROM clean_customers c
    JOIN clean_orders o ON c.customer_id = o.customer_id
    JOIN clean_order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id
) spend
GROUP BY customer_segment
ORDER BY num_customers DESC;

-- ============================================================
-- 18. PROFIT MARGIN % (overall)
-- ============================================================
SELECT
    ROUND(SUM(profit) / SUM(revenue) * 100, 2) AS profit_margin_percent
FROM clean_order_items;

-- ============================================================
-- 19. MONTH-OVER-MONTH REVENUE GROWTH %
-- ============================================================
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.revenue) AS revenue
    FROM clean_orders o
    JOIN clean_order_items oi ON o.order_id = oi.order_id
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100
    , 2) AS mom_growth_percent
FROM monthly
ORDER BY month;

-- ============================================================
-- 20. BEST / WORST PERFORMING CATEGORIES (by profit margin)
-- ============================================================
SELECT
    p.category,
    ROUND(SUM(oi.revenue), 2) AS revenue,
    ROUND(SUM(oi.profit), 2) AS profit,
    ROUND(SUM(oi.profit) / SUM(oi.revenue) * 100, 2) AS profit_margin_percent
FROM clean_order_items oi
JOIN clean_products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY profit_margin_percent DESC;

-- ============================================================
-- 21. ORDER STATUS ANALYSIS
-- ============================================================
SELECT
    order_status,
    COUNT(*) AS num_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clean_orders), 2) AS percent_of_total
FROM clean_orders
GROUP BY order_status
ORDER BY num_orders DESC;