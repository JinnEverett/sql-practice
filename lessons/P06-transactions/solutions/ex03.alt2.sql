BEGIN;
SELECT balance FROM p06.acct WHERE id = 1 FOR SHARE;
INSERT INTO p06.reads SELECT 1, balance FROM p06.acct WHERE id = 1;
-- >>> B
INSERT INTO p06.reads SELECT 2, balance FROM p06.acct WHERE id = 1;
COMMIT;
