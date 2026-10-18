-- db: lab
-- mode: manual
-- Demo (100 000 dòng, vài giây): RLS có làm chậm query không, và khi nào? So policy viết thẳng biểu thức với policy gọi hàm VOLATILE.
-- Đổi 100000 thành 1000000 để tái hiện số đo ở ex07.md. Mọi thứ dựng trong schema r09b rồi dọn sạch.
DROP SCHEMA IF EXISTS r09b CASCADE;
CREATE SCHEMA r09b;
GRANT USAGE ON SCHEMA r09b TO r09_app;
CREATE TABLE r09b.inv (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, tenant_id int NOT NULL, created_at timestamptz NOT NULL, amount numeric(12,2) NOT NULL);
-- tenant 1 chiếm khoảng 30% số dòng, 99 tenant còn lại chia đều
INSERT INTO r09b.inv (tenant_id, created_at, amount)
SELECT CASE WHEN (i::bigint * 7919) % 100 < 30 THEN 1 ELSE 2 + (i::bigint * 104729) % 99 END,
       timestamptz '2026-01-01' + (i % 270) * interval '1 day' + (i % 86400) * interval '1 second', (i % 1000) + 1
FROM generate_series(1, 100000) i;
CREATE INDEX r09b_idx ON r09b.inv (tenant_id, created_at);
CREATE FUNCTION r09b.cur_volatile() RETURNS int LANGUAGE plpgsql AS $f$ BEGIN RETURN nullif(current_setting('app.tenant_id', true), '')::int; END $f$;
GRANT SELECT ON r09b.inv TO r09_app;
GRANT EXECUTE ON FUNCTION r09b.cur_volatile() TO r09_app;
ALTER TABLE r09b.inv ENABLE ROW LEVEL SECURITY;
VACUUM ANALYZE r09b.inv;

\echo '--- (a) không RLS, WHERE tenant_id viết tay (superuser)'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT count(*), sum(amount) FROM r09b.inv WHERE created_at >= '2026-03-01' AND created_at < '2026-04-01' AND tenant_id = 77;

\echo '--- (b) RLS, policy là biểu thức current_setting(…) trực tiếp'
CREATE POLICY ti ON r09b.inv USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
BEGIN;
SET LOCAL ROLE r09_app;
SELECT set_config('app.tenant_id', '77', true);
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT count(*), sum(amount) FROM r09b.inv WHERE created_at >= '2026-03-01' AND created_at < '2026-04-01';
ROLLBACK;

\echo '--- (c) RLS, policy gọi hàm VOLATILE (mặc định của plpgsql): chậm hơn nhiều, không dùng được tenant_id trong index'
DROP POLICY ti ON r09b.inv;
CREATE POLICY ti ON r09b.inv USING (tenant_id = r09b.cur_volatile());
BEGIN;
SET LOCAL ROLE r09_app;
SELECT set_config('app.tenant_id', '77', true);
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT count(*), sum(amount) FROM r09b.inv WHERE created_at >= '2026-03-01' AND created_at < '2026-04-01';
ROLLBACK;
DROP SCHEMA r09b CASCADE;
