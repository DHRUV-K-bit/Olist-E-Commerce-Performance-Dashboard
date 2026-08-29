-- Step 3 — Data Profiling

-- Order Reviews Table

USE olist_bi;


-- 1. Row count

SELECT COUNT(*) AS row_count
FROM order_reviews;


-- 2. NULL values

SELECT
    SUM(review_id IS NULL) AS null_review_id,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(review_score IS NULL) AS null_review_score,
    SUM(review_comment_title IS NULL) AS null_comment_title,
    SUM(review_comment_message IS NULL) AS null_comment_message,
    SUM(review_creation_date IS NULL) AS null_creation_date,
    SUM(review_answer_timestamp IS NULL) AS null_answer_timestamp
FROM order_reviews;


-- 3. Repeated review_id

SELECT
    review_id,
    COUNT(*) AS appearance_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY appearance_count DESC;


-- 4. Repeated order_id

SELECT
    order_id,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC;


-- 5. Review score distribution

SELECT
    review_score,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;


-- Check for invalid review scores

SELECT *
FROM order_reviews
WHERE review_score < 1
   OR review_score > 5;


-- 6. Review date range

SELECT
    MIN(review_creation_date) AS earliest_review,
    MAX(review_creation_date) AS latest_review
FROM order_reviews;


-- 7. Review answered before it was created

SELECT
    review_id,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews
WHERE review_answer_timestamp < review_creation_date;


-- 8. Reviews created before order purchase

SELECT
    r.review_id,
    r.order_id,
    o.order_purchase_timestamp,
    r.review_creation_date
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp;


-- 9. Blank review comments

SELECT
    SUM(review_comment_title = '') AS blank_titles,
    SUM(review_comment_message = '') AS blank_messages
FROM order_reviews;


-- 10. Relationship: Reviews → Orders

SELECT DISTINCT r.order_id
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 11. Review IDs associated with multiple orders

SELECT
    review_id,
    COUNT(DISTINCT order_id) AS order_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(DISTINCT order_id) > 1
ORDER BY order_count DESC;