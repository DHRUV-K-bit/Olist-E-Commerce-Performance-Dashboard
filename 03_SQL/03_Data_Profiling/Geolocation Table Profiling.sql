-- Step 3 — Data Profiling

-- Geolocation Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM geolocation;


-- 2. NULL values

SELECT
    SUM(geolocation_zip_code_prefix IS NULL) AS null_zip_code,
    SUM(geolocation_lat IS NULL) AS null_latitude,
    SUM(geolocation_lng IS NULL) AS null_longitude,
    SUM(geolocation_city IS NULL) AS null_city,
    SUM(geolocation_state IS NULL) AS null_state
FROM geolocation;


-- 3. Duplicate ZIP code prefixes

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS appearance_count
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY appearance_count DESC;


-- 4. Latitude and longitude ranges

SELECT
    MIN(geolocation_lat) AS min_latitude,
    MAX(geolocation_lat) AS max_latitude,
    MIN(geolocation_lng) AS min_longitude,
    MAX(geolocation_lng) AS max_longitude
FROM geolocation;


-- 5. Invalid latitude/longitude values

SELECT *
FROM geolocation
WHERE geolocation_lat < -90
   OR geolocation_lat > 90
   OR geolocation_lng < -180
   OR geolocation_lng > 180;


-- 6. State check

SELECT DISTINCT geolocation_state
FROM geolocation
ORDER BY geolocation_state;

SELECT COUNT(DISTINCT geolocation_state) AS state_count
FROM geolocation;


-- 7. ZIP code match with Sellers

SELECT COUNT(DISTINCT s.seller_zip_code_prefix) AS unmatched_seller_zip_codes
FROM sellers s
LEFT JOIN geolocation g
    ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;


-- 8. ZIP code match with Customers

SELECT COUNT(DISTINCT c.customer_zip_code_prefix) AS unmatched_customer_zip_codes
FROM customers c
LEFT JOIN geolocation g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;