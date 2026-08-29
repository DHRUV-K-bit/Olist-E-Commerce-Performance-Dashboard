-- Step 3 — Data Profiling

-- Products Table

-- 1. Row count
-- 32951
SELECT COUNT(*)
FROM products;

-- 2. NULL values

-- product_id
SELECT product_id
FROM products
WHERE product_id IS NULL;

-- product_category_name
-- Empty set (0.144 sec)
SELECT product_category_name
FROM products
WHERE product_category_name IS NULL;

-- product_name_length
-- Empty set (0.131 sec)
SELECT product_name_length
FROM products
WHERE product_name_length IS NULL;

-- product_description_length
-- Empty set (0.135 sec)
SELECT product_description_length
FROM products
WHERE product_description_length IS NULL;

-- product_photos_qty
-- Empty set (0.140 sec)
SELECT product_photos_qty
FROM products
WHERE product_photos_qty IS NULL;

-- product_weight_g
-- Empty set (0.134 sec)
SELECT product_weight_g
FROM products
WHERE product_weight_g IS NULL;

-- product_length_cm
-- Empty set (0.148 sec)
SELECT product_length_cm
FROM products
WHERE product_length_cm IS NULL;

-- product_height_cm
-- Empty set (0.132 sec)
SELECT product_height_cm
FROM products
WHERE product_height_cm IS NULL;

-- product_width_cm
-- Empty set (0.134 sec)
SELECT product_width_cm
FROM products
WHERE product_width_cm IS NULL;

-- 3. Duplicate product_id
-- Empty set (0.791 sec)
SELECT COUNT(product_id)
FROM products
GROUP BY product_id
HAVING COUNT(product_id) > 1;

-- 4. Category

-- How many distinct product_category_name values?
-- 74 rows in set (0.251 sec)
SELECT DISTINCT product_category_name
FROM products;

-- Also check whether the category itself has NULLs.
-- Empty set (0.143 sec)
SELECT product_category_name
FROM products
WHERE product_category_name IS NULL; -- did this already

-- 5. Numeric ranges

-- product_name_length  -- MIN: 0 | MAX: 76
SELECT 
	MIN(product_name_length),
    MAX(product_name_length)
FROM products;

-- product_description_length  -- MIN: 0 | MAX: 3992
SELECT 
	MIN(product_description_length),
    MAX(product_description_length)
FROM products;

-- product_photos_qty  -- MIN: 0 | MAX: 20
SELECT 
	MIN(product_photos_qty),
    MAX(product_photos_qty)
FROM products;

-- product_weight_g  -- MIN: 0 | MAX: 40425
SELECT 
	MIN(product_weight_g),
    MAX(product_weight_g)
FROM products;

-- product_length_cm  -- MIN: 0 | MAX: 105
SELECT 
	MIN(product_length_cm),
    MAX(product_length_cm)
FROM products;

-- product_height_cm  -- MIN: 0 | MAX: 105
SELECT 
	MIN(product_height_cm),
    MAX(product_height_cm)
FROM products;

-- product_width_cm  -- MIN: 0 | MAX: 118
SELECT 
	MIN(product_width_cm),
    MAX(product_width_cm)
FROM products;

-- 6. Suspicious numeric values
-- Empty set (0.298 sec)
SELECT *
FROM products
WHERE product_name_length < 0
   OR product_description_length < 0
   OR product_photos_qty < 0
   OR product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- 7. Relationship: Products → Order Items
-- Empty set (2.815 sec)
SELECT DISTINCT ot.product_id
FROM order_items ot
	LEFT JOIN products p ON
							ot.product_id = p.product_id
WHERE p.product_id IS NULL;


SELECT
    SUM(product_name_length = 0) AS zero_name_length,
    SUM(product_description_length = 0) AS zero_description_length,
    SUM(product_photos_qty = 0) AS zero_photos,
    SUM(product_weight_g = 0) AS zero_weight,
    SUM(product_length_cm = 0) AS zero_length,
    SUM(product_height_cm = 0) AS zero_height,
    SUM(product_width_cm = 0) AS zero_width
FROM products;

-- What do we do next?

-- We investigate the suspicious zeros, specifically the:

6 products with weight = 0
2 products with length = 0
2 products with height = 0
2 products with width = 0

-- We want to see the actual records before deciding whether they're errors.

1. Investigate the 6 zero-weight products

Run:

SELECT *
FROM products
WHERE product_weight_g = 0;

This shows us the actual product IDs, categories, dimensions, etc.

2. Investigate the 2 zero-length products
SELECT *
FROM products
WHERE product_length_cm = 0;
3. Zero-height products
SELECT *
FROM products
WHERE product_height_cm = 0;
4. Zero-width products
SELECT *
FROM products
WHERE product_width_cm = 0;

1. Product 09ff...

This one has:

Weight = 0
Length = 0
Height = 0
Width = 0

But it does have a category, name, description, and photos.

So the physical measurements are missing/unknown, represented by 0. We should not invent values for them.

2. Product 5eb5...

This one has everything missing/zero:

Category → blank
Name length → 0
Description length → 0
Photos → 0
Weight → 0
Length → 0
Height → 0
Width → 0

This is clearly a product record with essentially no product information.

3. The other 4 zero-weight products

These have:

Weight = 0
Dimensions = 30 × 25 × 30

So again, the weight is missing/unknown, but dimensions are available.

What should we do?

Do not delete these rows. Do not replace the zeros with guesses.

For this project, I'd treat the 0 measurements as missing/unavailable data and leave them for now. This is especially important because these products may still appear in order_items, so deleting them could break relationships.

So our profiling conclusion is:

6 products have zero weight, and 2 have zero dimensions. These appear to represent missing product measurements rather than valid physical values. No replacement values will be invented.

✅ Products profiling is now complete.