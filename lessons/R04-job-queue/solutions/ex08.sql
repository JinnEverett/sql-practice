-- db: lab
-- mode: manual
-- Demo: chi phí câu nhận job khi hàng đợi có 100 job 'queued' lẫn trong 100 000 job 'done' (schema r04s, dọn sạch cuối script).
-- Đổi 100000 thành 1000000 (và 100 thành 1000) để tái hiện số đo ở ex08.md.
DROP SCHEMA IF EXISTS r04s CASCADE;
CREATE SCHEMA r04s;
CREATE TABLE r04s.jobs (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, priority int NOT NULL, status text NOT NULL, run_at timestamptz NOT NULL, payload jsonb NOT NULL DEFAULT '{}');
INSERT INTO r04s.jobs (priority, status, run_at)
SELECT (i::bigint * 7919) % 10, CASE WHEN i % 1000 = 0 THEN 'queued' ELSE 'done' END, timestamptz '2026-01-01' + i * interval '1 second'
FROM generate_series(1, 100000) i;
VACUUM ANALYZE r04s.jobs;
\echo '--- (a) không có index nào ngoài PK'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id FROM r04s.jobs WHERE status = 'queued' AND run_at <= now() ORDER BY priority DESC, run_at, id LIMIT 1 FOR UPDATE SKIP LOCKED;
\echo '--- (b) index đầy đủ (priority DESC, run_at, id)'
CREATE INDEX j_full ON r04s.jobs (priority DESC, run_at, id);
ANALYZE r04s.jobs;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id FROM r04s.jobs WHERE status = 'queued' AND run_at <= now() ORDER BY priority DESC, run_at, id LIMIT 1 FOR UPDATE SKIP LOCKED;
DROP INDEX r04s.j_full;
\echo '--- (c) partial index chỉ chứa job queued'
CREATE INDEX j_queued ON r04s.jobs (priority DESC, run_at, id) WHERE status = 'queued';
ANALYZE r04s.jobs;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id FROM r04s.jobs WHERE status = 'queued' AND run_at <= now() ORDER BY priority DESC, run_at, id LIMIT 1 FOR UPDATE SKIP LOCKED;
DROP SCHEMA r04s CASCADE;
