-- Step 3 — Data Profiling

-- Order Payments Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM order_payments;


-- 2. NULL values

SELECT
    SUM(order_id IS NULL) AS null_order_id,
    SUM(payment_sequential IS NULL) AS null_payment_sequential,
    SUM(payment_type IS NULL) AS null_payment_type,
    SUM(payment_installments IS NULL) AS null_installments,
    SUM(payment_value IS NULL) AS null_payment_value
FROM order_payments;


-- 3. Duplicate payment records

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS appearance_count
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- 4. Payment types

SELECT
    payment_type,
    COUNT(*) AS payment_count
FROM order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;


-- 5. Installment range

SELECT
    MIN(payment_installments) AS min_installments,
    MAX(payment_installments) AS max_installments
FROM order_payments;


-- Suspicious installment values

SELECT *
FROM order_payments
WHERE payment_installments <= 0;


-- 6. Payment value range

SELECT
    MIN(payment_value) AS min_payment_value,
    MAX(payment_value) AS max_payment_value
FROM order_payments;


-- Zero or negative payment values

SELECT *
FROM order_payments
WHERE payment_value <= 0;


-- 7. Payment sequential range

SELECT
    MIN(payment_sequential) AS min_sequential,
    MAX(payment_sequential) AS max_sequential
FROM order_payments;


-- Invalid sequential values

SELECT *
FROM order_payments
WHERE payment_sequential <= 0;


-- 8. Relationship: Payments → Orders

SELECT DISTINCT op.order_id
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 9. Payment totals vs Order Items

SELECT
    p.order_id,
    p.total_payment,
    i.order_value
FROM (
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2) AS total_payment
    FROM order_payments
    GROUP BY order_id
) p
JOIN (
    SELECT
        order_id,
        ROUND(SUM(price + freight_value), 2) AS order_value
    FROM order_items
    GROUP BY order_id
) i
    ON p.order_id = i.order_id
WHERE ABS(p.total_payment - i.order_value) > 0.05
ORDER BY ABS(p.total_payment - i.order_value) DESC;