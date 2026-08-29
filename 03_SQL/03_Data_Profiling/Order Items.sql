-- Step 3 — Data Profiling

-- Order Items Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM order_items;


-- 2. NULL values

SELECT
    SUM(order_id IS NULL) AS null_order_id,
    SUM(order_item_id IS NULL) AS null_order_item_id,
    SUM(product_id IS NULL) AS null_product_id,
    SUM(seller_id IS NULL) AS null_seller_id,
    SUM(shipping_limit_date IS NULL) AS null_shipping_limit,
    SUM(price IS NULL) AS null_price,
    SUM(freight_value IS NULL) AS null_freight
FROM order_items;


-- 3. Duplicate order item

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS appearance_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


-- 4. Price and freight ranges

SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight
FROM order_items;


-- 5. Zero or negative values

SELECT
    SUM(price <= 0) AS zero_or_negative_price,
    SUM(freight_value < 0) AS negative_freight
FROM order_items;


-- Zero freight values

SELECT COUNT(*) AS zero_freight_items
FROM order_items
WHERE freight_value = 0;


-- 6. Shipping deadline

-- Items shipped after the allowed shipping date
SELECT COUNT(*) AS late_shipments
FROM order_items ot
JOIN orders o
    ON o.order_id = ot.order_id
WHERE o.order_delivered_carrier_date > ot.shipping_limit_date;


-- Items shipped exactly on the deadline
SELECT COUNT(*) AS on_deadline_shipments
FROM order_items ot
JOIN orders o
    ON o.order_id = ot.order_id
WHERE o.order_delivered_carrier_date = ot.shipping_limit_date;


-- 7. Zero-freight records by seller

SELECT
    seller_id,
    COUNT(*) AS zero_freight_items
FROM order_items
WHERE freight_value = 0
GROUP BY seller_id
ORDER BY zero_freight_items DESC;


-- 8. Relationship: Order Items → Orders

SELECT DISTINCT ot.order_id
FROM order_items ot
LEFT JOIN orders o
    ON ot.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 9. Relationship: Order Items → Products

SELECT DISTINCT ot.product_id
FROM order_items ot
LEFT JOIN products p
    ON ot.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 10. Relationship: Order Items → Sellers

SELECT DISTINCT ot.seller_id
FROM order_items ot
LEFT JOIN sellers s
    ON ot.seller_id = s.seller_id
WHERE s.seller_id IS NULL;