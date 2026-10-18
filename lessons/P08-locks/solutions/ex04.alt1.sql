BEGIN;
SET LOCAL lock_timeout = '500ms';
ALTER TABLE p08.big ADD COLUMN x int;
COMMIT;
