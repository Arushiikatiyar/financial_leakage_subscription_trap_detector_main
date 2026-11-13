--Overall financial metrics--
SELECT
    (SELECT COUNT(*)
     FROM users) AS total_customers,

    (SELECT COUNT(*)
     FROM transactions
     WHERE transaction_type = 'DEBIT'
       AND payment_status = 'SUCCESS')
       AS successful_debit_transactions,

    (SELECT COALESCE(SUM(amount), 0)
     FROM transactions
     WHERE transaction_type = 'DEBIT'
       AND payment_status = 'SUCCESS')
       AS total_successful_debit_spending,

    (SELECT COUNT(*)
     FROM subscriptions
     WHERE status = 'ACTIVE') AS active_subscriptions,

    (SELECT COALESCE(SUM(monthly_price), 0)
     FROM subscriptions
     WHERE status = 'ACTIVE')
       AS active_monthly_subscription_value,

    (SELECT COUNT(*)
     FROM disputes) AS total_disputes,

    (SELECT COUNT(*)
     FROM price_history
     WHERE new_price > old_price)
       AS recorded_price_increases;
--Monthly spending trends--
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') AS spending_month,
    COUNT(*) AS successful_debit_count,
    SUM(amount) AS total_spending
FROM transactions
WHERE transaction_type = 'DEBIT'
    AND payment_status = 'SUCCESS'
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY spending_month;
--Subscription status breakdown--
SELECT
    status,
    COUNT(*) AS subscription_count,
    SUM(monthly_price) AS total_monthly_price
FROM subscriptions
GROUP BY status
ORDER BY subscription_count DESC;
--Dispute status breakdown--
SELECT
    dispute_status,
    COUNT(*) AS dispute_count
FROM disputes
GROUP BY dispute_status
ORDER BY dispute_count DESC;