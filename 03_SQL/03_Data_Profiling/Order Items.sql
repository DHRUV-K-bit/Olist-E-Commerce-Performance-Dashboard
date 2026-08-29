-- Step 3 — Data Profiling

-- Order Items Table

-- 1. Row count
-- 112650 
SELECT count(*) 
FROM order_items;

-- 2. NULL / missing values

-- order_id
-- Empty set (0.689 sec)
SELECT order_id 
FROM order_items
WHERE order_id IS NULL;

-- order_item_id
-- Empty set (0.447 sec)
SELECT order_item_id 
FROM order_items
WHERE order_item_id IS NULL;

-- product_id
-- Empty set (0.432 sec)
SELECT product_id 
FROM order_items
WHERE product_id IS NULL;

-- seller_id
-- Empty set (0.454 sec)
SELECT seller_id 
FROM order_items
WHERE seller_id IS NULL;

-- shipping_limit_date
-- Empty set (0.729 sec)
SELECT shipping_limit_date 
FROM order_items
WHERE shipping_limit_date IS NULL;

-- price
-- Empty set (0.692 sec)
SELECT price 
FROM order_items
WHERE price IS NULL;

-- freight_value
-- Empty set (0.579 sec)
SELECT freight_value 
FROM order_items
WHERE freight_value IS NULL;

-- 3. Duplicate (order_id, order_item_id) combination
-- Empty set (3.057 sec)
SELECT 
	order_id,
    order_item_id,
	COUNT(*) AS appearance_count
FROM order_items 
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
	
-- 4. Price range
-- MIN: 0.85 | MAX: 6735.00 
SELECT 
	MIN(price),
	MAX(price)
FROM order_items;

-- 5. Freight value range
-- MIN:  0.00 | MAX: 409.68
SELECT 
	MIN(freight_value),
    MAX(freight_value)
FROM order_items;

-- 6. Suspicious zero/negative values
-- 383 rows in set (0.889 sec)
SELECT 
	price,
    freight_value
FROM order_items 
WHERE price <= 0 OR  freight_value <= 0;

-- 7. Shipping date validity

-- Late Shipping
-- 10564 rows in set (4.737 sec)
SELECT 
	o.order_delivered_carrier_date,
    ot.shipping_limit_date
FROM order_items ot 
	JOIN orders o ON
						o.order_id = ot.order_id
WHERE o.order_delivered_carrier_date >= ot.shipping_limit_date;

-- 8. Relationship → Orders
-- Empty set (4.718 sec)
SELECT DISTINCT ot.order_id
FROM order_items ot 
	LEFT JOIN orders o ON
					o.order_id = ot.order_id 
WHERE o.order_id IS NULL;

-- 9. Relationship → Products
-- Empty set (3.239 sec)
SELECT DISTINCT ot.product_id
FROM order_items ot 
	LEFT JOIN products p ON
					p.product_id = ot.product_id
WHERE p.product_id IS NULL;

-- 10. Relationship → Sellers
-- Empty set (1.636 sec)
SELECT DISTINCT ot.seller_id
FROM order_items ot 
	LEFT JOIN sellers s ON
					s.seller_id = ot.seller_id
WHERE s.seller_id IS NULL;




SELECT
    SUM(price <= 0) AS zero_or_negative_price,
    SUM(freight_value <= 0) AS zero_or_negative_freight
FROM order_items;


Next: investigate the 383 zero-freight rows

Run:
SELECT *
FROM order_items
WHERE freight_value = 0;

For your data-profiling stage, record it as:

Freight Value: 383 rows have freight_value = 0. These are treated as potentially valid zero-shipping-cost records rather than missing values, 
												so no correction is applied at this stage.


Next check

-- Let's see whether the zero freight is concentrated among particular sellers/products. Run:
                                                
SELECT
    seller_id,
    COUNT(*) AS zero_freight_rows
FROM order_items
WHERE freight_value = 0
GROUP BY seller_id
ORDER BY zero_freight_rows DESC;

What I would record in your profiling notes

Zero Freight Values: 383 order-item records have freight_value = 0. 
The zero values are concentrated among a small number of sellers, with the top four sellers accounting for approximately 96.3% of these records. 
Since the values are consistently associated with specific sellers and are not NULL, they are retained as valid observations rather than treated as missing data.



Run this next:

SELECT
    seller_id,
    COUNT(*) AS total_items,
    SUM(freight_value = 0) AS zero_freight_items,
    ROUND(SUM(freight_value = 0) * 100.0 / COUNT(*), 2) AS zero_freight_percentage
FROM order_items
GROUP BY seller_id
HAVING SUM(freight_value = 0) > 0
ORDER BY zero_freight_percentage DESC;

This tells us what percentage of each seller's order items have zero freight.





Good. This confirms the zero-freight values are not a general problem across sellers.

Seller 7d13...0964: 27.34% zero freight — relatively high.
Seller 955f...0e60: 6.60%
Seller 4869...52b2: 4.84%
The remaining sellers are ≤ 4.55%.
Overall, only 9 sellers have any zero-freight records.
Conclusion for profiling

We'll keep all 383 zero-freight records. There isn't enough evidence to call them errors or missing values.

Now let's move to #7 — shipping dates.

You found 10,564 records where:

carrier_date >= shipping_limit_date

But we need to separate exactly on the deadline from actually late.

Run:

SELECT
    SUM(o.order_delivered_carrier_date > ot.shipping_limit_date) AS actually_late,
    SUM(o.order_delivered_carrier_date = ot.shipping_limit_date) AS exactly_on_deadline
FROM order_items ot
JOIN orders o
    ON o.order_id = ot.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL;

Then we'll know the real number of late shipments.




Perfect. Now we have the actual number of late shipments:

10,423 → 🚨 actually late
141 → 🟡 exactly on the shipping deadline
Total = 10,564, matching your previous result.
Profiling conclusion

For our project, we'll define:

Late shipment = order_delivered_carrier_date > shipping_limit_date

So 10,423 order items were shipped after their allowed shipping deadline.

The 141 exactly-on-deadline items are not late.

One important point

These are not necessarily data errors.

A seller shipping late is a business/logistics event, and it's actually valuable for your dashboard because one of your requirements is Logistics & Operations → Late deliveries.

So:

Don't clean/delete these 10,423 rows.
We'll preserve them and later use them to calculate late-shipment rate / seller delivery performance.

✅ Order Items profiling is basically done.