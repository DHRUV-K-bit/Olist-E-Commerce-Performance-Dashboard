-- Step 3 — Data Profiling

-- Sellers Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM sellers;


-- 2. NULL values

SELECT
    SUM(seller_id IS NULL) AS null_seller_id,
    SUM(seller_zip_code_prefix IS NULL) AS null_zip_code,
    SUM(seller_city IS NULL) AS null_city,
    SUM(seller_state IS NULL) AS null_state
FROM sellers;


-- 3. Duplicate seller_id

SELECT
    seller_id,
    COUNT(*) AS appearance_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- 4. ZIP code range

SELECT
    MIN(seller_zip_code_prefix) AS min_zip_code,
    MAX(seller_zip_code_prefix) AS max_zip_code
FROM sellers;


-- Check for non-numeric ZIP codes

SELECT seller_zip_code_prefix
FROM sellers
WHERE seller_zip_code_prefix NOT REGEXP '^[0-9]+$';


-- 5. State check

SELECT DISTINCT seller_state
FROM sellers
ORDER BY seller_state;

SELECT COUNT(DISTINCT seller_state) AS state_count
FROM sellers;


-- 6. City check

SELECT COUNT(DISTINCT seller_city) AS city_count
FROM sellers;

SELECT DISTINCT seller_city
FROM sellers
LIMIT 5;


-- 7. Relationship: Sellers → Order Items

SELECT DISTINCT ot.seller_id
FROM order_items ot
LEFT JOIN sellers s
    ON ot.seller_id = s.seller_id
WHERE s.seller_id IS NULL;