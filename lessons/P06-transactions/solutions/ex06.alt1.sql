BEGIN;
SELECT * FROM p06.doctor WHERE on_call FOR UPDATE;
-- >>> B
UPDATE p06.doctor SET on_call = false WHERE id = :me AND (SELECT count(*) FROM p06.doctor WHERE on_call) >= 2;
COMMIT;
