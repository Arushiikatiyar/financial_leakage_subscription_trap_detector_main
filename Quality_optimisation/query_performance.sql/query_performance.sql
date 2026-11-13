
EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE account_id = 10;

--Compare a query before and after indexing--

--Before creating the index--

DROP INDEX IF EXISTS idx_transactions_account_id;

EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE account_id = 10;
--Create the index--

CREATE INDEX IF NOT EXISTS idx_transactions_account_id
ON transactions(account_id);

ANALYZE transactions;
--Run the same query again--

EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE account_id = 10;
--Verify that indexes exist--

SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
