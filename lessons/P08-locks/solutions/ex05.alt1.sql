BEGIN;
INSERT INTO p08.runs SELECT 'ran' WHERE pg_try_advisory_xact_lock(42);
COMMIT;
