-- db: lab
-- mode: manual
-- Demo (chuẩn bị bảng; số đo thật dùng pgbench, lệnh ở comment dưới và trong ex08.md).
DROP SCHEMA IF EXISTS r08b CASCADE;
CREATE SCHEMA r08b;
CREATE TABLE r08b.counters (id int PRIMARY KEY, n bigint NOT NULL);
INSERT INTO r08b.counters VALUES (1, 0);
CREATE TABLE r08b.counters_sharded (shard int PRIMARY KEY, n bigint NOT NULL);
INSERT INTO r08b.counters_sharded SELECT g, 0 FROM generate_series(1, 16) g;
-- hot.sql:      UPDATE r08b.counters SET n = n + 1 WHERE id = 1;
-- sharded.sql:  \set s random(1, 16)
--               UPDATE r08b.counters_sharded SET n = n + 1 WHERE shard = :s;
-- chạy:  pgbench -U postgres -n -c 16 -j 4 -T 10 -f hot.sql lab      (và -f sharded.sql)
-- Đọc tổng của bộ đếm phân mảnh:
SELECT sum(n) FROM r08b.counters_sharded;
DROP SCHEMA r08b CASCADE;
