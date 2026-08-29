-- Step 3 — Data Profiling

-- Product Category Translation Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM product_category_translation;


-- 2. NULL values

SELECT
    SUM(product_category_name IS NULL) AS null_portuguese_category,
    SUM(product_category_name_english IS NULL) AS null_english_category
FROM product_category_translation;


-- 3. Duplicate Portuguese categories

SELECT
    product_category_name,
    COUNT(*) AS appearance_count
FROM product_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;


-- 4. Duplicate English categories

SELECT
    product_category_name_english,
    COUNT(*) AS appearance_count
FROM product_category_translation
GROUP BY product_category_name_english
HAVING COUNT(*) > 1;


-- 5. Product categories without a translation

SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE pct.product_category_name IS NULL
ORDER BY p.product_category_name;


-- 6. Translation records without a matching product category

SELECT DISTINCT pct.product_category_name
FROM product_category_translation pct
LEFT JOIN products p
    ON pct.product_category_name = p.product_category_name
WHERE p.product_category_name IS NULL;