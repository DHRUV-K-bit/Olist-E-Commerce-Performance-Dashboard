-- Step 3 — Data Profiling

-- Products Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM products;


-- 2. NULL values

SELECT
    SUM(product_id IS NULL) AS null_product_id,
    SUM(product_category_name IS NULL) AS null_category,
    SUM(product_name_length IS NULL) AS null_name_length,
    SUM(product_description_length IS NULL) AS null_description_length,
    SUM(product_photos_qty IS NULL) AS null_photos_qty,
    SUM(product_weight_g IS NULL) AS null_weight,
    SUM(product_length_cm IS NULL) AS null_length,
    SUM(product_height_cm IS NULL) AS null_height,
    SUM(product_width_cm IS NULL) AS null_width
FROM products;


-- 3. Duplicate product_id

SELECT
    product_id,
    COUNT(*) AS appearance_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- 4. Product categories

SELECT DISTINCT product_category_name
FROM products
ORDER BY product_category_name;

SELECT COUNT(DISTINCT product_category_name) AS category_count
FROM products;


-- 5. Numeric ranges

SELECT
    MIN(product_name_length) AS min_name_length,
    MAX(product_name_length) AS max_name_length,
    MIN(product_description_length) AS min_description_length,
    MAX(product_description_length) AS max_description_length,
    MIN(product_photos_qty) AS min_photos_qty,
    MAX(product_photos_qty) AS max_photos_qty,
    MIN(product_weight_g) AS min_weight_g,
    MAX(product_weight_g) AS max_weight_g,
    MIN(product_length_cm) AS min_length_cm,
    MAX(product_length_cm) AS max_length_cm,
    MIN(product_height_cm) AS min_height_cm,
    MAX(product_height_cm) AS max_height_cm,
    MIN(product_width_cm) AS min_width_cm,
    MAX(product_width_cm) AS max_width_cm
FROM products;


-- 6. Negative values

SELECT *
FROM products
WHERE product_name_length < 0
   OR product_description_length < 0
   OR product_photos_qty < 0
   OR product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;


-- 7. Zero values

SELECT
    SUM(product_name_length = 0) AS zero_name_length,
    SUM(product_description_length = 0) AS zero_description_length,
    SUM(product_photos_qty = 0) AS zero_photos,
    SUM(product_weight_g = 0) AS zero_weight,
    SUM(product_length_cm = 0) AS zero_length,
    SUM(product_height_cm = 0) AS zero_height,
    SUM(product_width_cm = 0) AS zero_width
FROM products;


-- Investigate zero physical measurements

SELECT *
FROM products
WHERE product_weight_g = 0
   OR product_length_cm = 0
   OR product_height_cm = 0
   OR product_width_cm = 0;


-- 8. Relationship: Products → Order Items

SELECT DISTINCT ot.product_id
FROM order_items ot
LEFT JOIN products p
    ON ot.product_id = p.product_id
WHERE p.product_id IS NULL;