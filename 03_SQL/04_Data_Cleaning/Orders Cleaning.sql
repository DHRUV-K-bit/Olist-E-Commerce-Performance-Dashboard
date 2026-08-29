-- Step 4 — Data Cleaning

-- Orders Table

USE olist_bi;


-- 1. Investigate carrier dates occurring before purchase

SELECT
    MIN(
        TIMESTAMPDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_purchase_timestamp
        )
    ) AS smallest_difference_hours,
    MAX(
        TIMESTAMPDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_purchase_timestamp
        )
    ) AS largest_difference_hours,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                HOUR,
                order_delivered_carrier_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS average_difference_hours
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;


-- 2. Group the timestamp anomalies by size

SELECT
    CASE
        WHEN TIMESTAMPDIFF(
                 HOUR,
                 order_delivered_carrier_date,
                 order_purchase_timestamp
             ) <= 1
            THEN '0-1 hour'

        WHEN TIMESTAMPDIFF(
                 HOUR,
                 order_delivered_carrier_date,
                 order_purchase_timestamp
             ) <= 24
            THEN '1-24 hours'

        WHEN TIMESTAMPDIFF(
                 HOUR,
                 order_delivered_carrier_date,
                 order_purchase_timestamp
             ) <= 72
            THEN '1-3 days'

        WHEN TIMESTAMPDIFF(
                 HOUR,
                 order_delivered_carrier_date,
                 order_purchase_timestamp
             ) <= 168
            THEN '3-7 days'

        ELSE 'More than 7 days'
    END AS anomaly_range,
    COUNT(*) AS order_count
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp
GROUP BY anomaly_range
ORDER BY
    CASE anomaly_range
        WHEN '0-1 hour' THEN 1
        WHEN '1-24 hours' THEN 2
        WHEN '1-3 days' THEN 3
        WHEN '3-7 days' THEN 4
        WHEN 'More than 7 days' THEN 5
    END;


-- 3. Investigate delivered orders with missing timestamps

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
      )
ORDER BY order_id;


-- 4. Classify the missing timestamps

SELECT
    CASE
        WHEN order_approved_at IS NULL
             AND order_delivered_customer_date IS NULL
            THEN 'Approval + customer delivery missing'

        WHEN order_approved_at IS NULL
            THEN 'Approval missing'

        WHEN order_delivered_customer_date IS NULL
            THEN 'Customer delivery missing'
    END AS missing_timestamp_type,
    COUNT(*) AS order_count
FROM orders
WHERE order_status = 'delivered'
  AND (
        order_approved_at IS NULL
        OR order_delivered_customer_date IS NULL
      )
GROUP BY missing_timestamp_type;


-- No timestamp values are changed here because there is no reliable
-- source for reconstructing the missing or inconsistent dates.