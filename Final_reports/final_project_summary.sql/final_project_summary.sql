--Overall project database summary--
SELECT
    (SELECT COUNT(*) FROM users) AS total_customers,

    (SELECT COUNT(*) FROM accounts) AS total_accounts,

    (SELECT COUNT(*) FROM merchants) AS total_merchants,

    (SELECT COUNT(*) FROM transactions) AS total_transactions,

    (SELECT COUNT(*) FROM subscriptions) AS total_subscriptions,

    (SELECT COUNT(*) FROM disputes) AS total_disputes;
--Total potential subscription leakage--
SELECT
    COUNT(*) AS subscriptions_without_recorded_usage,
    COALESCE(SUM(monthly_price), 0)
        AS potential_monthly_subscription_leakage
FROM subscriptions s
WHERE status = 'ACTIVE'
AND NOT EXISTS (
    SELECT 1
    FROM subscription_usage su
    WHERE su.subscription_id = s.subscription_id
);
--Potential duplicate payment summary--
SELECT
    COUNT(*) AS potential_duplicate_pairs,
    COALESCE(SUM(t2.amount), 0)
        AS potential_duplicate_amount
FROM transactions t1
JOIN transactions t2
    ON t1.account_id = t2.account_id
    AND t1.merchant_id = t2.merchant_id
    AND t1.amount = t2.amount
    AND t1.transaction_id < t2.transaction_id
    AND ABS(
        EXTRACT(EPOCH FROM (
            t2.transaction_date - t1.transaction_date
        ))
    ) <= 120
WHERE t1.transaction_type = 'DEBIT'
    AND t2.transaction_type = 'DEBIT'
    AND t1.payment_status = 'SUCCESS'
    AND t2.payment_status = 'SUCCESS';
--Subscription price increase summary--
SELECT
    COUNT(*) AS total_price_increases,
    COALESCE(SUM(new_price - old_price), 0)
        AS total_recorded_price_increase,
    COALESCE(AVG(new_price - old_price), 0)
        AS average_price_increase
FROM price_history
WHERE new_price > old_price;
--Dispute summary--
SELECT
    dispute_status,
    COUNT(*) AS total_disputes
FROM disputes
GROUP BY dispute_status
ORDER BY total_disputes DESC;