-- db: lab
-- mode: manual
-- Demo (N = 100 000, chưa tới 1 giây mỗi lệnh): thời gian của các thao tác DDL thường gặp. Đổi 100000 thành 1000000 / 5000000 để tái hiện số đo ở ex09.md.
-- Để thấy truy vấn bị chặn: mở thêm một cửa sổ psql và chạy `SELECT 1 FROM r10m.t LIMIT 1;` / `INSERT …` ngay lúc lệnh DDL đang chạy (cách đo ở ex09.md).
DROP SCHEMA IF EXISTS r10m CASCADE;
CREATE SCHEMA r10m;
CREATE TABLE r10m.t (id int PRIMARY KEY, amount numeric(12,2) NOT NULL, ref text, created_at timestamptz NOT NULL);
INSERT INTO r10m.t SELECT i, 1000 + i % 500, 'C' || (i % 1000), timestamptz '2026-01-01' + i * interval '1 second' FROM generate_series(1, 100000) i;
VACUUM ANALYZE r10m.t;
\timing on
\echo '--- ADD COLUMN default hằng'
ALTER TABLE r10m.t ADD COLUMN c1 int NOT NULL DEFAULT 0;
\echo '--- ADD COLUMN default volatile'
ALTER TABLE r10m.t ADD COLUMN c2 numeric DEFAULT random();
\echo '--- ALTER COLUMN TYPE bigint'
ALTER TABLE r10m.t ALTER COLUMN id TYPE bigint;
\echo '--- CREATE INDEX thường'
CREATE INDEX t_amount_idx ON r10m.t (amount);
DROP INDEX r10m.t_amount_idx;
\echo '--- CREATE INDEX CONCURRENTLY'
CREATE INDEX CONCURRENTLY t_amount_idx ON r10m.t (amount);
\echo '--- SET NOT NULL trực tiếp'
ALTER TABLE r10m.t ALTER COLUMN ref SET NOT NULL;
ALTER TABLE r10m.t ALTER COLUMN ref DROP NOT NULL;
\echo '--- NOT VALID → VALIDATE → SET NOT NULL'
ALTER TABLE r10m.t ADD CONSTRAINT ref_nn CHECK (ref IS NOT NULL) NOT VALID;
ALTER TABLE r10m.t VALIDATE CONSTRAINT ref_nn;
ALTER TABLE r10m.t ALTER COLUMN ref SET NOT NULL;
\timing off
DROP SCHEMA r10m CASCADE;
