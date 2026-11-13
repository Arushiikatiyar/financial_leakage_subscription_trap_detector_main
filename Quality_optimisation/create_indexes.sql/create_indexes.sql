--Check for duplicate transaction reference numbers--

SELECT
    reference_number,
    COUNT(*) AS occurrences
FROM transactions
GROUP BY reference_number
HAVING COUNT(*) > 1;
--Create indexes for frequently searched columns--

-- Transactions table indexes

CREATE INDEX IF NOT EXISTS idx_transactions_account_id
ON transactions(account_id);

CREATE INDEX IF NOT EXISTS idx_transactions_merchant_id
ON transactions(merchant_id);

CREATE INDEX IF NOT EXISTS idx_transactions_subscription_id
ON transactions(subscription_id);

CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date
ON transactions(transaction_date);


-- Subscriptions table indexes

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id
ON subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_merchant_id
ON subscriptions(merchant_id);


-- Subscription usage table index

CREATE INDEX IF NOT EXISTS idx_subscription_usage_subscription_id
ON subscription_usage(subscription_id);


-- Price history table index

CREATE INDEX IF NOT EXISTS idx_price_history_subscription_id
ON price_history(subscription_id);


-- Disputes table index

CREATE INDEX IF NOT EXISTS idx_disputes_transaction_id
ON disputes(transaction_id);
--Update table statistics--
ANALYZE;
