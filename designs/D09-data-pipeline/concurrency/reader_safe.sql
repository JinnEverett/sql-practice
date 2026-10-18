-- Poll theo "chưa published" + SKIP LOCKED (cách của claim_outbox)
DO $$
DECLARE seen bigint := 0; n bigint; t0 timestamptz := clock_timestamp();
BEGIN
    WHILE clock_timestamp() - t0 < interval '9 seconds' LOOP
        WITH c AS (UPDATE d09.demo_events SET published_at = now()
                   WHERE id IN (SELECT id FROM d09.demo_events WHERE published_at IS NULL ORDER BY id LIMIT 1000 FOR UPDATE SKIP LOCKED) RETURNING 1)
        SELECT count(*) INTO n FROM c;
        seen := seen + n;
        PERFORM pg_sleep(0.005);
    END LOOP;
    WITH c AS (UPDATE d09.demo_events SET published_at = now()
               WHERE id IN (SELECT id FROM d09.demo_events WHERE published_at IS NULL ORDER BY id FOR UPDATE SKIP LOCKED) RETURNING 1)
    SELECT count(*) INTO n FROM c;
    seen := seen + n;
    INSERT INTO d09.demo_result VALUES ('safe SKIP LOCKED', seen) ON CONFLICT (mode) DO UPDATE SET seen = EXCLUDED.seen;
END $$;
