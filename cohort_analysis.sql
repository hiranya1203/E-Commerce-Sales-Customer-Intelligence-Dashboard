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
