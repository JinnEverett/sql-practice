-- Phương án đối chứng: schema-per-tenant. 1000 tenant x (projects + tasks + 3 index). Đo catalog và chi phí migration.
-- Ghi chú đo thật: gộp cả 1000 schema trong MỘT transaction thất bại với `out of shared memory` (max_locks_per_transaction mặc định 64).
-- Chạy:  psql -d lab -f schema_per_tenant.sql   (tự dọn sau khi xong, ~vài chục giây)
\timing on
SELECT pg_size_pretty(pg_total_relation_size('pg_class') + pg_total_relation_size('pg_attribute') + pg_total_relation_size('pg_index')) AS catalog_size_before;
DO $$ BEGIN FOR i IN 1..1000 LOOP
    EXECUTE format('CREATE SCHEMA spt_%s', i);
    EXECUTE format('CREATE TABLE spt_%s.projects (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL)', i);
    EXECUTE format('CREATE TABLE spt_%s.tasks (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, project_id bigint NOT NULL REFERENCES spt_%s.projects(id), title text NOT NULL, status text NOT NULL, created_at timestamptz NOT NULL DEFAULT now())', i, i);
    EXECUTE format('CREATE INDEX ON spt_%s.tasks (project_id, status)', i);
    EXECUTE format('CREATE INDEX ON spt_%s.tasks (created_at DESC)', i);
    COMMIT;      -- mỗi tenant một transaction: gộp 1000 tenant vào một transaction sẽ hết lock table (out of shared memory)
END LOOP; END $$;
SELECT count(*) AS relations_in_catalog, pg_size_pretty(pg_total_relation_size('pg_class') + pg_total_relation_size('pg_attribute') + pg_total_relation_size('pg_index')) AS catalog_size_after
FROM pg_class WHERE relnamespace::regnamespace::text LIKE 'spt\_%';
-- Migration "thêm 1 cột" phải chạy 1000 lần
DO $$ BEGIN FOR i IN 1..1000 LOOP EXECUTE format('ALTER TABLE spt_%s.tasks ADD COLUMN assignee bigint', i); COMMIT; END LOOP; END $$;
-- dọn
DO $$ BEGIN FOR i IN 1..1000 LOOP EXECUTE format('DROP SCHEMA IF EXISTS spt_%s CASCADE', i); COMMIT; END LOOP; END $$;
\timing off
