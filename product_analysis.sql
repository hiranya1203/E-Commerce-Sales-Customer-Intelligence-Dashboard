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