BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM p06.acct WHERE id = 1;
-- >>> B
UPDATE p06.acct SET balance = balance + 30 WHERE id = 1;
COMMIT;
