-- Step 4 — Data Cleaning

-- Order Reviews Table

USE olist_bi;


-- 1. Find invalid zero dates

SELECT
    review_id,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews
WHERE YEAR(review_creation_date) = 0;


-- 2. Clean the invalid review record

-- The zero date is invalid, so represent the dates as NULL.
UPDATE order_reviews
SET
    review_creation_date = NULL,
    review_answer_timestamp = NULL
WHERE review_id = '636b237e87574ba29654deaba9eb9797';


-- 3. Verify the correction

SELECT
    review_id,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews
WHERE review_id = '636b237e87574ba29654deaba9eb9797';


-- 4. Check for remaining zero dates

SELECT COUNT(*) AS remaining_zero_dates
FROM order_reviews
WHERE YEAR(review_creation_date) = 0;


-- 5. Check real review-before-purchase anomalies

SELECT
    r.review_id,
    r.order_id,
    o.order_purchase_timestamp,
    r.review_creation_date
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp
  AND YEAR(r.review_creation_date) <> 0;

-- Real date anomalies are left unchanged because there is no
-- reliable source for determining the correct review date.