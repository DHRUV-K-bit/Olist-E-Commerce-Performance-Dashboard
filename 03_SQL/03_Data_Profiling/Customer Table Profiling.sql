-- Step 3 — Data Profiling

-- Customer Table

-- 1. Row count
--    99441 
SELECT count(*) 
FROM customers;

-- 2. NULL / missing values

-- customer_id
-- Empty set (0.603 sec)
SELECT customer_id 
FROM customers
WHERE customer_id IS NULL;

-- customer_unique_id
-- Empty set (0.449 sec)
SELECT customer_unique_id
FROM customers
WHERE customer_unique_id IS NULL;

-- customer_zip_code_prefix
-- Empty set (0.424 sec)
SELECT customer_zip_code_prefix
FROM customers
WHERE customer_zip_code_prefix IS NULL;

-- customer_city
-- Empty set (0.456 sec)
SELECT customer_city
FROM customers
WHERE customer_city IS NULL;

-- customer_state
-- Empty set (0.444 sec)
SELECT customer_state
FROM customers
WHERE customer_state IS NULL;

-- 3. Duplicate customer_id
-- Empty set (2.431 sec)
SELECT 
	customer_id,
	COUNT(*) AS appearance_count
FROM customers 
GROUP BY customer_id
HAVING COUNT(*) > 1;
	
-- 4. Duplicate customer_unique_id 
-- 2997 rows in set (2.716 sec)
SELECT 
	customer_unique_id,
	COUNT(*) AS appearance_count
FROM customers 
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

-- 5. ZIP code check
-- MIN: 1003 | MAX: 99990
SELECT 
	MIN(customer_zip_code_prefix),
    MAX(customer_zip_code_prefix)
FROM customers;

-- Find any non-numeric/suspicious values
-- Empty set (0.850 sec)
SELECT customer_zip_code_prefix
FROM customers 
WHERE customer_zip_code_prefix NOT REGEXP '^[0-9]+$';

-- 6. State check
-- 27 rows in set (0.677 sec)
SELECT DISTINCT customer_state 
FROM customers;

-- Are they all 2-character codes?
-- 27 rows in set (0.733 sec)
SELECT DISTINCT customer_state
FROM customers
WHERE customer_state LIKE '__';

-- 7. City check
-- 4119 rows in set (0.902 sec)
SELECT DISTINCT customer_city 
FROM customers;

SELECT DISTINCT customer_city 
FROM customers
LIMIT 5;

-- 8. Relationship check — Customers → Orders
-- Empty set (0.503 sec)
SELECT DISTINCT o.customer_id
FROM orders o
	LEFT JOIN customers c ON
					o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
                    


    
