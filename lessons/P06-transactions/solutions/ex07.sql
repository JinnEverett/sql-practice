-- db: lab
-- mode: manual
-- Demo: bảng và script pgbench dùng ở ex07 (chạy pgbench ngoài psql: xem ex07.md).
DROP TABLE IF EXISTS p06.hot;
CREATE TABLE p06.hot (id int PRIMARY KEY, v int NOT NULL);
INSERT INTO p06.hot SELECT i, 0 FROM generate_series(1, 1000) i;
