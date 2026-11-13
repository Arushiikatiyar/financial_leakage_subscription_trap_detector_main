INSERT INTO categories
(category_name, description)
VALUES
('Entertainment', 'Movies, music and streaming services'),
('Food', 'Restaurants and food delivery'),
('Shopping', 'Online and offline shopping'),
('Travel', 'Flights, hotels and transportation'),
('Healthcare', 'Medical and healthcare expenses'),
('Utilities', 'Electricity, internet and other bills'),
('Education', 'Online courses and educational services'),
('Fitness', 'Gyms and fitness subscriptions'),
('Technology', 'Software and cloud services'),
('Finance', 'Financial services and banking');

INSERT INTO users
(first_name, last_name, email, registration_date, city)

SELECT
    'User' || g,
    'Customer' || g,
    'user' || g || '@example.com',
    DATE '2023-01-01' + (g % 1000),
    CASE
        WHEN g % 5 = 0 THEN 'Mumbai'
        WHEN g % 5 = 1 THEN 'Delhi'
        WHEN g % 5 = 2 THEN 'Bengaluru'
        WHEN g % 5 = 3 THEN 'Hyderabad'
        ELSE 'Bhubaneswar'
    END

FROM generate_series(1, 100) AS g;


INSERT INTO merchants
(merchant_name, category_id, merchant_type)

SELECT
    v.merchant_name,
    c.category_id,
    v.merchant_type
FROM (
    VALUES
    ('Netflix', 'Entertainment', 'SUBSCRIPTION'),
    ('Spotify', 'Entertainment', 'SUBSCRIPTION'),
    ('YouTube Premium', 'Entertainment', 'SUBSCRIPTION'),
    ('Disney+ Hotstar', 'Entertainment', 'SUBSCRIPTION'),
    ('Amazon Prime', 'Shopping', 'SUBSCRIPTION'),
    ('Google One', 'Technology', 'SUBSCRIPTION'),
    ('iCloud', 'Technology', 'SUBSCRIPTION'),
    ('Microsoft 365', 'Technology', 'SUBSCRIPTION'),
    ('Adobe', 'Technology', 'SUBSCRIPTION'),
    ('Gym Membership', 'Fitness', 'SUBSCRIPTION'),
    ('Coursera', 'Education', 'SUBSCRIPTION'),
    ('Canva', 'Technology', 'SUBSCRIPTION'),
    ('Swiggy', 'Food', 'FOOD'),
    ('Zomato', 'Food', 'FOOD'),
    ('Amazon', 'Shopping', 'RETAIL'),
    ('Flipkart', 'Shopping', 'RETAIL'),
    ('Uber', 'Travel', 'TRANSPORT'),
    ('Ola', 'Travel', 'TRANSPORT'),
    ('MakeMyTrip', 'Travel', 'TRAVEL'),
    ('IRCTC', 'Travel', 'TRAVEL'),
    ('Apollo Pharmacy', 'Healthcare', 'RETAIL'),
    ('MedPlus', 'Healthcare', 'RETAIL'),
    ('Electricity Board', 'Utilities', 'UTILITIES'),
    ('Airtel', 'Utilities', 'UTILITIES'),
    ('Jio', 'Utilities', 'UTILITIES'),
    ('Starbucks', 'Food', 'FOOD'),
    ('BigBasket', 'Shopping', 'RETAIL'),
    ('Myntra', 'Shopping', 'RETAIL'),
    ('BookMyShow', 'Entertainment', 'ENTERTAINMENT'),
    ('Paytm', 'Finance', 'FINANCIAL')
) AS v(merchant_name, category_name, merchant_type)

JOIN categories c
    ON c.category_name = v.category_name;

INSERT INTO accounts
(user_id, account_name, account_type, balance)

SELECT
    ((g - 1) % 100) + 1,

    'Account_' || g,

    CASE
        WHEN g % 4 = 0 THEN 'CREDIT_CARD'
        WHEN g % 4 = 1 THEN 'SAVINGS'
        WHEN g % 4 = 2 THEN 'WALLET'
        ELSE 'CURRENT'
    END,

    ROUND((1000 + random() * 99000)::NUMERIC, 2)

FROM generate_series(1, 150) AS g;

INSERT INTO subscriptions
(
    user_id,
    merchant_id,
    monthly_price,
    start_date,
    next_billing_date,
    status
)

SELECT
    ((g - 1) % 100) + 1,

    (
        SELECT merchant_id
        FROM merchants
        WHERE merchant_type = 'SUBSCRIPTION'
        ORDER BY merchant_id
        OFFSET ((g - 1) % 12)
        LIMIT 1
    ),

    ROUND((99 + random() * 900)::NUMERIC, 2),

    DATE '2023-01-01' + (g % 900),

    CASE
        WHEN g % 4 = 0 THEN NULL
        ELSE CURRENT_DATE + (g % 30)
    END,

    CASE
        WHEN g % 10 = 0 THEN 'CANCELLED'
        WHEN g % 10 = 1 THEN 'PAUSED'
        WHEN g % 10 = 2 THEN 'EXPIRED'
        ELSE 'ACTIVE'
    END

FROM generate_series(1, 500) AS g;

INSERT INTO price_history
(
    subscription_id,
    old_price,
    new_price,
    effective_date
)

SELECT
    subscription_id,

    ROUND((monthly_price * 0.80)::NUMERIC, 2),

    monthly_price,

    start_date + INTERVAL '6 months'

FROM subscriptions
WHERE subscription_id <= 150;

INSERT INTO subscription_usage
(
    subscription_id,
    usage_date,
    usage_type
)

SELECT
    s.subscription_id,

    s.start_date
        + ((g * 3) % 500) * INTERVAL '1 day'
        + INTERVAL '10 hours',

    CASE
        WHEN g % 4 = 0 THEN 'LOGIN'
        WHEN g % 4 = 1 THEN 'STREAMING'
        WHEN g % 4 = 2 THEN 'DOWNLOAD'
        ELSE 'SESSION'
    END

FROM generate_series(1, 1200) AS g

JOIN subscriptions s
    ON s.subscription_id = ((g - 1) % 500) + 1

WHERE s.subscription_id % 5 <> 0;


INSERT INTO transactions
(
    account_id,
    merchant_id,
    amount,
    transaction_date,
    transaction_type,
    payment_status,
    reference_number
)

SELECT
    ((g - 1) % 150) + 1,

    ((g - 1) % 30) + 1,

    ROUND((50 + random() * 4950)::NUMERIC, 2),

    TIMESTAMP '2025-01-01 00:00:00'
        + (g % 680) * INTERVAL '1 day'
        + (g % 24) * INTERVAL '1 hour',

    CASE
        WHEN g % 20 = 0 THEN 'REFUND'
        WHEN g % 10 = 0 THEN 'CREDIT'
        ELSE 'DEBIT'
    END,

    CASE
        WHEN g % 20 = 0 THEN 'FAILED'
        WHEN g % 17 = 0 THEN 'PENDING'
        ELSE 'SUCCESS'
    END,

    'TXN-' || g

FROM generate_series(1, 8000) AS g;

INSERT INTO transactions
(
    account_id,
    merchant_id,
    amount,
    transaction_date,
    transaction_type,
    payment_status,
    reference_number
)

SELECT
    account_id,
    merchant_id,
    amount,
    transaction_date + INTERVAL '1 minute',
    'DEBIT',
    'SUCCESS',
    'DUP-' || transaction_id

FROM transactions
WHERE transaction_id BETWEEN 1 AND 30;

INSERT INTO disputes
(
    transaction_id,
    dispute_reason,
    dispute_date,
    dispute_status
)

SELECT
    transaction_id,

    CASE
        WHEN transaction_id % 4 = 0
            THEN 'Duplicate charge'

        WHEN transaction_id % 4 = 1
            THEN 'Unauthorized payment'

        WHEN transaction_id % 4 = 2
            THEN 'Incorrect amount'

        ELSE 'Service not received'
    END,

    transaction_date::DATE + 1,

    CASE
        WHEN transaction_id % 4 = 0 THEN 'OPEN'
        WHEN transaction_id % 4 = 1 THEN 'UNDER_REVIEW'
        WHEN transaction_id % 4 = 2 THEN 'RESOLVED'
        ELSE 'REJECTED'
    END

FROM transactions

WHERE transaction_id BETWEEN 1 AND 8000
AND transaction_id % 80 = 0;

SELECT
    s.subscription_id,
    s.user_id,
    s.monthly_price,
    s.status
FROM subscriptions s
LEFT JOIN subscription_usage su
    ON s.subscription_id = su.subscription_id
WHERE su.usage_id IS NULL;

SELECT
    subscription_id,
    old_price,
    new_price,
    new_price - old_price AS price_increase
FROM price_history
WHERE new_price > old_price
ORDER BY price_increase DESC;

SELECT
    t1.transaction_id AS transaction_1,
    t2.transaction_id AS transaction_2,
    t1.account_id,
    t1.merchant_id,
    t1.amount,
    t1.transaction_date,
    t2.transaction_date
FROM transactions t1
JOIN transactions t2
    ON t1.account_id = t2.account_id
    AND t1.merchant_id = t2.merchant_id
    AND t1.amount = t2.amount
    AND t1.transaction_id < t2.transaction_id
    AND ABS(EXTRACT(EPOCH FROM
        (t1.transaction_date - t2.transaction_date))) <= 120
WHERE t1.transaction_type = 'DEBIT'
  AND t2.transaction_type = 'DEBIT'
  AND t1.payment_status = 'SUCCESS'
  AND t2.payment_status = 'SUCCESS';

ALTER TABLE transactions
ADD COLUMN subscription_id INTEGER;

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_subscriptions
FOREIGN KEY (subscription_id)
REFERENCES subscriptions(subscription_id);

INSERT INTO transactions
(
    account_id,
    merchant_id,
    subscription_id,
    amount,
    transaction_date,
    transaction_type,
    payment_status,
    reference_number
)

SELECT
    a.account_id,
    s.merchant_id,
    s.subscription_id,
    s.monthly_price,

    (s.start_date + (gs.month_no * INTERVAL '1 month'))
        + INTERVAL '10 hours',

    'DEBIT',
    'SUCCESS',

    'SUB-BILL-' || s.subscription_id
        || '-' || gs.month_no

FROM subscriptions s

JOIN accounts a
    ON a.user_id = s.user_id

CROSS JOIN generate_series(0, 5) AS gs(month_no)

WHERE s.status = 'ACTIVE'
AND a.account_id = (
    SELECT MIN(a2.account_id)
    FROM accounts a2
    WHERE a2.user_id = s.user_id
);