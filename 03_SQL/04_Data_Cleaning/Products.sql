-- Step 4 — Data Cleaning

-- Products Table

USE olist_bi;


-- 1. Check products with invalid physical measurements

SELECT *
FROM products
WHERE product_weight_g <= 0
   OR product_length_cm <= 0
   OR product_height_cm <= 0
   OR product_width_cm <= 0;


-- 2. Check the completely blank product record

SELECT *
FROM products
WHERE product_category_name IS NULL
  AND product_name_length = 0
  AND product_description_length = 0
  AND product_photos_qty = 0
  AND product_weight_g = 0
  AND product_length_cm = 0
  AND product_height_cm = 0
  AND product_width_cm = 0;


-- 3. Check whether the affected products are used in orders

SELECT
    p.product_id,
    COUNT(oi.order_id) AS order_item_rows,
    COUNT(DISTINCT oi.order_id) AS distinct_orders
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_weight_g = 0
   OR p.product_length_cm = 0
   OR p.product_height_cm = 0
   OR p.product_width_cm = 0
GROUP BY p.product_id
ORDER BY p.product_id;


-- 4. Check product_id uniqueness

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM products;


-- 5. Clean invalid physical measurements

-- Zero values represent unavailable measurements, so store them as NULL.
UPDATE products
SET
    product_weight_g = NULLIF(product_weight_g, 0),
    product_length_cm = NULLIF(product_length_cm, 0),
    product_height_cm = NULLIF(product_height_cm, 0),
    product_width_cm = NULLIF(product_width_cm, 0)
WHERE product_weight_g = 0
   OR product_length_cm = 0
   OR product_height_cm = 0
   OR product_width_cm = 0;


-- 6. Clean the completely blank product record

-- The product is used in orders, so we retain it.
-- Unknown product attributes are represented as NULL.
UPDATE products
SET
    product_category_name = NULL,
    product_name_length = NULL,
    product_description_length = NULL,
    product_photos_qty = NULL
WHERE product_id = '5eb564652db742ff8f28759cd8d2652a';


-- 7. Verify the cleaned records

SELECT
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products
WHERE product_id = '5eb564652db742ff8f28759cd8d2652a';


-- 8. Check for remaining zero physical measurements

SELECT COUNT(*) AS remaining_zero_measurements
FROM products
WHERE product_weight_g = 0
   OR product_length_cm = 0
   OR product_height_cm = 0
   OR product_width_cm = 0;