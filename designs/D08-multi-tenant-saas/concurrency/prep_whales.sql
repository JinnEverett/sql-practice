-- Chuẩn bị 2 cá voi mới (tenant 9 và 10, mỗi tenant 400k task) trên schema d08 đã seed bởi queries.sql. Idempotent.
SET search_path = d08;
DO $$
DECLARE t bigint;
BEGIN
    FOREACH t IN ARRAY ARRAY[9, 10] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relnamespace = 'd08'::regnamespace AND relname = format('tasks_t%s', t)) THEN
            PERFORM promote_tenant(t);
        END IF;
        DELETE FROM tasks WHERE tenant_id = t;
        INSERT INTO tasks (tenant_id, project_id, title, status, created_at)
        SELECT t, p.id, 'task ' || g, CASE WHEN g % 3 = 0 THEN 'done' ELSE 'open' END, timestamptz '2026-01-01' + g * interval '70 seconds'
        FROM generate_series(1, 400000) g
        JOIN LATERAL (SELECT id FROM projects WHERE tenant_id = t ORDER BY id OFFSET (g % 5) LIMIT 1) p ON true;
    END LOOP;
END $$;
ANALYZE tasks;
