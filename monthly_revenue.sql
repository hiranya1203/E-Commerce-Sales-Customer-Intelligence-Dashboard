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
