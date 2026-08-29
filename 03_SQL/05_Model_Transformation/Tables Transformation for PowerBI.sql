-- TRANSFORMATION

-- Dim_Geography

-- Creating Dim_Geography
CREATE TABLE Dim_Geography (
    GeographyKey INT AUTO_INCREMENT PRIMARY KEY,
    Zip_Prefix INT NOT NULL,
    City VARCHAR(100),
    State CHAR(2),
    Latitude DECIMAL(18,13),
    Longitude DECIMAL(18,13)
);

-- Populating Dim_Geography
INSERT INTO Dim_Geography
    (Zip_Prefix, City, State, Latitude, Longitude)
WITH
city_counts AS (
    SELECT
        geolocation_zip_code_prefix AS Zip_Prefix,
        geolocation_city AS City,
        COUNT(*) AS city_count
    FROM geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city
),
ranked_cities AS (
    SELECT
        Zip_Prefix,
        City,
        ROW_NUMBER() OVER (
            PARTITION BY Zip_Prefix
            ORDER BY city_count DESC, City
        ) AS rn
    FROM city_counts
),
state_counts AS (
    SELECT
        geolocation_zip_code_prefix AS Zip_Prefix,
        geolocation_state AS State,
        COUNT(*) AS state_count
    FROM geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_state
),
ranked_states AS (
    SELECT
        Zip_Prefix,
        State,
        ROW_NUMBER() OVER (
            PARTITION BY Zip_Prefix
            ORDER BY state_count DESC, State
        ) AS rn
    FROM state_counts
),
coordinates AS (
    SELECT
        geolocation_zip_code_prefix AS Zip_Prefix,
        ROUND(AVG(geolocation_lat), 13) AS Latitude,
        ROUND(AVG(geolocation_lng), 13) AS Longitude
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix
)
SELECT
    c.Zip_Prefix,
    c.City,
    s.State,
    co.Latitude,
    co.Longitude
FROM ranked_cities c
JOIN ranked_states s
    ON c.Zip_Prefix = s.Zip_Prefix
JOIN coordinates co
    ON c.Zip_Prefix = co.Zip_Prefix
WHERE c.rn = 1
  AND s.rn = 1;

-- Verifying Count (19,015)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Zip_Prefix) AS unique_zip_prefixes,
    COUNT(DISTINCT GeographyKey) AS unique_geography_keys
FROM Dim_Geography;


-- Dim_Category

-- Creating Dim_Category
CREATE TABLE Dim_Category (
    CategoryKey INT AUTO_INCREMENT PRIMARY KEY,
    Category_Name_PT VARCHAR(100) NOT NULL,
    Category_Name_EN VARCHAR(100)
);

-- Inserting Cleaned Data into Dim_Category
INSERT INTO Dim_Category
    (Category_Name_PT, Category_Name_EN)
SELECT
    product_category_name,
    product_category_name_english
FROM product_category_translation;

-- 
INSERT INTO Dim_Category
    (Category_Name_PT, Category_Name_EN)
VALUES
    ('pc_gamer', NULL),
    ('portateis_cozinha_e_preparadores_de_alimentos', NULL),
    ('', 'Uncategorized');
    
-- Verifying Count (74)
SELECT
    COUNT(*) AS total_categories,
    COUNT(DISTINCT CategoryKey) AS unique_category_keys
FROM Dim_Category;


-- Dim_Customer

-- Creating Dim_Customer
CREATE TABLE Dim_Customer (
    CustomerKey INT AUTO_INCREMENT PRIMARY KEY,
    Customer_ID CHAR(32) NOT NULL,
    Customer_Unique_ID CHAR(32) NOT NULL,
    GeographyKey INT
);

-- Populating table
INSERT INTO Dim_Customer
    (Customer_ID, Customer_Unique_ID)
SELECT
    customer_id,
    customer_unique_id
FROM customers;

-- Verifying Keys (99441)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CustomerKey) AS unique_customer_keys,
    COUNT(DISTINCT Customer_ID) AS unique_customer_ids
FROM Dim_Customer;

-- Checking how many geography records each customer ZIP prefix can match.
SELECT
    c.customer_zip_code_prefix,
    COUNT(g.GeographyKey) AS geography_records
FROM customers c
LEFT JOIN Dim_Geography g
    ON c.customer_zip_code_prefix = g.Zip_Prefix
GROUP BY c.customer_zip_code_prefix
ORDER BY geography_records DESC;


-- Creating Indexes
CREATE INDEX idx_customers_customer_id
ON customers(customer_id);

CREATE INDEX idx_customers_zip
ON customers(customer_zip_code_prefix);

CREATE INDEX idx_dim_geography_zip
ON Dim_Geography(Zip_Prefix);


-- 
UPDATE Dim_Customer c
JOIN customers src
    ON c.Customer_ID = src.customer_id
JOIN Dim_Geography g
    ON src.customer_zip_code_prefix = g.Zip_Prefix
SET c.GeographyKey = g.GeographyKey;

-- Verify how many customers successfully matched
SELECT
    COUNT(*) AS total_customers,
    COUNT(GeographyKey) AS customers_with_geography,
    COUNT(*) - COUNT(GeographyKey) AS customers_without_geography
FROM Dim_Customer;


-- Dim_Product

-- Creating Dim_Product
CREATE TABLE Dim_Product (
    ProductKey INT AUTO_INCREMENT PRIMARY KEY,
    Product_ID CHAR(32) NOT NULL,
    CategoryKey INT,
    Product_Name_Length INT,
    Product_Description_Length INT,
    Weight_G INT,
    Length_CM INT,
    Width_CM INT,
    Height_CM INT,
    Photos_Qty INT,
    Product_Volume DECIMAL(15,2),
    Size_Category VARCHAR(20)
);

-- Populating Dim_Product
INSERT INTO Dim_Product
    (
        Product_ID,
        CategoryKey,
        Product_Name_Length,
        Product_Description_Length,
        Weight_G,
        Length_CM,
        Width_CM,
        Height_CM,
        Photos_Qty,
        Product_Volume,
        Size_Category
    )
SELECT
    p.product_id,
    c.CategoryKey,
    p.product_name_length,
    p.product_description_length,
    p.product_weight_g,
    p.product_length_cm,
    p.product_width_cm,
    p.product_height_cm,
    p.product_photos_qty,
    ROUND(
        p.product_length_cm *
        p.product_width_cm *
        p.product_height_cm,
        2
    ) AS Product_Volume,
    CASE
        WHEN p.product_length_cm IS NULL
          OR p.product_width_cm IS NULL
          OR p.product_height_cm IS NULL
        THEN 'Unknown'

        WHEN (
            p.product_length_cm *
            p.product_width_cm *
            p.product_height_cm
        ) < 1000
        THEN 'Small'

        WHEN (
            p.product_length_cm *
            p.product_width_cm *
            p.product_height_cm
        ) < 10000
        THEN 'Medium'

        ELSE 'Large'
    END AS Size_Category
FROM products p
	LEFT JOIN Dim_Category c
		ON p.product_category_name = c.Category_Name_PT;
 
-- Verifying Count
SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT ProductKey) AS unique_product_keys,
    COUNT(DISTINCT Product_ID) AS unique_product_ids
FROM Dim_Product;


-- Dim_Seller

-- Creating Dim_Seller
CREATE TABLE Dim_Seller (
    SellerKey INT AUTO_INCREMENT PRIMARY KEY,
    Seller_ID CHAR(32) NOT NULL,
    GeographyKey INT
);

-- Populating it
INSERT INTO Dim_Seller
    (Seller_ID)
SELECT
    seller_id
FROM sellers;

-- Count Verification
SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT SellerKey) AS unique_seller_keys,
    COUNT(DISTINCT Seller_ID) AS unique_seller_ids
FROM Dim_Seller;

-- Creating Index
CREATE INDEX idx_sellers_seller_id
ON sellers(seller_id);

CREATE INDEX idx_sellers_zip
ON sellers(seller_zip_code_prefix);

CREATE INDEX idx_dim_seller_seller_id
ON Dim_Seller(Seller_ID);

-- Updating GeographyKey
UPDATE Dim_Seller ds
JOIN sellers s
    ON ds.Seller_ID = s.seller_id
JOIN Dim_Geography g
    ON s.seller_zip_code_prefix = g.Zip_Prefix
SET ds.GeographyKey = g.GeographyKey;

-- Count Verification
SELECT
    COUNT(*) AS total_sellers,
    COUNT(GeographyKey) AS sellers_with_geography,
    COUNT(*) - COUNT(GeographyKey) AS sellers_without_geography
FROM Dim_Seller;

-- Fact_OrderItems

-- Creating Dim_OrderItems
CREATE TABLE Fact_OrderItems (
    OrderItemKey INT AUTO_INCREMENT PRIMARY KEY,
    Order_ID CHAR(32) NOT NULL,
    Order_Item_ID INT NOT NULL,
    ProductKey INT,
    SellerKey INT,
    CustomerKey INT,
    Shipping_Limit_Date DATE,
    Price DECIMAL(10,2),
    Freight_Value DECIMAL(10,2)
);

-- Populating Dim_OrderItems

-- Creating Indexes
CREATE INDEX idx_dim_product_product_id
ON Dim_Product(Product_ID);

CREATE INDEX idx_dim_seller_seller_id
ON Dim_Seller(Seller_ID);

CREATE INDEX idx_dim_customer_customer_id
ON Dim_Customer(Customer_ID);

CREATE INDEX idx_order_items_order_id
ON order_items(order_id);

-- Inserting the order_item data
INSERT INTO Fact_OrderItems
(
    Order_ID,
    Order_Item_ID,
    ProductKey,
    SellerKey,
    CustomerKey,
    Shipping_Limit_Date,
    Price,
    Freight_Value
)
SELECT
    oi.order_id,
    oi.order_item_id,
    p.ProductKey,
    s.SellerKey,
    c.CustomerKey,
    DATE(oi.shipping_limit_date),
    oi.price,
    oi.freight_value
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN Dim_Product p
    ON oi.product_id = p.Product_ID
LEFT JOIN Dim_Seller s
    ON oi.seller_id = s.Seller_ID
LEFT JOIN Dim_Customer c
    ON o.customer_id = c.Customer_ID;
    
-- Verifying Count (112650)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT OrderItemKey) AS unique_order_item_keys,
    COUNT(DISTINCT CONCAT(Order_ID, '-', Order_Item_ID)) AS unique_order_items
FROM Fact_OrderItems;

-- Fact_Orders

-- Creating Fact_Orders
CREATE TABLE Fact_Orders (
    OrderID CHAR(32) PRIMARY KEY,
    CustomerKey INT,
    PurchaseDateKey INT,
    Order_Status VARCHAR(20),
    Purchase_Timestamp DATETIME,
    Approved_Timestamp DATETIME,
    Carrier_Date DATETIME,
    Customer_Delivery_Date DATETIME,
    Estimated_Delivery_Date DATETIME,
    Delivery_Days INT,
    Early_Delivery_Flag TINYINT,
    Late_Delivery_Flag TINYINT
);

-- Populating Fact_Orders
INSERT INTO Fact_Orders
(
    OrderID,
    CustomerKey,
    PurchaseDateKey,
    Order_Status,
    Purchase_Timestamp,
    Approved_Timestamp,
    Carrier_Date,
    Customer_Delivery_Date,
    Estimated_Delivery_Date,
    Delivery_Days,
    Early_Delivery_Flag,
    Late_Delivery_Flag
)
SELECT
    o.order_id,
    c.CustomerKey,
    CAST(DATE_FORMAT(o.order_purchase_timestamp, '%Y%m%d') AS UNSIGNED),
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp
        )
        ELSE NULL
    END AS Delivery_Days,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
        THEN NULL
        WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS Early_Delivery_Flag,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
        THEN NULL
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS Late_Delivery_Flag

FROM orders o
LEFT JOIN Dim_Customer c
    ON o.customer_id = c.Customer_ID;
    
-- Count Verification (99441)
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT OrderID) AS unique_order_ids
FROM Fact_Orders;


-- Fact_OrderPayment

-- Creating Fact_OrderPayment
CREATE TABLE Fact_OrderPayment (
    PaymentKey INT AUTO_INCREMENT PRIMARY KEY,
    Order_ID CHAR(32) NOT NULL,
    Payment_Sequential INT NOT NULL,
    Payment_Type VARCHAR(30),
    Payment_Installments INT,
    Payment_Value DECIMAL(10,2)
);

-- Create Index
CREATE INDEX idx_order_payments_order_id
ON order_payments(order_id);

-- Populate
INSERT INTO Fact_OrderPayment
(
    Order_ID,
    Payment_Sequential,
    Payment_Type,
    Payment_Installments,
    Payment_Value
)
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM order_payments;

-- Count Verification
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT PaymentKey) AS unique_payment_keys,
    COUNT(DISTINCT CONCAT(Order_ID, '-', Payment_Sequential)) AS unique_payments
FROM Fact_OrderPayment;



-- Fact_OrderReviews 
-- Creating Fact_OrderReviews 
CREATE TABLE Fact_OrderReviews (
    ReviewKey INT AUTO_INCREMENT PRIMARY KEY,
    ReviewDateKey INT,
    Order_ID CHAR(32) NOT NULL,
    Review_ID CHAR(32) NOT NULL,
    Review_Score INT,
    Comment_Title TEXT,
    Comment_Message TEXT,
    Review_Creation_Date DATETIME,
    Review_Answer_Timestamp DATETIME
);

-- Creating Index
CREATE INDEX idx_order_reviews_order_id
ON order_reviews(order_id);

-- Populating
INSERT INTO Fact_OrderReviews
(
    ReviewDateKey,
    Order_ID,
    Review_ID,
    Review_Score,
    Comment_Title,
    Comment_Message,
    Review_Creation_Date,
    Review_Answer_Timestamp
)
SELECT
    CAST(DATE_FORMAT(review_creation_date, '%Y%m%d') AS UNSIGNED),
    order_id,
    review_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews;

-- Count Verification (99223)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ReviewKey) AS unique_review_keys,
    COUNT(DISTINCT CONCAT(Order_ID, '-', Review_ID)) AS unique_order_reviews
FROM Fact_OrderReviews;