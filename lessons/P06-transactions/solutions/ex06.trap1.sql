BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) FROM p06.doctor WHERE on_call;
-- >>> B
UPDATE p06.doctor SET on_call = false WHERE id = :me;
COMMIT;
