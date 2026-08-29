-- Step 3 — Data Profiling

-- Order Reviews Table

-- 1. Row count
-- 99223
SELECT COUNT(*)
FROM order_reviews;

-- 2. NULL values

-- review_id
-- Empty set (0.576 sec)
SELECT review_id
FROM order_reviews
WHERE review_id IS NULL;

-- order_id
-- Empty set (0.520 sec)
SELECT order_id
FROM order_reviews
WHERE order_id IS NULL;

-- review_score
-- Empty set (0.433 sec)
SELECT review_score
FROM order_reviews
WHERE review_score IS NULL;

-- review_comment_title
-- Empty set (3.641 sec)
SELECT review_comment_title
FROM order_reviews
WHERE review_comment_title IS NULL;

-- review_comment_message
-- Empty set (0.452 sec)
SELECT review_comment_message
FROM order_reviews
WHERE review_comment_message IS NULL;

-- review_creation_date
-- Empty set (0.504 sec)
SELECT review_creation_date
FROM order_reviews
WHERE review_creation_date IS NULL;

-- review_answer_timestamp
-- Empty set (0.461 sec)
SELECT review_answer_timestamp
FROM order_reviews
WHERE review_answer_timestamp IS NULL;

-- 3. Duplicate review_id
-- 789 rows in set (2.372 sec)
SELECT
    review_id,
    COUNT(*) AS appearance_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- 4. Duplicate order_id
-- 547 rows in set (2.493 sec)
SELECT
    order_id,
    COUNT(*) AS appearance_count
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 5. Review score

-- What scores exist?
-- 5 rows in set (0.693 sec) -- 1,2,3,4,5
SELECT DISTINCT review_score
FROM order_reviews
ORDER BY review_score;

-- Count each score
			 1 |        11424 |
|            2 |         3151 |
|            3 |         8179 |
|            4 |        19142 |
|            5 |        57327
-- 5 rows in set (0.681 sec)
SELECT
    review_score,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Check for invalid scores
-- Empty set (0.752 sec)
SELECT *
FROM order_reviews
WHERE review_score < 1
   OR review_score > 5;
   
-- 6. Review timestamps

-- Check the date range
+---------------------+---------------------+
| earliest_review     | latest_review       |
+---------------------+---------------------+
| 0000-00-00 00:00:00 | 2018-08-31 00:00:00 |
+---------------------+---------------------+
SELECT
    MIN(review_creation_date) AS earliest_review,
    MAX(review_creation_date) AS latest_review
FROM order_reviews;

-- Check if review was created AFTER it was answered
-- Empty set (0.731 sec)
SELECT
    review_id,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews
WHERE review_answer_timestamp < review_creation_date;

-- Check for future/invalid sequence relative to order purchase
-- 75 rows in set (9.443 sec)
SELECT
    r.review_id,
    r.order_id,
    o.order_purchase_timestamp,
    r.review_creation_date
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp;

-- 7. Check blank review titles/messages

-- 87655
SELECT COUNT(*) AS blank_titles
FROM order_reviews
WHERE review_comment_title = '';

-- 58247
SELECT COUNT(*) AS blank_messages
FROM order_reviews
WHERE review_comment_message = '';

-- 8. Every review should belong to an existing order
-- Empty set (4.999 sec)
SELECT DISTINCT r.order_id
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 9. Does one review_id belong to multiple orders?
-- 789 rows in set (2.610 sec)
SELECT
    review_id,
    COUNT(DISTINCT order_id) AS order_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(DISTINCT order_id) > 1;


-- One correction about #9

-- The fact that there are 789 review_ids with multiple orders does
-- NOT automatically mean the reviews are duplicates. We need to look at the actual records first.

SELECT
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
)
ORDER BY review_id
LIMIT 20;




-- Also, let's investigate the 75 reviews before purchase:

SELECT
    r.review_id,
    r.order_id,
    o.order_purchase_timestamp,
    r.review_creation_date
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp
ORDER BY r.review_creation_date
LIMIT 20;




Great. These results clarify both issues.

1. Duplicate review_id — this looks like a dataset characteristic

Look at the examples:

same review_id
→ different order_id
→ same score
→ same creation date
→ same answer timestamp

So these aren't necessarily accidental duplicate rows. The same review record/content appears to have been associated with multiple orders.

Therefore, don't delete the 789 review_id duplicates just because they're duplicated.

We'll preserve them and be careful with review metrics later.

2. The 75 reviews before purchase — we found the main issue

Your first result is:

review_creation_date = 0000-00-00

That's clearly an invalid date.

But the other examples are more interesting. For example:

Purchase: 2016-10-22
Review:   2016-10-09

That is genuinely before the purchase date.

So we have two different issues:

0000-00-00 → invalid/missing date that needs cleaning
Real dates before purchase → data inconsistency/anomaly, which we should investigate rather than blindly change
One thing I want you to check

Let's find out how many 0000-00-00 dates there are:

SELECT COUNT(*) AS zero_dates
FROM order_reviews
WHERE review_creation_date = '0000-00-00 00:00:00';

And let's see whether the 75 anomalies are actually just these zero dates or whether there are genuine dates before purchase:

SELECT COUNT(*) AS real_date_anomalies
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp
  AND r.review_creation_date <> '0000-00-00 00:00:00';

Send me those two numbers. Then we'll know exactly what we're dealing with.

We can detect those rows without directly writing the zero-date literal.

Run this instead:
SELECT COUNT(*) AS zero_dates
FROM order_reviews
WHERE YEAR(review_creation_date) = 0;

Then:

SELECT COUNT(*) AS real_date_anomalies
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp
  AND YEAR(r.review_creation_date) <> 0;

This separates:

YEAR(...) = 0 → invalid 0000-00-00 dates
YEAR(...) <> 0 + review before purchase → genuine date anomalies

Perfect. Now we know exactly what's happening:

1 row has the invalid 0000-00-00 review date → 🔴 data-quality issue
74 rows have a real review date earlier than the order purchase → ⚠️ anomaly
Together = 75 rows, matching our original result. ✅
What we'll do during cleaning

1 invalid zero-date: we'll handle it during cleaning.

74 real anomalies: we won't change the dates blindly. We'll document them as anomalies unless further investigation gives us a reliable correction.

So the Order Reviews profiling is essentially complete. ✅