CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- created retail_transactions table

SET FOREIGN_KEY_CHECKS = 0;
SET autocommit = 0;

LOAD DATA LOCAL INFILE 'C:/Users/swathikanike/Downloads/E-commerce,Intelligence/retail_clean.csv'
INTO TABLE retail_transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
SET autocommit = 1;

SELECT COUNT(*) FROM retail_transactions;

-- created rfm_raw table

SET FOREIGN_KEY_CHECKS = 0;
SET autocommit = 0;

CREATE TABLE rfm_raw (
    CustomerID VARCHAR(20),
    Recency INT,
    Frequency INT,
    Monetary DECIMAL(10,2)
);

LOAD DATA LOCAL INFILE 'C:/Users/swathikanike/Downloads/E-commerce,Intelligence/rfm_raw.csv'
INTO TABLE rfm_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
SET autocommit = 1;

SELECT * FROM rfm_raw;

-- Query 1 Monthly Revenue & Growth

SELECT
    Year,
    Month,
    total_revenue,
    total_orders,
    unique_customers,
    ROUND(total_revenue / total_orders, 2) AS avg_order_value,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY Year, Month))
        / LAG(total_revenue) OVER (ORDER BY Year, Month) * 100
    , 2) AS mom_growth_pct
FROM (
    SELECT
        Year,
        Month,
        SUM(Revenue) AS total_revenue,
        COUNT(DISTINCT Invoice) AS total_orders,
        COUNT(DISTINCT `Customer ID`) AS unique_customers
    FROM retail_transactions
    GROUP BY Year, Month
) t
ORDER BY Year, Month;

-- query 2 RFM scoring and segmentation

WITH rfm_scores AS (
    SELECT
        CustomerID,
        Recency,
        Frequency,
        Monetary,
        NTILE(4) OVER (ORDER BY Recency ASC)    AS R_Score,
        NTILE(4) OVER (ORDER BY Frequency DESC) AS F_Score,
        NTILE(4) OVER (ORDER BY Monetary DESC)  AS M_Score
    FROM rfm_raw
),
rfm_segments AS (
    SELECT *,
        CONCAT(R_Score, F_Score, M_Score) AS RFM_Code,
        (R_Score + F_Score + M_Score)     AS RFM_Total,
        CASE
            WHEN R_Score = 4 AND F_Score >= 3 THEN 'Champions'
            WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers'
            WHEN R_Score >= 3 AND F_Score <= 2 THEN 'Potential Loyalists'
            WHEN R_Score = 2 AND F_Score >= 3 THEN 'At Risk'
            WHEN R_Score <= 2 AND F_Score >= 3 THEN 'Cant Lose Them'
            WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Hibernating'
            ELSE 'New Customers'
        END AS Segment
    FROM rfm_scores
)
SELECT
    Segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(Recency), 0) AS avg_recency_days,
    ROUND(AVG(Frequency), 1) AS avg_orders,
    ROUND(AVG(Monetary), 2) AS avg_revenue,
    ROUND(SUM(Monetary), 2) AS total_segment_revenue
FROM rfm_segments
GROUP BY Segment
ORDER BY total_segment_revenue DESC;

-- query 3 cohort retention and analysis
WITH first_purchase AS (
    SELECT
        `Customer ID`,
        DATE_FORMAT(MIN(InvoiceDate), '%Y-%m') AS cohort_month
    FROM retail_transactions
    GROUP BY `Customer ID`
),
customer_activity AS (
    SELECT
        t.`Customer ID`,
        fp.cohort_month,
        DATE_FORMAT(t.InvoiceDate, '%Y-%m') AS activity_month
    FROM retail_transactions t
    JOIN first_purchase fp 
        ON t.`Customer ID` = fp.`Customer ID`
),
cohort_size AS (
    SELECT 
        cohort_month, 
        COUNT(DISTINCT `Customer ID`) AS cohort_customers
    FROM first_purchase
    GROUP BY cohort_month
),
retention AS (
    SELECT
        ca.cohort_month,
        ca.activity_month,
        COUNT(DISTINCT ca.`Customer ID`) AS active_customers
    FROM customer_activity ca
    GROUP BY ca.cohort_month, ca.activity_month
)
SELECT
    r.cohort_month,
    r.activity_month,
    r.active_customers,
    cs.cohort_customers,
    ROUND(r.active_customers / cs.cohort_customers * 100, 1) AS retention_rate_pct
FROM retention r
JOIN cohort_size cs 
    ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.activity_month;

-- query 4 top products and category performances

SELECT
    Description AS product,
    COUNT(DISTINCT Invoice) AS total_orders,
    SUM(Quantity) AS total_units_sold,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(AVG(Price), 2) AS avg_price,
    ROUND(
        SUM(Revenue) * 100 / SUM(SUM(Revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM retail_transactions
GROUP BY Description
ORDER BY total_revenue DESC
LIMIT 20;