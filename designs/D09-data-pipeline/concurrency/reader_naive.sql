-- Poll theo "id > last_id" (cách ngây thơ)
DO $$
DECLARE last_id bigint := 0; seen bigint := 0; r record; t0 timestamptz := clock_timestamp(); n bigint;
BEGIN
    WHILE clock_timestamp() - t0 < interval '9 seconds' LOOP
        SELECT count(*), COALESCE(max(id), last_id) INTO n, last_id FROM d09.demo_events WHERE id > last_id;
        seen := seen + n;
        PERFORM pg_sleep(0.005);
    END LOOP;
    SELECT count(*), COALESCE(max(id), last_id) INTO n, last_id FROM d09.demo_events WHERE id > last_id;
    seen := seen + n;
    INSERT INTO d09.demo_result VALUES ('naive id > last_id', seen) ON CONFLICT (mode) DO UPDATE SET seen = EXCLUDED.seen;
END $$;
