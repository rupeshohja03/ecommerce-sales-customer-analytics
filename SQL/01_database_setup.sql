-- 01_database_setup.sql
-- Creates the database and selects it for use

DROP DATABASE IF EXISTS ecommerce_analytics;
CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

SELECT 'Database created successfully' AS status;