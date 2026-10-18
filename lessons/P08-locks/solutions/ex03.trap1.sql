BEGIN;
UPDATE p08.acct SET balance = balance - 10 WHERE id = :from;
-- >>> B
UPDATE p08.acct SET balance = balance + 10 WHERE id = :to;
INSERT INTO p08.xfer_log VALUES (:from, :to);
COMMIT;
