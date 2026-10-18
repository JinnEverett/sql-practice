BEGIN;
INSERT INTO p06.reads SELECT 1, count(*) FROM p06.ticket WHERE status = 'open';
-- >>> B
INSERT INTO p06.reads SELECT 2, count(*) FROM p06.ticket WHERE status = 'open';
COMMIT;
