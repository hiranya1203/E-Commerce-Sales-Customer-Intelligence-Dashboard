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
