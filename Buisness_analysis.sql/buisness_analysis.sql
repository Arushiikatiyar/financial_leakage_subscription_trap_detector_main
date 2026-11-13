-- TOTAL EXPENDITURE BY EACH CUSTOMER --

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    SUM(t.amount) AS total_expenditure

FROM users u

JOIN accounts a
    ON u.user_id = a.user_id

JOIN transactions t
    ON a.account_id = t.account_id

WHERE t.transaction_type = 'DEBIT'
AND t.payment_status = 'SUCCESS'

GROUP BY
    u.user_id,
    u.first_name,
    u.last_name

ORDER BY total_expenditure DESC;

--Identify the top 10 highest-spending customers--
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    SUM(t.amount) AS total_expenditure

FROM users u

JOIN accounts a
    ON u.user_id = a.user_id

JOIN transactions t
    ON a.account_id = t.account_id

WHERE t.transaction_type = 'DEBIT'
AND t.payment_status = 'SUCCESS'

GROUP BY
    u.user_id,
    u.first_name,
    u.last_name

ORDER BY total_expenditure DESC

LIMIT 10;

--CALCULATE TOTAL SPENDING BY CITY--
SELECT
    u.city,
    COUNT(DISTINCT u.user_id) AS total_customers,
    SUM(t.amount) AS total_expenditure,
    ROUND(AVG(t.amount), 2) AS average_transaction

FROM users u

JOIN accounts a
    ON u.user_id = a.user_id

JOIN transactions t
    ON a.account_id = t.account_id

WHERE t.transaction_type = 'DEBIT'
AND t.payment_status = 'SUCCESS'

GROUP BY u.city

ORDER BY total_expenditure DESC;
--Classify customers based on expenditure--
SELECT
    u.user_id,
    u.first_name,
    u.last_name,

    SUM(t.amount) AS total_expenditure,

    CASE
        WHEN SUM(t.amount) > 50000
            THEN 'HIGH SPENDER'

        WHEN SUM(t.amount) >= 20000
            THEN 'MEDIUM SPENDER'

        ELSE 'LOW SPENDER'
    END AS spending_category

FROM users u

JOIN accounts a
    ON u.user_id = a.user_id

JOIN transactions t
    ON a.account_id = t.account_id

WHERE t.transaction_type = 'DEBIT'
AND t.payment_status = 'SUCCESS'

GROUP BY
    u.user_id,
    u.first_name,
    u.last_name

ORDER BY total_expenditure DESC;

--Find active subscriptions with no recorded usage--
SELECT
    s.subscription_id,
    u.user_id,
    u.first_name,
    u.last_name,
    m.merchant_name,
    s.monthly_price,
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
)

ORDER BY s.monthly_price DESC;
--Calculate potential monthly subscription leakage--
SELECT
    COUNT(*) AS unused_active_subscriptions,

    SUM(s.monthly_price)
        AS potential_monthly_leakage,

    SUM(s.monthly_price) * 12
        AS potential_annual_leakage

FROM subscriptions s

WHERE s.status = 'ACTIVE'

AND NOT EXISTS (
    SELECT 1
    FROM subscription_usage su
    WHERE su.subscription_id = s.subscription_id
);
--Find customers with more than three active subscriptions--
SELECT
    u.user_id,
    u.first_name,
    u.last_name,

    COUNT(s.subscription_id)
        AS active_subscription_count,

    SUM(s.monthly_price)
        AS monthly_subscription_cost

FROM users u

JOIN subscriptions s
    ON u.user_id = s.user_id

WHERE s.status = 'ACTIVE'

GROUP BY
    u.user_id,
    u.first_name,
    u.last_name

HAVING COUNT(s.subscription_id) > 3

ORDER BY monthly_subscription_cost DESC;

--Find subscriptions that are more expensive than the average--
SELECT
    s.subscription_id,
    u.first_name,
    m.merchant_name,
    s.monthly_price

FROM subscriptions s

JOIN users u
    ON s.user_id = u.user_id

JOIN merchants m
    ON s.merchant_id = m.merchant_id

WHERE s.monthly_price > (
    SELECT AVG(monthly_price)
    FROM subscriptions
)

ORDER BY s.monthly_price DESC;

--Find potential duplicate transactions--

SELECT
    t1.transaction_id AS transaction_1,
    t2.transaction_id AS transaction_2,
    t1.account_id,
    m.merchant_name,
    t1.amount,
    t1.transaction_date AS first_transaction_time,
    t2.transaction_date AS second_transaction_time,
    ABS(
        EXTRACT(
            EPOCH FROM (t2.transaction_date - t1.transaction_date)
        )
    ) AS time_difference_seconds
FROM transactions t1
JOIN transactions t2
    ON t1.account_id = t2.account_id
    AND t1.merchant_id = t2.merchant_id
    AND t1.amount = t2.amount
    AND t1.transaction_id < t2.transaction_id
JOIN merchants m
    ON t1.merchant_id = m.merchant_id
WHERE t1.transaction_type = 'DEBIT'
    AND t2.transaction_type = 'DEBIT'
    AND t1.payment_status = 'SUCCESS'
    AND t2.payment_status = 'SUCCESS'
    AND ABS(
        EXTRACT(
            EPOCH FROM (t2.transaction_date - t1.transaction_date)
        )
    ) <= 120
ORDER BY time_difference_seconds;
--Count potential duplicate pairs--

SELECT
    COUNT(*) AS potential_duplicate_pairs
FROM transactions t1
JOIN transactions t2
    ON t1.account_id = t2.account_id
    AND t1.merchant_id = t2.merchant_id
    AND t1.amount = t2.amount
    AND t1.transaction_id < t2.transaction_id
WHERE t1.transaction_type = 'DEBIT'
    AND t2.transaction_type = 'DEBIT'
    AND t1.payment_status = 'SUCCESS'
    AND t2.payment_status = 'SUCCESS'
    AND ABS(
        EXTRACT(
            EPOCH FROM (t2.transaction_date - t1.transaction_date)
        )
    ) <= 120;

--Calculate the potential amount involved--

SELECT
    COUNT(*) AS potential_duplicate_pairs,
    SUM(t2.amount) AS potential_duplicate_amount
FROM transactions t1
JOIN transactions t2
    ON t1.account_id = t2.account_id
    AND t1.merchant_id = t2.merchant_id
    AND t1.amount = t2.amount
    AND t1.transaction_id < t2.transaction_id
WHERE t1.transaction_type = 'DEBIT'
    AND t2.transaction_type = 'DEBIT'
    AND t1.payment_status = 'SUCCESS'
    AND t2.payment_status = 'SUCCESS'
    AND ABS(
        EXTRACT(
            EPOCH FROM (t2.transaction_date - t1.transaction_date)
        )
    ) <= 120;

--Calculate the price increase--

SELECT
    s.subscription_id,
    u.first_name,
    u.last_name,
    m.merchant_name,
    ph.old_price,
    ph.new_price,
    ph.new_price - ph.old_price AS price_increase,
    ROUND(
        (
            (ph.new_price - ph.old_price)
            / NULLIF(ph.old_price, 0)
        ) * 100,
        2
    ) AS percentage_increase,
    ph.effective_date
FROM price_history ph
JOIN subscriptions s
    ON ph.subscription_id = s.subscription_id
JOIN users u
    ON s.user_id = u.user_id
JOIN merchants m
    ON s.merchant_id = m.merchant_id
ORDER BY percentage_increase DESC;
--Find subscriptions with a price increase greater than 20%--

SELECT
    s.subscription_id,
    m.merchant_name,
    ph.old_price,
    ph.new_price,
    ROUND(
        ((ph.new_price - ph.old_price)
        / NULLIF(ph.old_price, 0)) * 100,
        2
    ) AS percentage_increase
FROM price_history ph
JOIN subscriptions s
    ON ph.subscription_id = s.subscription_id
JOIN merchants m
    ON s.merchant_id = m.merchant_id
WHERE ph.new_price > ph.old_price
    AND (
        (ph.new_price - ph.old_price)
        / NULLIF(ph.old_price, 0)
    ) * 100 > 20
ORDER BY percentage_increase DESC;
--Find the subscriptions with the highest price increases--

SELECT
    s.subscription_id,
    m.merchant_name,
    ph.old_price,
    ph.new_price,
    ph.new_price - ph.old_price AS increase_amount
FROM price_history ph
JOIN subscriptions s
    ON ph.subscription_id = s.subscription_id
JOIN merchants m
    ON s.merchant_id = m.merchant_id
ORDER BY increase_amount DESC
LIMIT 10;
--Calculate the total price increase across subscriptions--

SELECT
    COUNT(*) AS subscriptions_with_price_history,
    SUM(ph.old_price) AS total_old_monthly_price,
    SUM(ph.new_price) AS total_new_monthly_price,
    SUM(ph.new_price - ph.old_price) AS total_monthly_increase
FROM price_history ph
WHERE ph.new_price > ph.old_price;

--Find the top 10 merchants by total spending--

SELECT
    m.merchant_id,
    m.merchant_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_revenue,
    ROUND(AVG(t.amount), 2) AS average_transaction_amount
FROM merchants m
JOIN transactions t
    ON m.merchant_id = t.merchant_id
WHERE t.transaction_type = 'DEBIT'
    AND t.payment_status = 'SUCCESS'
GROUP BY
    m.merchant_id,
    m.merchant_name
ORDER BY total_revenue DESC
LIMIT 10;
--Calculate category-wise spending--

SELECT
    c.category_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_spending,
    ROUND(AVG(t.amount), 2) AS average_transaction_amount
FROM transactions t
JOIN merchants m
    ON t.merchant_id = m.merchant_id
JOIN categories c
    ON m.category_id = c.category_id
WHERE t.transaction_type = 'DEBIT'
    AND t.payment_status = 'SUCCESS'
GROUP BY c.category_id, c.category_name
ORDER BY total_spending DESC;
--Find the most expensive transaction for each merchant--

SELECT
    m.merchant_name,
    MAX(t.amount) AS highest_transaction
FROM merchants m
JOIN transactions t
    ON m.merchant_id = t.merchant_id
WHERE t.transaction_type = 'DEBIT'
    AND t.payment_status = 'SUCCESS'
GROUP BY m.merchant_id, m.merchant_name
ORDER BY highest_transaction DESC;
--Find merchants with more than 100 successful transactions--

SELECT
    m.merchant_name,
    COUNT(t.transaction_id) AS successful_transactions,
    SUM(t.amount) AS total_revenue
FROM merchants m
JOIN transactions t
    ON m.merchant_id = t.merchant_id
WHERE t.payment_status = 'SUCCESS'
    AND t.transaction_type = 'DEBIT'
GROUP BY m.merchant_id, m.merchant_name
HAVING COUNT(t.transaction_id) > 100
ORDER BY successful_transactions DESC;
--Display all disputed transactions with customer and merchant information--

SELECT
    d.dispute_id,
    d.dispute_reason,
    d.dispute_status,
    d.dispute_date,
    t.transaction_id,
    t.amount,
    t.transaction_date,
    u.first_name,
    u.last_name,
    m.merchant_name
FROM disputes d
JOIN transactions t
    ON d.transaction_id = t.transaction_id
JOIN accounts a
    ON t.account_id = a.account_id
JOIN users u
    ON a.user_id = u.user_id
JOIN merchants m
    ON t.merchant_id = m.merchant_id
ORDER BY d.dispute_date DESC;
--Count disputes by status--

SELECT
    dispute_status,
    COUNT(*) AS total_disputes
FROM disputes
GROUP BY dispute_status
ORDER BY total_disputes DESC;
--Calculate the total disputed amount--

SELECT
    COUNT(d.dispute_id) AS total_disputes,
    SUM(t.amount) AS total_disputed_amount,
    ROUND(AVG(t.amount), 2) AS average_disputed_amount
FROM disputes d
JOIN transactions t
    ON d.transaction_id = t.transaction_id;
--Find merchants with the most disputes--

SELECT
    m.merchant_name,
    COUNT(d.dispute_id) AS total_disputes,
    SUM(t.amount) AS disputed_transaction_amount
FROM disputes d
JOIN transactions t
    ON d.transaction_id = t.transaction_id
JOIN merchants m
    ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_id, m.merchant_name
ORDER BY total_disputes DESC;
--Identify customers with multiple disputes--

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(d.dispute_id) AS total_disputes,
    SUM(t.amount) AS total_disputed_amount
FROM users u
JOIN accounts a
    ON u.user_id = a.user_id
JOIN transactions t
    ON a.account_id = t.account_id
JOIN disputes d
    ON t.transaction_id = d.transaction_id
GROUP BY u.user_id, u.first_name, u.last_name
HAVING COUNT(d.dispute_id) > 1
ORDER BY total_disputes DESC;
--VERIFICATION--

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
SELECT 'subscription_usage', COUNT(*) FROM subscription_usage;
