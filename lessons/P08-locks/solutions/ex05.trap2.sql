INSERT INTO p08.runs SELECT 'ran' WHERE pg_try_advisory_lock(43);
