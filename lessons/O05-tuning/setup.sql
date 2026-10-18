-- O05 · Tuning. Chạy trên DB `lab`, schema `o05`. Chạy lại bao nhiêu lần cũng được.
-- items: bảng để đọc công thức cost của planner (ex02). big: bảng đủ lớn để một lần sort không vừa work_mem mặc định (ex03).
DROP SCHEMA IF EXISTS o05 CASCADE;
CREATE SCHEMA o05;

CREATE TABLE o05.items (id int PRIMARY KEY, grp int NOT NULL, pad text NOT NULL);
INSERT INTO o05.items SELECT i, i % 100, md5(i::text) FROM generate_series(1, 200000) i;

CREATE TABLE o05.big (id int PRIMARY KEY, payload text NOT NULL);
INSERT INTO o05.big SELECT i, md5(i::text) || md5((i * 7)::text) FROM generate_series(1, 600000) i;

-- relpages/reltuples phải chính xác thì công thức cost mới khớp EXPLAIN.
VACUUM ANALYZE o05.items;
VACUUM ANALYZE o05.big;
