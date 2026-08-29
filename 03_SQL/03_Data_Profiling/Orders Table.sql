-- Step 3 — Data Profiling

-- Orders Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM orders;


-- 2. NULL values

SELECT
    SUM(order_id IS NULL) AS null_order_id,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(order_status IS NULL) AS null_order_status,
    SUM(order_purchase_timestamp IS NULL) AS null_purchase_timestamp,
    SUM(order_approved_at IS NULL) AS null_approved_at,
    SUM(order_delivered_carrier_date IS NULL) AS null_carrier_date,
    SUM(order_delivered_customer_date IS NULL) AS null_customer_date,
    SUM(order_estimated_delivery_date IS NULL) AS null_estimated_delivery
FROM orders;


-- 3. Duplicate order_id

SELECT
    order_id,
    COUNT(*) AS appearance_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 4. Order status

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 5. Purchase date range

SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase,
    MAX(order_purchase_timestamp) AS latest_purchase
FROM orders;


-- 6. Timestamp sequence checks

-- Approval before purchase
SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at
FROM orders
WHERE order_approved_at < order_purchase_timestamp;


-- Carrier date before purchase
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;


-- Customer delivery before purchase
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;


-- Estimated delivery before purchase
SELECT
    order_id,
    order_purchase_timestamp,
    order_estimated_delivery_date
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;


-- 7. Delivered orders with missing milestones

SELECT
    order_id,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
  AND (
        order_approved_at IS NULL
        OR order_delivered_carrier_date IS NULL
        OR order_delivered_customer_date IS NULL
      );


-- 8. Canceled orders with delivery timestamps

SELECT
    order_id,
    order_status,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'canceled'
  AND (
        order_delivered_carrier_date IS NOT NULL
        OR order_delivered_customer_date IS NOT NULL
      );


-- 9. Relationship: Orders → Customers

SELECT DISTINCT o.customer_id
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;