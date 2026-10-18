-- db: lab
-- mode: manual
-- Demo: bảng 3 index thêm; so thời gian nạp với bảng chỉ có PK (dùng p10.t_m làm nguồn, cần setup của P10a).
CREATE SCHEMA IF NOT EXISTS p10b;
DROP TABLE IF EXISTS p10b.w3;
CREATE TABLE p10b.w3 (id int PRIMARY KEY, u int, ts timestamptz, grp int, amount int, gen int, pad text);
CREATE INDEX ON p10b.w3 (u);
CREATE INDEX ON p10b.w3 (ts);
CREATE INDEX ON p10b.w3 (grp, amount);
INSERT INTO p10b.w3 SELECT id, u, ts, grp, amount, gen, pad FROM p10.t_m;
SELECT pg_size_pretty(pg_relation_size('p10b.w3')) AS heap, pg_size_pretty(pg_indexes_size('p10b.w3')) AS indexes;
DROP TABLE p10b.w3;
