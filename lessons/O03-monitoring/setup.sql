-- O03 · Monitoring. Chạy trên DB `lab`, schema `o03`. Chạy lại bao nhiêu lần cũng được.
-- Cần extension pg_stat_statements (đã có sẵn trong lab, nạp qua shared_preload_libraries ở docker-compose).
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
DROP SCHEMA IF EXISTS o03 CASCADE;
CREATE SCHEMA o03;

CREATE TABLE o03.big (id int PRIMARY KEY, grp int NOT NULL, payload text NOT NULL);
INSERT INTO o03.big SELECT i, i % 100, md5(i::text) || md5((i * 7)::text) FROM generate_series(1, 300000) i;
CREATE TABLE o03.small (id int PRIMARY KEY, v int NOT NULL);
INSERT INTO o03.small SELECT i, i * 10 FROM generate_series(1, 1000) i;
CREATE TABLE o03.mid (id int PRIMARY KEY, v int NOT NULL);       -- không ai truy vấn: để thấy bảng "im lặng"
INSERT INTO o03.mid SELECT i, i FROM generate_series(1, 20000) i;
ANALYZE o03.big; ANALYZE o03.small; ANALYZE o03.mid;
