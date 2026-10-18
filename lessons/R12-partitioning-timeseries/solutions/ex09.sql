-- db: lab
-- mode: manual
-- Demo (N = 100 000, vài giây): partition theo tháng so với bảng thường — pruning khi không có index, và retention bằng DROP so với DELETE.
-- Đổi 100000 thành 1000000 / 5000000 để tái hiện số đo ở ex09.md. Dọn sạch cuối script.
DROP SCHEMA IF EXISTS r12d CASCADE;
CREATE SCHEMA r12d;
CREATE TABLE r12d.mono (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, device int NOT NULL, ts timestamptz NOT NULL, value numeric(10,2) NOT NULL);
CREATE TABLE r12d.part (id bigint GENERATED ALWAYS AS IDENTITY, device int NOT NULL, ts timestamptz NOT NULL, value numeric(10,2) NOT NULL, PRIMARY KEY (id, ts)) PARTITION BY RANGE (ts);
DO $$ DECLARE i int; t0 timestamptz := '2026-01-01 00:00+00'; BEGIN
  FOR i IN 0..11 LOOP
    EXECUTE format('CREATE TABLE r12d.part_%s PARTITION OF r12d.part FOR VALUES FROM (%L) TO (%L)', i, t0 + make_interval(months => i), t0 + make_interval(months => i + 1));
  END LOOP;
END $$;
INSERT INTO r12d.mono (device, ts, value) SELECT i % 100, timestamptz '2026-01-01 00:00+00' + (i::bigint * 365 * 86400 / 100000) * interval '1 second', (i % 1000) / 10.0 FROM generate_series(0, 99999) i;
INSERT INTO r12d.part (device, ts, value) SELECT i % 100, timestamptz '2026-01-01 00:00+00' + (i::bigint * 365 * 86400 / 100000) * interval '1 second', (i % 1000) / 10.0 FROM generate_series(0, 99999) i;
VACUUM ANALYZE r12d.mono; VACUUM ANALYZE r12d.part;
\echo '--- một ngày, KHÔNG có index trên ts: bảng thường quét hết, bảng partition chỉ quét 1 partition'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*), sum(value) FROM r12d.mono WHERE ts >= '2026-03-10 00:00+00' AND ts < '2026-03-11 00:00+00';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*), sum(value) FROM r12d.part WHERE ts >= '2026-03-10 00:00+00' AND ts < '2026-03-11 00:00+00';
\echo '--- retention tháng 1: DELETE (dead tuple + WAL) so với DETACH + DROP (gần như không WAL)'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM r12d.mono WHERE ts >= '2026-01-01 00:00+00' AND ts < '2026-02-01 00:00+00';
ROLLBACK;
BEGIN;
ALTER TABLE r12d.part DETACH PARTITION r12d.part_0;
DROP TABLE r12d.part_0;
ROLLBACK;
DROP SCHEMA r12d CASCADE;
