-- Step 3 — Data Profiling

-- Order Payments Table

-- 1. Row count
-- 103886 
SELECT COUNT(*)
FROM order_payments;

-- 2. NULL / missing values

-- order_id
-- Empty set (0.596 sec)
SELECT order_id
FROM order_payments
WHERE order_id IS NULL;

-- payment_sequential
-- Empty set (0.607 sec)
SELECT payment_sequential
FROM order_payments
WHERE payment_sequential IS NULL;

-- payment_type
-- Empty set (0.480 sec)
SELECT payment_type
FROM order_payments
WHERE payment_type IS NULL;

-- payment_installments
-- Empty set (0.546 sec)
SELECT payment_installments
FROM order_payments
WHERE payment_installments IS NULL;

-- payment_value
-- Empty set (0.511 sec)
SELECT payment_value
FROM order_payments
WHERE payment_value IS NULL;


-- 3. Duplicate payment records
-- Empty set (2.572 sec)
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS appearance_count
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- 4. Payment types
-- 5 rows in set (0.696 sec)
SELECT DISTINCT payment_type
FROM order_payments;

-- COUNT of each type
-- 5 rows in set (1.181 sec)
SELECT
    payment_type,
    COUNT(*) AS payment_count
FROM order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;

-- 5. Payment installments
-- MIN: 0 | MAX: 24
SELECT
    MIN(payment_installments) AS min_installments,
    MAX(payment_installments) AS max_installments
FROM order_payments;

-- Check suspicious values:
-- 2 rows in set (0.626 sec) -- BOTH EQULAL TO ZERO
SELECT *
FROM order_payments
WHERE payment_installments <= 0;

-- 6. Payment value
-- MIN: 0.00 | MAX: 13664.08
SELECT
    MIN(payment_value) AS min_payment_value,
    MAX(payment_value) AS max_payment_value
FROM order_payments;

-- Check suspicious values:
-- 9 rows in set (0.556 sec) -- ALL payment_value = 0
SELECT *
FROM order_payments
WHERE payment_value <= 0;

-- 7. Payment sequential
-- MIN: 1 | MAX: 29
SELECT
    MIN(payment_sequential) AS min_sequential,
    MAX(payment_sequential) AS max_sequential
FROM order_payments;

-- Check suspicious values:
-- Empty set (0.542 sec)
SELECT *
FROM order_payments
WHERE payment_sequential <= 0;

-- 8. Relationship → Orders
-- Empty set (5.963 sec)
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
FROM
    (
        SELECT
            order_id,
            ROUND(SUM(payment_value), 2) AS total_payment
        FROM order_payments
        GROUP BY order_id
    ) p
JOIN
    (
        SELECT
            order_id,
            ROUND(SUM(price + freight_value), 2) AS order_value
        FROM order_items
        GROUP BY order_id
    ) i
ON p.order_id = i.order_id
WHERE p.total_payment <> i.order_value
LIMIT 20;

-- One final check

-- Let's find how many orders have a meaningful difference, ignoring tiny rounding differences.

-- Run:

SELECT
    COUNT(*) AS meaningful_mismatches
FROM
    (
        SELECT
            p.order_id,
            p.total_payment,
            i.order_value
        FROM
            (
                SELECT order_id, ROUND(SUM(payment_value), 2) AS total_payment
                FROM order_payments
                GROUP BY order_id
            ) p
        JOIN
            (
                SELECT order_id, ROUND(SUM(price + freight_value), 2) AS order_value
                FROM order_items
                GROUP BY order_id
            ) i
        ON p.order_id = i.order_id
        WHERE ABS(p.total_payment - i.order_value) > 0.05
    ) x;

Good. 260 orders have a meaningful payment-vs-order-value difference (> 0.05).

But this is not automatically a cleaning error. It is a data-quality finding that we should document/investigate, especially because most of the dataset still matches closely.

Payments profiling conclusion
✅ No NULLs
✅ No duplicate payment records
✅ Valid payment types
⚠️ 2 credit-card records have payment_installments = 0
🟡 9 zero-value payment records — retained
🟡 260 orders have meaningful differences between payment totals and price + freight

For now, don't modify these 260 orders. We don't have enough evidence to call them incorrect





First: investigate the 2 zero-installment records

Run:

SELECT *
FROM order_payments
WHERE payment_installments = 0;
Then: investigate the 9 zero-payment records
SELECT *
FROM order_payments
WHERE payment_value = 0;

Send me both results.

Yep. These results tell us something useful:

1. payment_installments = 0 → ⚠️ suspicious

Both are credit card payments with actual payment values:

58.69
129.94

So 0 installments doesn't make logical sense for a credit-card payment. We'll flag these for cleaning, rather than pretending they're valid.

2. payment_value = 0 → 🟡 don't automatically delete

All 9 zero-value payments are either:

voucher
not_defined

And importantly, they are not necessarily the entire payment for the order. Some orders have multiple payment records.

So don't delete them yet. They may represent voucher/payment records with zero monetary contribution.

Next check

Let's see whether these 9 orders have other payment records with actual values:

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_value
FROM order_payments
WHERE order_id IN (
    SELECT order_id
    FROM order_payments
    WHERE payment_value = 0
)
ORDER BY order_id, payment_sequential;

Perfect. This confirms what we suspected.

What we learned

The zero-payment rows are not necessarily bad data:

45ed..., 6ccb..., 8bc..., b238..., and fa65... have other payment records with positive values.
So the 0.00 voucher rows are likely additional voucher records that contributed nothing to the payment total.
The three not_defined rows with 0.00 are unusual, but they don't affect the monetary total.
So for cleaning:

Do NOT delete the 9 zero-payment rows.
We should preserve the original payment records and handle them appropriately when calculating payment metrics.

The 2 credit-card rows with payment_installments = 0 are the actual suspicious values we'll flag for cleaning.