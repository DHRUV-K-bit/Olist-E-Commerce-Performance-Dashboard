-- Step 3 — Data Profiling

-- Orders Table

-- 1. Row count
-- 99441
SELECT COUNT(*)
FROM orders;

-- 2. NULL values in all columns

-- order_id
-- Empty set (0.577 sec)
SELECT order_id
FROM orders
WHERE order_id IS NULL;

-- customer_id
-- Empty set (0.484 sec)
SELECT customer_id
FROM orders
WHERE customer_id IS NULL;

-- order_status
-- Empty set (0.486 sec)
SELECT order_status
FROM orders
WHERE order_status IS NULL;

-- order_purchase_timestamp
-- Empty set (0.422 sec)
SELECT order_purchase_timestamp
FROM orders
WHERE order_purchase_timestamp IS NULL;

-- order_approved_at
-- 160 NULL ROWS
-- 160 rows in set (0.496 sec)
SELECT order_approved_at
FROM orders
WHERE order_approved_at IS NULL;

-- order_delivered_carrier_date
-- 1783 NULL ROWS
-- 1783 rows in set (0.470 sec)
SELECT order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date IS NULL;

-- order_delivered_customer_date
-- 2965 NULL ROWS
-- 2965 rows in set (0.452 sec)
SELECT order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date IS NULL;

-- order_estimated_delivery_date
-- Empty set (0.471 sec)
SELECT order_estimated_delivery_date
FROM orders
WHERE order_estimated_delivery_date IS NULL;

-- 3. Duplicate order_id
-- Empty set (2.021 sec)
SELECT 
	order_id,
    COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 4. Order status — DISTINCT order_status
delivered    |
| invoiced     |
| shipped      |
| processing   |
| unavailable  |
| canceled     |
| created      |
| approved
-- 8 rows in set (0.691 sec)
SELECT DISTINCT order_status
FROM orders;

-- 5. Purchase date range — MIN/MAX
-- MIN: 2016-09-04 21:15:19 | MAX: 2018-10-17 17:30:18
SELECT 
	MIN(order_purchase_timestamp),
    MAX(order_purchase_timestamp )
FROM orders;

-- 6. Check timestamp sequence

-- Approval before purchase?
-- Empty set (0.719 sec)
SELECT 
	order_id,
    order_purchase_timestamp,
    order_approved_at
FROM orders
WHERE order_approved_at < order_purchase_timestamp;

-- Carrier delivery before purchase?
-- 166 rows in set (0.647 sec)
SELECT 
	order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;

-- Customer delivery before purchase?
-- Empty set (0.684 sec)
SELECT 
	order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- Estimated delivery before purchase?
-- Empty set (0.660 sec)
SELECT 
	order_id,
    order_purchase_timestamp,
    order_estimated_delivery_date
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;

-- 7. Delivery date NULLs by order status

-- created
-- Empty set (0.660 sec)
SELECT 
	order_id, 
    order_status, 
    order_approved_at, 
    order_delivered_carrier_date
FROM orders
WHERE order_status = 'created'
  AND (
			order_approved_at IS NOT NULL 
		OR	
			order_delivered_carrier_date IS NOT NULL
		OR
			order_delivered_customer_date IS NOT NULL
	  );

-- approved
-- Empty set (0.592 sec)
SELECT 
	order_id, 
    order_status, 
    order_approved_at, 
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'approved'
  AND (
			order_approved_at IS NULL 
		OR 	
			order_delivered_carrier_date IS NOT NULL
        OR
			order_delivered_customer_date IS NOT NULL 
  );


-- processing
-- Empty set (0.557 sec)
SELECT 
	order_id,
    order_status,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders 
WHERE order_status = 'processing' 
	AND (
			order_approved_at IS NULL
		OR
			order_delivered_carrier_date IS NOT NULL
		OR
			order_delivered_customer_date IS NOT NULL
		);
        
-- invoiced
-- Empty set (0.569 sec)
SELECT 
	order_id,
    order_status,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders 
WHERE order_status = 'invoiced' 
	AND (
			order_approved_at IS NULL
		OR
			order_delivered_carrier_date IS NOT NULL
		OR
			order_delivered_customer_date IS NOT NULL
		);

-- shipped     
-- Empty set (0.704 sec)
SELECT
	order_id,
    order_status,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'shipped'
	AND (
			order_approved_at IS NULL -- Must be approved to ship
		OR 
            order_delivered_carrier_date IS NULL  -- Must be with carrier to ship
		OR 
			order_delivered_customer_date IS NOT NULL -- Can't be delivered if still shipping
		);

-- delivered
-- 23 rows in set (0.745 sec)
SELECT 
	order_id,
    order_status,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders 
WHERE order_status = 'delivered' 
	AND (
			order_approved_at IS NULL
		OR
			order_delivered_carrier_date IS NULL
		OR
			order_delivered_customer_date IS NULL
		);

-- unavailable
-- Empty set (0.622 sec)
SELECT 
	order_id,
    order_status,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders 
WHERE order_status = 'unavailable' 
	AND (
			order_delivered_carrier_date IS NOT NULL
		OR
			order_delivered_customer_date IS NOT NULL
		);

-- canceled
-- 6 rows in set (0.593 sec)
SELECT 
	order_id, 
    order_status, 
    order_approved_at,
    order_delivered_carrier_date, 
    order_delivered_customer_date
FROM orders
WHERE order_status = 'canceled' AND order_delivered_customer_date IS NOT NULL;

-- 8. Relationship: Orders → Customers
-- Empty set (6.269 sec)
SELECT DISTINCT o.customer_id
FROM orders o
	LEFT JOIN customers c ON
							c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;
        
-- Let's investigate the 166 carrier-before-purchase records first, because that's the clearest chronological violation.

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp
ORDER BY order_purchase_timestamp;

What we found

Most of the 166 records have the carrier timestamp only a few minutes before the purchase timestamp.

For example:

Purchase: 2018-04-25 13:02:26
Carrier:  2018-04-25 12:36:00

That's a 26-minute difference.

There are many similar cases. This suggests a systematic timestamp inconsistency, rather than 166 completely random bad records.

But there are also extreme cases, such as:

Purchase: 2018-07-16 18:40:53
Carrier:  2018-01-26 13:35:00

That's clearly much more suspicious.

So we DON'T fix all 166 the same way.

We should first measure how far apart the timestamps are.

Run:

SELECT
    COUNT(*) AS affected_orders,
    MIN(TIMESTAMPDIFF(MINUTE, order_delivered_carrier_date, order_purchase_timestamp)) AS smallest_difference_minutes,
    MAX(TIMESTAMPDIFF(MINUTE, order_delivered_carrier_date, order_purchase_timestamp)) AS largest_difference_minutes,
    AVG(TIMESTAMPDIFF(MINUTE, order_delivered_carrier_date, order_purchase_timestamp)) AS average_difference_minutes
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;

This tells us:

How serious is the timestamp problem overall?

Exactly. This gives us a clearer picture:

166 affected orders
Smallest difference: 0 minutes
Largest difference: 246,545 minutes ≈ 171 days
Average difference: 1,562 minutes ≈ 26 hours

So this is not just a few-minute rounding issue. Most may be small discrepancies, but some are clearly major timestamp anomalies.

Profiling conclusion

We'll flag these 166 records as timestamp anomalies and deal with them during the cleaning stage.

Next

Let's investigate the 23 delivered orders with missing delivery milestones.

Run:

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
WHERE order_status = 'delivered'
AND (
    order_approved_at IS NULL
    OR order_delivered_carrier_date IS NULL
    OR order_delivered_customer_date IS NULL
);

This is useful. The 23 rows are not all the same problem.

What we found

1. 16 orders have order_approved_at = NULL, but they were eventually delivered.

For example:

purchase → NULL approval → carrier → delivered

That's a missing approval timestamp, not necessarily a missing approval event, because the later logistics timestamps exist.

2. 6 orders have order_delivered_customer_date = NULL, despite being marked delivered.

That's a genuine missing delivery timestamp.

3. 1 order has both carrier and customer delivery dates NULL.

So we'll flag these as missing/incomplete timestamps.

Important

We're not going to invent timestamps such as:

"Let's assume approval happened 10 minutes after purchase."

No. We don't have evidence for that.

During cleaning, we'll preserve the known dates and leave genuinely unknown dates as NULL.

Also, this is a good example of why NULL ≠ bad row. The order itself can still be useful even if one milestone timestamp wasn't recorded.

One more thing before we move on

Your earlier query found 6 canceled orders with a customer delivery date. That's worth investigating next.

Run:

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
WHERE order_status = 'canceled'
AND order_delivered_customer_date IS NOT NULL;


This confirms the 6 canceled orders are genuine anomalies in the dataset:

All 6 were approved
All 6 were shipped to the carrier
All 6 have a customer delivery date
Yet their final order_status is canceled

So these aren't simply missing timestamps. They're status/timestamp inconsistencies.

Profiling conclusion for Orders

We'll flag:

166 carrier-before-purchase timestamp anomalies
23 delivered orders with missing milestone timestamps
6 canceled orders with delivery timestamps

And importantly, we won't delete these orders. During cleaning, we'll decide how to handle the problematic fields/statuses without losing potentially useful order data.

✅ Orders profiling is now complete.
