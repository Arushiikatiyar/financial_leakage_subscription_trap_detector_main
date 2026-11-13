BEGIN;
CREATE TABLE users (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    registration_date DATE NOT NULL,
    city VARCHAR(80)
);

CREATE TABLE categories (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE accounts (
    account_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    user_id INTEGER NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(30) NOT NULL,
    balance NUMERIC(12,2) NOT NULL
        CHECK (balance >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_accounts_users
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT chk_account_type
        CHECK (account_type IN
        ('SAVINGS', 'CURRENT', 'CREDIT_CARD', 'WALLET'))
);

CREATE TABLE merchants (
    merchant_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL UNIQUE,
    category_id INTEGER NOT NULL,
    merchant_type VARCHAR(40) NOT NULL,

    CONSTRAINT fk_merchants_categories
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
);

CREATE TABLE transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    account_id INTEGER NOT NULL,
    merchant_id INTEGER NOT NULL,
    amount NUMERIC(12,2) NOT NULL
        CHECK (amount > 0),
    transaction_date TIMESTAMP NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    payment_status VARCHAR(20) NOT NULL,
    reference_number VARCHAR(100) UNIQUE,

    CONSTRAINT fk_transactions_accounts
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id),

    CONSTRAINT fk_transactions_merchants
        FOREIGN KEY (merchant_id)
        REFERENCES merchants(merchant_id),

    CONSTRAINT chk_transaction_type
        CHECK (transaction_type IN
        ('DEBIT', 'CREDIT', 'REFUND')),

    CONSTRAINT chk_payment_status
        CHECK (payment_status IN
        ('SUCCESS', 'FAILED', 'PENDING'))
);

CREATE TABLE subscriptions (
    subscription_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    user_id INTEGER NOT NULL,
    merchant_id INTEGER NOT NULL,
    monthly_price NUMERIC(10,2) NOT NULL
        CHECK (monthly_price > 0),
    start_date DATE NOT NULL,
    next_billing_date DATE,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_subscriptions_users
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_subscriptions_merchants
        FOREIGN KEY (merchant_id)
        REFERENCES merchants(merchant_id),

    CONSTRAINT chk_subscription_status
        CHECK (status IN
        ('ACTIVE', 'CANCELLED', 'PAUSED', 'EXPIRED'))
);

CREATE TABLE disputes (
    dispute_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    dispute_reason TEXT NOT NULL,
    dispute_date DATE NOT NULL,
    dispute_status VARCHAR(25) NOT NULL,

    CONSTRAINT fk_disputes_transactions
        FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id),

    CONSTRAINT chk_dispute_status
        CHECK (dispute_status IN
        ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED'))
);

CREATE TABLE price_history (
    price_history_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    subscription_id INTEGER NOT NULL,
    old_price NUMERIC(10,2) NOT NULL
        CHECK (old_price > 0),
    new_price NUMERIC(10,2) NOT NULL
        CHECK (new_price > 0),
    effective_date DATE NOT NULL,

    CONSTRAINT fk_price_history_subscriptions
        FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);

CREATE TABLE subscription_usage (
    usage_id BIGINT GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    subscription_id INTEGER NOT NULL,
    usage_date TIMESTAMP NOT NULL,
    usage_type VARCHAR(50) NOT NULL,

    CONSTRAINT fk_usage_subscriptions
        FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);

COMMIT;
