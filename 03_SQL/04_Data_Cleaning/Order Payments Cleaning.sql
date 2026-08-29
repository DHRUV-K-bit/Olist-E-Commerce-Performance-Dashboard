-- Step 4 — Data Cleaning

-- Order Payments Table

USE olist_bi;


-- 1. Check credit card records with zero installments

SELECT
    order_id,
    payment_type,
    payment_sequential,
    payment_installments,
    payment_value
FROM order_payments
WHERE payment_type = 'credit_card'
  AND payment_installments = 0;


-- 2. Check whether zero-installment payments have other payment records

SELECT
    op.order_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM order_payments op
WHERE op.payment_sequential = 2
  AND NOT EXISTS (
        SELECT 1
        FROM order_payments op2
        WHERE op2.order_id = op.order_id
          AND op2.payment_sequential = 1
    )
ORDER BY op.order_id;


-- 3. Correct zero installment values

-- A credit card payment cannot have zero installments.
UPDATE order_payments
SET payment_installments = 1
WHERE payment_installments = 0;


-- 4. Verify the correction

SELECT COUNT(*) AS remaining_zero_installments
FROM order_payments
WHERE payment_installments = 0;


-- 5. Reproduce payment/order-value mismatches

SELECT
    p.order_id,
    ROUND(p.total_payment, 2) AS total_payment,
    ROUND(i.order_value, 2) AS order_value,
    ROUND(p.total_payment - i.order_value, 2) AS difference
FROM (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
) p
JOIN (
    SELECT
        order_id,
        SUM(price + freight_value) AS order_value
    FROM order_items
    GROUP BY order_id
) i
    ON p.order_id = i.order_id
WHERE ABS(p.total_payment - i.order_value) > 0.05
ORDER BY difference;


-- 6. Classify the mismatches

SELECT
    CASE
        WHEN p.total_payment > i.order_value
            THEN 'Payment greater than order value'
        WHEN p.total_payment < i.order_value
            THEN 'Payment less than order value'
    END AS mismatch_type,
    COUNT(*) AS order_count
FROM (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
) p
JOIN (
    SELECT
        order_id,
        SUM(price + freight_value) AS order_value
    FROM order_items
    GROUP BY order_id
) i
    ON p.order_id = i.order_id
WHERE ABS(p.total_payment - i.order_value) > 0.05
GROUP BY mismatch_type;


-- 7. Measure the size of the mismatches

SELECT
    MIN(ABS(p.total_payment - i.order_value)) AS smallest_difference,
    MAX(ABS(p.total_payment - i.order_value)) AS largest_difference,
    ROUND(
        AVG(ABS(p.total_payment - i.order_value)),
        2
    ) AS average_difference
FROM (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
) p
JOIN (
    SELECT
        order_id,
        SUM(price + freight_value) AS order_value
    FROM order_items
    GROUP BY order_id
) i
    ON p.order_id = i.order_id
WHERE ABS(p.total_payment - i.order_value) > 0.05;


-- The payment/order-value mismatches are not corrected because
-- the difference can result from valid payment structures such as
-- vouchers, multiple payments, or order-level differences.