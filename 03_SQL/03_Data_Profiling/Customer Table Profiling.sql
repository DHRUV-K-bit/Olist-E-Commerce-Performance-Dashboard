-- Step 3 — Data Profiling

-- Customers Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM customers;


-- 2. NULL values

SELECT
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(customer_unique_id IS NULL) AS null_customer_unique_id,
    SUM(customer_zip_code_prefix IS NULL) AS null_zip_code,
    SUM(customer_city IS NULL) AS null_city,
    SUM(customer_state IS NULL) AS null_state
FROM customers;


-- 3. Duplicate customer_id

SELECT
    customer_id,
    COUNT(*) AS appearance_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 4. Repeated customer_unique_id

-- A customer_unique_id can appear across multiple customer_id records.
SELECT
    customer_unique_id,
    COUNT(*) AS customer_id_count
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY customer_id_count DESC;


-- 5. ZIP code range

SELECT
    MIN(customer_zip_code_prefix) AS min_zip_code,
    MAX(customer_zip_code_prefix) AS max_zip_code
FROM customers;


-- Check for non-numeric ZIP codes

SELECT customer_zip_code_prefix
FROM customers
WHERE customer_zip_code_prefix NOT REGEXP '^[0-9]+$';


-- 6. State check

SELECT DISTINCT customer_state
FROM customers
ORDER BY customer_state;

SELECT COUNT(DISTINCT customer_state) AS state_count
FROM customers;


-- 7. City check

SELECT COUNT(DISTINCT customer_city) AS city_count
FROM customers;

SELECT DISTINCT customer_city
FROM customers
LIMIT 5;


-- 8. Relationship: Customers → Orders

SELECT DISTINCT o.customer_id
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;