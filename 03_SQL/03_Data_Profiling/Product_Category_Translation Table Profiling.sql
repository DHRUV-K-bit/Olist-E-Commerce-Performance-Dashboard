-- Step 3 — Data Profiling

-- Product_Category_Translation Table

-- 1. Row count
-- 71
SELECT COUNT(*)
FROM product_category_translation;

-- 2. NULL values

-- product_category_name
-- Empty set (0.014 sec)
SELECT product_category_name
FROM product_category_translation
WHERE product_category_name IS NULL;

-- product_category_name_english
-- Empty set (0.010 sec)
SELECT product_category_name_english
FROM product_category_translation
WHERE product_category_name_english IS NULL;

-- 3. Duplicate Portuguese category
-- Empty set (0.021 sec)
SELECT 
	product_category_name,
    COUNT(*)
FROM product_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- 4. Duplicate English category
-- Empty set (0.009 sec)
SELECT
		product_category_name_english,
        COUNT(*)
FROM product_category_translation
GROUP BY product_category_name_english
HAVING COUNT(*) > 1;

-- 5. Translation coverage
-- 3 rows in set (0.372 sec)
SELECT 
	DISTINCT p.product_category_name, 
    pct.product_category_name
FROM products p
LEFT JOIN product_category_translation pct 
    ON p.product_category_name = pct.product_category_name
WHERE pct.product_category_name IS NULL;

-- 6. Reverse relationship
-- Empty set (3.826 sec)
SELECT 
	DISTINCT pct.product_category_name,
    p.product_category_name
FROM product_category_translation pct 
LEFT JOIN products p
    ON pct.product_category_name = p.product_category_name
WHERE p.product_category_name IS NULL;
   
   
-- 3 product categories in products that don't have a translation.
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE pct.product_category_name IS NULL;

-- What does this mean?

-- This is not a reason to delete those products.

-- During cleaning/ETL, we'll handle them appropriately—most likely:

Blank category → treat as Unknown/Uncategorized
pc_gamer → keep the Portuguese category and handle the English category as Unknown/Untranslated
portateis_cozinha_e_preparadores_de_alimentos → same idea

-- And importantly, we don't invent translations ourselves in the raw/staging layer.

-- So the final profiling conclusion for this table is:

-- 71 translation records, no NULLs or duplicates, but 3 product categories lack a translation. These will be handled during the transformation stage.

-- ✅ Product Category Translation profiling complete.
