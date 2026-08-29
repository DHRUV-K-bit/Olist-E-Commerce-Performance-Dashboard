-- Step 3 — Data Profiling

-- Geolocation Table

-- 1. Row count
-- 1000163
SELECT COUNT(*) 
FROM geolocation;

-- 2. NULL values for all 5 columns

-- geolocation_zip_code_prefix
-- Empty set (8.912 sec)
SELECT geolocation_zip_code_prefix
FROM geolocation 
WHERE geolocation_zip_code_prefix IS NULL;

-- geolocation_lat
-- Empty set (8.227 sec)
SELECT geolocation_lat
FROM geolocation 
WHERE geolocation_lat IS NULL;

-- geolocation_lng
-- Empty set (5.248 sec)
SELECT geolocation_lng
FROM geolocation 
WHERE geolocation_lng IS NULL;

-- geolocation_city
-- Empty set (5.232 sec)
SELECT geolocation_city
FROM geolocation 
WHERE geolocation_city IS NULL;

-- geolocation_state
-- Empty set (5.297 sec)
SELECT geolocation_state
FROM geolocation 
WHERE geolocation_state IS NULL;

-- 3. Duplicate ZIP code prefixes
-- 17972 rows in set (11.737 sec)
SELECT 
	geolocation_zip_code_prefix,
    COUNT(*)
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1;

-- 4. Latitude range
-- MIN: -36.6053744107061 | MAX: 45.0659331826970 
SELECT
	MIN(geolocation_lat),
    MAX(geolocation_lat)
FROM geolocation;

-- 5. Longitude range
-- MIN: -99.9999999999999 | MAX: 99.9999999999999 
SELECT 
	MIN(geolocation_lng),
    MAX(geolocation_lng)
FROM geolocation;

-- 6. Suspicious latitude/longitude values

-- For latitude, valid values are: -90 to +90

-- For longitude: -180 to +180
-- Empty set (7.838 sec)
SELECT *
FROM geolocation
WHERE geolocation_lat < -90
   OR geolocation_lat > 90
   OR geolocation_lng < -180
   OR geolocation_lng > 180;

-- 7. State check
-- 27 rows in set (7.422 sec)
SELECT DISTINCT geolocation_state
FROM geolocation;

-- 27 
SELECT COUNT(DISTINCT geolocation_state)
FROM geolocation;

-- 8. Relationship / ZIP-code consistency

-- Comparing with sellers table
-- 2285
-- 37708
-- 7412
-- 82040
-- 72580
-- 71551
-- 91901
-- 7 rows in set (12.675 sec)
SELECT s.seller_zip_code_prefix
FROM sellers s
	LEFT JOIN geolocation g ON
								s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

-- Comparing with customers table

----------+
|                    41098 |
|                    41098 |
|                    41098 |
|                    38710 |
|                    62898 |
|                    64605 |
|                    72457 |
|                    56485 |
|                    29718 |
|                    72536 |
|                    72536 |
|                    72536 |
|                    64095 |
|                    39103 |
|                    73369 |
|                    71884 |
|                    71884 |
|                     7430 |
|                    71884 |
|                    73369 |
|                    87323 |
|                    71884 |
|                    71884 |
|                    73369 |
|                    73369 |
|                    73369 |
|                    72465 |
|                    64047 |
|                    72465 |
|                    72465 |
|                    72863 |
|                    59547 |
|                    37005 |
|                    76897 |
|                    36248 |
|                    85118 |
|                    85118 |
|                    56327 |
|                    93602 |
|                    72341 |
|                    72242 |
|                    72242 |
|                    59299 |
|                    28530 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    71919 |
|                    72583 |
|                    17390 |
|                    72583 |
|                    72583 |
|                    72583 |
|                    70701 |
|                    70701 |
|                    71591 |
|                    71591 |
|                    71698 |
|                    95853 |
|                    55863 |
|                    83843 |
|                    73091 |
|                    73081 |
|                    72455 |
|                    19740 |
|                    73081 |
|                    72023 |
|                    72023 |
|                    35104 |
|                    71971 |
|                    72440 |
|                     7784 |
|                    71593 |
|                    13307 |
|                    12770 |
|                    70316 |
|                    72243 |
|                    86135 |
|                     7729 |
|                    73401 |
|                    73401 |
|                    73401 |
|                    73401 |
|                    72867 |
|                    73401 |
|                    71208 |
|                    71953 |
|                    71810 |
|                    71810 |
|                    71810 |
|                    29196 |
|                    29196 |
|                    29949 |
|                    29949 |
|                    29949 |
|                    61906 |
|                    61906 |
|                    72595 |
|                    72595 |
|                    72595 |
|                    85894 |
|                    72595 |
|                    65137 |
|                    65137 |
|                    75257 |
|                    77404 |
|                    44135 |
|                    65137 |
|                     7412 |
|                    94370 |
|                    71905 |
|                    67105 |
|                    73310 |
|                    42716 |
|                     8342 |
|                    84623 |
|                    65830 |
|                    73391 |
|                    11547 |
|                    62625 |
|                    28575 |
|                    75784 |
|                    75784 |
|                    28120 |
|                    78554 |
|                     6930 |
|                    72238 |
|                    78554 |
|                    72238 |
|                    72549 |
|                    42843 |
|                    71975 |
|                    73255 |
|                    73255 |
|                    73255 |
|                    73255 |
|                    73255 |
|                    73255 |
|                    73255 |
|                    28160 |
|                    28160 |
|                    68629 |
|                    83210 |
|                    87511 |
|                    71590 |
|                    72535 |
|                    76968 |
|                    72002 |
|                    72002 |
|                    72002 |
|                    72002 |
|                    72002 |
|                    41347 |
|                    73082 |
|                    73082 |
|                    35242 |
|                    72821 |
|                    72821 |
|                    72821 |
|                    72268 |
|                    73093 |
|                    72268 |
|                    68511 |
|                    73402 |
|                    73402 |
|                    27980 |
|                    36956 |
|                    72017 |
|                    71995 |
|                    49870 |
|                    72017 |
|                    72017 |
|                    71995 |
|                    71995 |
|                    72338 |
|                    28388 |
|                     2140 |
|                    43870 |
|                    72904 |
|                    55027 |
|                    71993 |
|                    58734 |
|                    70716 |
|                    70716 |
|                    28617 |
|                    58286 |
|                    72300 |
|                    72300 |
|                    72300 |
|                    72300 |
|                    72300 |
|                    72300 |
|                    72596 |
|                    72596 |
|                    72596 |
|                    85958 |
|                    72596 |
|                    73090 |
|                    71996 |
|                    72237 |
|                    70702 |
|                    71996 |
|                    71976 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    72005 |
|                    73272 |
|                    72005 |
|                    28655 |
|                    28655 |
|                    86996 |
|                    25840 |
|                    70333 |
|                    57254 |
|                    25919 |
|                    25919 |
|                    73088 |
|                    12332 |
|                    36596 |
|                    72280 |
|                    72280 |
|                    72280 |
|                    72280 |
|                    71574 |
|                    71574 |
|                    71574 |
|                    72427 |
|                    95572 |
|                    71551 |
|                    71551 |
|                    71551 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    72760 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    70686 |
|                    38627 |
|                    71676 |
|                    72587 |
|                    71676 |
|                    71676 |
|                    71676 |
|                    72587 |
|                    35408 |
|                    70324 |
|                    70324 |
|                    71261 |
|                    36857 |
|                    71539 |
|                     8980 |
|                    48504 |
|                     8980 |
+--------------------------+
278 rows in set (19.853 sec)

SELECT c.customer_zip_code_prefix
FROM customers c
LEFT JOIN geolocation g ON
								c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

-- So for Geolocation, the main findings so far are:

17,972 ZIP prefixes have multiple geolocation records → expected; don't remove.
1 suspicious longitude value → flag.
13 unusually high latitude values → flag.
7 seller ZIP prefixes have no geolocation match → investigate during cleaning.
Customer ZIP matching needs separate investigation because your query returned many unmatched records.