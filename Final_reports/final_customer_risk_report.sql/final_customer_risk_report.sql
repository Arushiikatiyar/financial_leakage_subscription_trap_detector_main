--Consolidated customer risk report--

WITH transaction_summary AS (
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
subscription_summary AS (
    SELECT
        user_id,
        COUNT(*) AS active_subscriptions,
        SUM(monthly_price) AS monthly_subscription_cost
    FROM subscriptions
    WHERE status = 'ACTIVE'
    GROUP BY user_id
),
unused_subscription_summary AS (
    SELECT
        s.user_id,
        COUNT(*) AS subscriptions_without_usage,
        SUM(s.monthly_price) AS potential_monthly_leakage
    FROM subscriptions s
    WHERE s.status = 'ACTIVE'
        AND NOT EXISTS (
            SELECT 1
            FROM subscription_usage su
            WHERE su.subscription_id = s.subscription_id
        )
    GROUP BY s.user_id
),
dispute_summary AS (
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
    COALESCE(ts.total_transactions, 0) AS total_transactions,
    COALESCE(ts.total_spending, 0) AS total_spending,
    COALESCE(ss.active_subscriptions, 0) AS active_subscriptions,
    COALESCE(ss.monthly_subscription_cost, 0) AS monthly_subscription_cost,
    COALESCE(us.subscriptions_without_usage, 0) AS subscriptions_without_usage,
    COALESCE(us.potential_monthly_leakage, 0) AS potential_monthly_leakage,
    COALESCE(ds.total_disputes, 0) AS total_disputes
FROM users u
LEFT JOIN transaction_summary ts
    ON u.user_id = ts.user_id
LEFT JOIN subscription_summary ss
    ON u.user_id = ss.user_id
LEFT JOIN unused_subscription_summary us
    ON u.user_id = us.user_id
LEFT JOIN dispute_summary ds
    ON u.user_id = ds.user_id
ORDER BY
    potential_monthly_leakage DESC,
    total_disputes DESC,
    total_spending DESC;
--Classify customers for further review--

WITH customer_disputes AS (
    SELECT
        a.user_id,
        COUNT(DISTINCT d.dispute_id) AS total_disputes
    FROM accounts a
    JOIN transactions t
        ON a.account_id = t.account_id
    JOIN disputes d
        ON t.transaction_id = d.transaction_id
    GROUP BY a.user_id
),
customer_leakage AS (
    SELECT
        s.user_id,
        SUM(s.monthly_price) AS potential_monthly_leakage
    FROM subscriptions s
    WHERE s.status = 'ACTIVE'
        AND NOT EXISTS (
            SELECT 1
            FROM subscription_usage su
            WHERE su.subscription_id = s.subscription_id
        )
    GROUP BY s.user_id
)
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COALESCE(cd.total_disputes, 0) AS total_disputes,
    COALESCE(cl.potential_monthly_leakage, 0) AS potential_monthly_leakage,
    CASE
        WHEN COALESCE(cd.total_disputes, 0) >= 3
             AND COALESCE(cl.potential_monthly_leakage, 0) >= 1000
            THEN 'PRIORITY REVIEW'
        WHEN COALESCE(cd.total_disputes, 0) >= 2
            THEN 'DISPUTE REVIEW'
        WHEN COALESCE(cl.potential_monthly_leakage, 0) >= 1000
            THEN 'SUBSCRIPTION REVIEW'
        ELSE 'NORMAL REVIEW'
    END AS review_category
FROM users u
LEFT JOIN customer_disputes cd
    ON u.user_id = cd.user_id
LEFT JOIN customer_leakage cl
    ON u.user_id = cl.user_id
ORDER BY
    CASE
        WHEN COALESCE(cd.total_disputes, 0) >= 3
             AND COALESCE(cl.potential_monthly_leakage, 0) >= 1000 THEN 1
        WHEN COALESCE(cd.total_disputes, 0) >= 2 THEN 2
        WHEN COALESCE(cl.potential_monthly_leakage, 0) >= 1000 THEN 3
        ELSE 4
    END;

