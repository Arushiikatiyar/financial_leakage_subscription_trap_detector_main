--Check whether all tables have records--

SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'merchants', COUNT(*) FROM merchants
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL
SELECT 'disputes', COUNT(*) FROM disputes
UNION ALL
SELECT 'price_history', COUNT(*) FROM price_history
UNION ALL
SELECT 'subscription_usage', COUNT(*) FROM subscription_usage
ORDER BY table_name;
--Check for customers without accounts--

SELECT
    u.user_id,
    u.first_name,
    u.last_name
FROM users u
LEFT JOIN accounts a
    ON u.user_id = a.user_id
WHERE a.account_id IS NULL;
--Check for transactions without a valid account--

SELECT
    t.transaction_id,
    t.account_id
FROM transactions t
LEFT JOIN accounts a
    ON t.account_id = a.account_id
WHERE a.account_id IS NULL;
--Check for subscriptions without recorded usage--

SELECT
    s.subscription_id,
    s.user_id,
    s.status,
    s.monthly_price
FROM subscriptions s
LEFT JOIN subscription_usage su
    ON s.subscription_id = su.subscription_id
WHERE su.usage_id IS NULL;
--Check for invalid transaction amounts--

SELECT *
FROM transactions
WHERE amount <= 0;
--Check for duplicate transaction reference numbers--

SELECT
    reference_number,
    COUNT(*) AS occurrences
FROM transactions
GROUP BY reference_number
HAVING COUNT(*) > 1;