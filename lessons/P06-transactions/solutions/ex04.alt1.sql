BEGIN;
SELECT balance FROM p06.acct WHERE id = 1 FOR UPDATE;
-- >>> B
UPDATE p06.acct SET balance = 130 WHERE id = 1;
COMMIT;
