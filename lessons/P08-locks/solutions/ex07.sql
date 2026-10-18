-- db: lab
-- mode: manual
-- Demo: bảng hàng đợi 200 000 việc cho pgbench (xem ex07.md).
DROP TABLE IF EXISTS p08.q;
CREATE TABLE p08.q (id int PRIMARY KEY, state text NOT NULL);
INSERT INTO p08.q SELECT i, 'new' FROM generate_series(1, 200000) i;
