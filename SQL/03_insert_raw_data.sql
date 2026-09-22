-- 03_insert_raw_data.sql
-- Auto-generates 500-600+ realistic, relational records
-- Intentionally includes NULLs, duplicates, inconsistent text, and unusual values

USE ecommerce_analytics;

-- ============================================================
-- CUSTOMERS (120 generated + 5 intentional duplicates = 125)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS generate_customers$$
CREATE PROCEDURE generate_customers()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE r INT;
    WHILE i <= 120 DO
        SET r = FLOOR(1 + RAND()*15);
        INSERT INTO customers (customer_name, email, phone, city, state, signup_date, customer_rating)
        VALUES (
            CONCAT(
                ELT(FLOOR(1+RAND()*20),'Aarav','Vivaan','Aditya','Vihaan','Arjun','Sai','Reyansh','Krishna','Ishaan','Kabir','Ananya','Diya','Saanvi','Aadhya','Kiara','Myra','Anika','Navya','Riya','Priya'),
                ' ',
                ELT(FLOOR(1+RAND()*15),'Sharma','Verma','Gupta','Patel','Reddy','Nair','Iyer','Singh','Kumar','Das','Mehta','Joshi','Rao','Chopra','Malhotra')
            ),
            CASE WHEN RAND() < 0.10 THEN NULL ELSE CONCAT('customer', i, '@example.com') END,
            CASE WHEN RAND() < 0.08 THEN NULL ELSE CONCAT('9', FLOOR(100000000 + RAND()*899999999)) END,
            ELT(r,'Mumbai','mumbai','Delhi','Bangalore','bangalore','BANGALORE','Hyderabad','Chennai','Kolkata','Pune','Ahmedabad','Jaipur','Lucknow','Surat','Nagpur'),
            ELT(r,'Maharashtra','Maharashtra','Delhi','Karnataka','Karnataka','Karnataka','Telangana','Tamil Nadu','West Bengal','Maharashtra','Gujarat','Rajasthan','Uttar Pradesh','Gujarat','Maharashtra'),
            DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND()*700) DAY),
            ROUND(1 + RAND()*4, 1)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_customers();
DROP PROCEDURE generate_customers;

-- Intentional duplicate customer records (data-quality issue for later cleaning)
INSERT INTO customers (customer_name, email, phone, city, state, signup_date, customer_rating)
SELECT customer_name, email, phone, city, state, signup_date, customer_rating
FROM customers ORDER BY RAND() LIMIT 5;


-- ============================================================
-- PRODUCTS (60 generated + 5 intentional duplicates = 65)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS generate_products$$
CREATE PROCEDURE generate_products()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 60 DO
        INSERT INTO products (product_name, category, price, cost_price)
        VALUES(
            ELT(FLOOR(1+RAND()*30),
                'Wireless Bluetooth Earbuds','Smartphone 128GB','LED Smart TV 43-inch','Men Cotton T-Shirt',
                'Women Kurti','Running Shoes','Non-Stick Frying Pan','Yoga Mat','Kids Building Blocks Set',
                'Basmati Rice 5kg','Face Wash 100ml','Study Table','Bluetooth Speaker','Laptop Backpack',
                'Wrist Watch','Office Chair','Hair Dryer','Water Bottle 1L','Notebook Set','Cricket Bat',
                'Denim Jeans','Microwave Oven','Ceiling Fan','Sofa Cover','Sunglasses','Wall Clock',
                'Pressure Cooker','School Bag','Formal Shirt','Sports Shoes'
            ),
            ELT(FLOOR(1+RAND()*13),
                'Electronics','electronics','ELECTRONICS','Clothing','clothing','Home & Kitchen',
                'home & kitchen','Books','Beauty','beauty','Sports','Toys','Grocery'
            ),
            CASE WHEN RAND() < 0.03 THEN 0 WHEN RAND() < 0.05 THEN -100 ELSE ROUND(100 + RAND()*9000,2) END,
            CASE WHEN RAND() < 0.10 THEN NULL ELSE ROUND(50 + RAND()*5000,2) END
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_products();
DROP PROCEDURE generate_products;

INSERT INTO products (product_name, category, price, cost_price)
SELECT product_name, category, price, cost_price
FROM products ORDER BY RAND() LIMIT 5;


-- ============================================================
-- ORDERS (300 records)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS generate_orders$$
CREATE PROCEDURE generate_orders()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE max_cust INT;
    SELECT MAX(customer_id) INTO max_cust FROM customers;
    WHILE i <= 300 DO
        INSERT INTO orders (customer_id, order_date, order_status)
        VALUES(
            FLOOR(1 + RAND()*max_cust),
            CASE WHEN RAND() < 0.02 THEN '2030-01-01'
                 WHEN RAND() < 0.02 THEN '2019-01-01'
                 ELSE DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND()*640) DAY) END,
            CASE WHEN RAND() < 0.05 THEN NULL
                 ELSE ELT(FLOOR(1+RAND()*8),'Delivered','delivered','DELIVERED','Pending','pending','Cancelled','cancelled','Shipped') END
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_orders();
DROP PROCEDURE generate_orders;


-- ============================================================
-- ORDER_ITEMS (550 records)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS generate_order_items$$
CREATE PROCEDURE generate_order_items()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE max_order INT;
    DECLARE max_prod INT;
    DECLARE pid INT;
    SELECT MAX(order_id) INTO max_order FROM orders;
    SELECT MAX(product_id) INTO max_prod FROM products;
    WHILE i <= 550 DO
        SET pid = FLOOR(1 + RAND()*max_prod);
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        SELECT
            FLOOR(1 + RAND()*max_order),
            pid,
            CASE WHEN RAND() < 0.03 THEN 0
                 WHEN RAND() < 0.02 THEN -2
                 WHEN RAND() < 0.02 THEN 500
                 ELSE FLOOR(1 + RAND()*5) END,
            CASE WHEN RAND() < 0.07 THEN NULL
                 ELSE (SELECT price FROM products WHERE product_id = pid) END;
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_order_items();
DROP PROCEDURE generate_order_items;


-- ============================================================
-- PAYMENTS (~280 records — a few orders left unpaid on purpose)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS generate_payments$$
CREATE PROCEDURE generate_payments()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE max_order INT;
    SELECT MAX(order_id) INTO max_order FROM orders;
    WHILE i <= max_order DO
        IF RAND() < 0.93 THEN
            INSERT INTO payments (order_id, payment_method, payment_status, payment_date, amount_paid)
            SELECT
                i,
                ELT(FLOOR(1+RAND()*8),'Credit Card','credit card','CREDIT CARD','UPI','upi','Debit Card','Net Banking','Cash on Delivery'),
                CASE WHEN RAND() < 0.05 THEN NULL ELSE ELT(FLOOR(1+RAND()*4),'Success','success','Failed','Pending') END,
                o.order_date,
                CASE WHEN RAND() < 0.06 THEN NULL ELSE ROUND(100 + RAND()*9000,2) END
            FROM orders o WHERE o.order_id = i;
        END IF;
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_payments();
DROP PROCEDURE generate_payments;

SELECT 'All raw data generated successfully' AS status;