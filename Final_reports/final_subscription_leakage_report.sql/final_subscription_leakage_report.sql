--Detailed subscription leakage report--

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    m.merchant_name,
    c.category_name,
    s.subscription_id,
    s.monthly_price,
    s.monthly_price * 12 AS estimated_annual_cost,
    s.start_date,
    s.next_billing_date
FROM subscriptions s
JOIN users u
    ON s.user_id = u.user_id
JOIN merchants m
    ON s.merchant_id = m.merchant_id
JOIN categories c
    ON m.category_id = c.category_id
WHERE s.status = 'ACTIVE'
    AND NOT EXISTS (
        SELECT 1
        FROM subscription_usage su
        WHERE su.subscription_id = s.subscription_id
    )
ORDER BY s.monthly_price DESC;
--Overall potential subscription leakage--

SELECT
    COUNT(*) AS unused_active_subscription_count,
    COUNT(DISTINCT user_id) AS affected_customers,
    SUM(monthly_price) AS potential_monthly_leakage,
    SUM(monthly_price * 12) AS potential_annual_leakage,
    ROUND(AVG(monthly_price), 2) AS average_monthly_subscription_price
FROM subscription_leakage_view;
--Find merchants contributing the most potential leakage--

SELECT
    merchant_name,
    COUNT(*) AS unused_subscription_count,
    SUM(monthly_price) AS potential_monthly_leakage,
    SUM(annual_cost) AS potential_annual_leakage
FROM subscription_leakage_view
GROUP BY merchant_name
ORDER BY potential_monthly_leakage DESC;
