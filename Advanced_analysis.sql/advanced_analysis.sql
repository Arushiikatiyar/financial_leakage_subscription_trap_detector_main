--Identify customers with unusually high spending--

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    SUM(t.amount) AS total_spending,
    COUNT(t.transaction_id) AS transaction_count,
    CASE
        WHEN SUM(t.amount) >= 100000 THEN 'VERY HIGH'
        WHEN SUM(t.amount) >= 50000 THEN 'HIGH'
        WHEN SUM(t.amount) >= 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS spending_category
FROM users u
JOIN accounts a
    ON u.user_id = a.user_id
JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.transaction_type = 'DEBIT'
    AND t.payment_status = 'SUCCESS'
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_spending DESC;
--Find customers whose spending is above the average customer spending--

SELECT
    customer_spending.user_id,
    customer_spending.first_name,
    customer_spending.last_name,
    customer_spending.total_spending
FROM (
    SELECT
        u.user_id,
        u.first_name,
        u.last_name,
        SUM(t.amount) AS total_spending
    FROM users u
    JOIN accounts a
        ON u.user_id = a.user_id
    JOIN transactions t
        ON a.account_id = t.account_id
    WHERE t.transaction_type = 'DEBIT'
        AND t.payment_status = 'SUCCESS'
    GROUP BY u.user_id, u.first_name, u.last_name
) AS customer_spending
WHERE customer_spending.total_spending > (
    SELECT AVG(total_spending)
    FROM (
        SELECT
            a.user_id,
            SUM(t.amount) AS total_spending
        FROM accounts a
        JOIN transactions t
            ON a.account_id = t.account_id
        WHERE t.transaction_type = 'DEBIT'
            AND t.payment_status = 'SUCCESS'
        GROUP BY a.user_id
    ) AS average_spending
)
ORDER BY customer_spending.total_spending DESC;
--Calculate each customer's total active subscription cost--

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(s.subscription_id) AS active_subscription_count,
    SUM(s.monthly_price) AS total_monthly_subscription_cost,
    SUM(s.monthly_price) * 12 AS estimated_annual_subscription_cost
FROM users u
JOIN subscriptions s
    ON u.user_id = s.user_id
WHERE s.status = 'ACTIVE'
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_monthly_subscription_cost DESC;
--Find customers with high subscription costs but no recorded usage--

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(s.subscription_id) AS subscriptions_without_recorded_usage,
    SUM(s.monthly_price) AS potential_monthly_leakage
FROM users u
JOIN subscriptions s
    ON u.user_id = s.user_id
WHERE s.status = 'ACTIVE'
    AND NOT EXISTS (
        SELECT 1
        FROM subscription_usage su
        WHERE su.subscription_id = s.subscription_id
    )
GROUP BY u.user_id, u.first_name, u.last_name
HAVING SUM(s.monthly_price) > 1000
ORDER BY potential_monthly_leakage DESC;
--Calculate total spending month by month--

SELECT
    DATE_TRUNC('month', transaction_date)::DATE AS spending_month,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_spending,
    ROUND(AVG(amount), 2) AS average_transaction_amount
FROM transactions
WHERE transaction_type = 'DEBIT'
    AND payment_status = 'SUCCESS'
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY spending_month;
--Compare spending across months--

WITH monthly_spending AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::DATE AS spending_month,
        SUM(amount) AS total_spending
    FROM transactions
    WHERE transaction_type = 'DEBIT'
        AND payment_status = 'SUCCESS'
    GROUP BY DATE_TRUNC('month', transaction_date)
)
SELECT
    spending_month,
    total_spending,
    LAG(total_spending) OVER (
        ORDER BY spending_month
    ) AS previous_month_spending,
    total_spending - LAG(total_spending) OVER (
        ORDER BY spending_month
    ) AS spending_change
FROM monthly_spending
ORDER BY spending_month;
--Calculate the percentage change in monthly spending--

WITH monthly_spending AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::DATE AS spending_month,
        SUM(amount) AS total_spending
    FROM transactions
    WHERE transaction_type = 'DEBIT'
        AND payment_status = 'SUCCESS'
    GROUP BY DATE_TRUNC('month', transaction_date)
),
spending_comparison AS (
    SELECT
        spending_month,
        total_spending,
        LAG(total_spending) OVER (
            ORDER BY spending_month
        ) AS previous_month_spending
    FROM monthly_spending
)
SELECT
    spending_month,
    total_spending,
    previous_month_spending,
    ROUND(
        (
            (total_spending - previous_month_spending)
            / NULLIF(previous_month_spending, 0)
        ) * 100,
        2
    ) AS percentage_change
FROM spending_comparison
ORDER BY spending_month;
--Build the consolidated report--

WITH customer_transactions AS (
    SELECT
        a.user_id,
        COUNT(t.transaction_id) AS total_transactions,
        COALESCE(SUM(t.amount), 0) AS total_spending
    FROM accounts a
    LEFT JOIN transactions t
        ON a.account_id = t.account_id
        AND t.transaction_type = 'DEBIT'
        AND t.payment_status = 'SUCCESS'
    GROUP BY a.user_id
),
customer_subscriptions AS (
    SELECT
        user_id,
        COUNT(*) AS active_subscriptions,
        COALESCE(SUM(monthly_price), 0) AS monthly_subscription_cost
    FROM subscriptions
    WHERE status = 'ACTIVE'
    GROUP BY user_id
),
customer_disputes AS (
    SELECT
        a.user_id,
        COUNT(d.dispute_id) AS total_disputes
    FROM accounts a
    JOIN transactions t
        ON a.account_id = t.account_id
    JOIN disputes d
        ON t.transaction_id = d.transaction_id
    GROUP BY a.user_id
)
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COALESCE(ct.total_transactions, 0) AS total_transactions,
    COALESCE(ct.total_spending, 0) AS total_spending,
    COALESCE(cs.active_subscriptions, 0) AS active_subscriptions,
    COALESCE(cs.monthly_subscription_cost, 0) AS monthly_subscription_cost,
    COALESCE(cd.total_disputes, 0) AS total_disputes
FROM users u
LEFT JOIN customer_transactions ct
    ON u.user_id = ct.user_id
LEFT JOIN customer_subscriptions cs
    ON u.user_id = cs.user_id
LEFT JOIN customer_disputes cd
    ON u.user_id = cd.user_id
ORDER BY total_spending DESC;
--Create a customer spending view--

CREATE OR REPLACE VIEW customer_spending_view AS
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(SUM(t.amount), 0) AS total_spending
FROM users u
LEFT JOIN accounts a
    ON u.user_id = a.user_id
LEFT JOIN transactions t
    ON a.account_id = t.account_id
    AND t.transaction_type = 'DEBIT'
    AND t.payment_status = 'SUCCESS'
GROUP BY u.user_id, u.first_name, u.last_name;
--TO USE THIS VIEW --

SELECT *
FROM customer_spending_view
ORDER BY total_spending DESC;
--LET'S FILTER IT--

SELECT *
FROM customer_spending_view
WHERE total_spending > 50000
ORDER BY total_spending DESC;
--Create a subscription leakage view--

CREATE OR REPLACE VIEW subscription_leakage_view AS
SELECT
    s.subscription_id,
    u.user_id,
    u.first_name,
    u.last_name,
    m.merchant_name,
    s.monthly_price,
    s.monthly_price * 12 AS annual_cost,
    s.status
FROM subscriptions s
JOIN users u
    ON s.user_id = u.user_id
JOIN merchants m
    ON s.merchant_id = m.merchant_id
WHERE s.status = 'ACTIVE'
    AND NOT EXISTS (
        SELECT 1
        FROM subscription_usage su
        WHERE su.subscription_id = s.subscription_id
    );
--TO USE IT--

SELECT *
FROM subscription_leakage_view
ORDER BY monthly_price DESC;
--CALCULATE THE TOTAL POTENTIAL LEAKAGE--

SELECT
    COUNT(*) AS potentially_unused_subscriptions,
    SUM(monthly_price) AS monthly_leakage,
    SUM(annual_cost) AS annual_leakage
FROM subscription_leakage_view;
--Create a merchant performance view--

CREATE OR REPLACE VIEW merchant_performance_view AS
SELECT
    m.merchant_id,
    m.merchant_name,
    c.category_name,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(SUM(t.amount), 0) AS total_revenue,
    ROUND(AVG(t.amount), 2) AS average_transaction_amount
FROM merchants m
JOIN categories c
    ON m.category_id = c.category_id
LEFT JOIN transactions t
    ON m.merchant_id = t.merchant_id
    AND t.transaction_type = 'DEBIT'
    AND t.payment_status = 'SUCCESS'
GROUP BY
    m.merchant_id,
    m.merchant_name,
    c.category_name;
--TO USE IT--

SELECT *
FROM merchant_performance_view
ORDER BY total_revenue DESC;

