-- Step 3 — Data Profiling

-- Sellers Table

-- 1. Row count
-- 3095 
	SELECT COUNT(*) 
	FROM sellers;
    
-- 2. NULL values

-- seller_id
-- Empty set (0.023 sec)
SELECT seller_id
FROM sellers 
WHERE seller_id IS NULL;

-- seller_zip_code_prefix
-- Empty set (0.018 sec)
SELECT seller_zip_code_prefix
FROM sellers 
WHERE seller_zip_code_prefix IS NULL;

-- seller_city
-- Empty set (0.017 sec)
SELECT seller_city
FROM sellers 
WHERE seller_city IS NULL;

-- seller_state
-- Empty set (0.019 sec)
SELECT seller_state
FROM sellers 
WHERE seller_state IS NULL;

-- 3. Duplicate seller_id
-- Empty set (0.058 sec)
SELECT 
	seller_id,
	COUNT(*)
FROM sellers
GROUP BY seller_id
HAVING COUNT(seller_id) > 1;

-- 4. ZIP code
-- MIN: 1001 | MAX: 99730
SELECT
	MIN(seller_zip_code_prefix),
    MAX(seller_zip_code_prefix)
FROM sellers;

-- Check for suspicious/non-numeric values.
-- Empty set (0.031 sec)
SELECT seller_zip_code_prefix
FROM sellers
WHERE seller_zip_code_prefix NOT REGEXP '^[0-9]+$';

-- 5. State
-- 23 rows in set (20.436 sec)
SELECT DISTINCT seller_state
FROM sellers;

-- Check whether they're all 2-character codes.
-- 23 rows in set (0.027 sec)
SELECT DISTINCT seller_state
FROM sellers
WHERE seller_state LIKE '__';

-- 6. City
-- 610
SELECT COUNT(DISTINCT seller_city)
FROM sellers;

-- Small Smaple
-- 5 rows in set (
SELECT DISTINCT seller_city
FROM sellers
LIMIT 5;

-- 7. Relationship: Sellers → Order Items
-- Empty set (2.852 sec)
SELECT DISTINCT ot.seller_id
FROM order_items ot
	LEFT JOIN sellers s ON
							ot.seller_id = s.seller_id
WHERE s.seller_id IS NULL;