--Detailed potential duplicate payment report--

SELECT
    t1.transaction_id AS original_transaction_id,
    t2.transaction_id AS possible_duplicate_id,
    u.user_id,
    u.first_name,
    u.last_name,
    m.merchant_name,
    t1.amount,
    t1.transaction_date AS original_transaction_time,
    t2.transaction_date AS possible_duplicate_time,
    ROUND(
        ABS(EXTRACT(EPOCH FROM (
            t2.transaction_date - t1.transaction_date
        ))),
        2
    ) AS time_difference_seconds
FROM transactions t1
JOIN transactions t2
    ON t1.account_id = t2.account_id
    AND t1.merchant_id = t2.merchant_id
    AND t1.amount = t2.amount
    AND t1.transaction_id < t2.transaction_id
JOIN accounts a
    ON t1.account_id = a.account_id
JOIN users u
    ON a.user_id = u.user_id
JOIN merchants m
    ON t1.merchant_id = m.merchant_id
WHERE t1.transaction_type = 'DEBIT'
    AND t2.transaction_type = 'DEBIT'
    AND t1.payment_status = 'SUCCESS'
    AND t2.payment_status = 'SUCCESS'
    AND ABS(EXTRACT(EPOCH FROM (
        t2.transaction_date - t1.transaction_date
    ))) <= 120
ORDER BY time_difference_seconds;
--Summarise potential duplicate payments--

WITH duplicate_pairs AS (
    SELECT
        t1.transaction_id AS original_transaction_id,
        t2.transaction_id AS possible_duplicate_id,
        t2.amount AS possible_duplicate_amount
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
        AND ABS(EXTRACT(EPOCH FROM (
            t2.transaction_date - t1.transaction_date
        ))) <= 120
)
SELECT
    COUNT(*) AS potential_duplicate_pairs,
    SUM(possible_duplicate_amount) AS potential_duplicate_amount
FROM duplicate_pairs;
