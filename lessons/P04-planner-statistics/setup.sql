-- P04 · dữ liệu cho ex03–ex07. Chạy trên DB `lab`. Chạy lại được nhiều lần (~3 giây).
-- Các bảng tắt autovacuum để autovacuum không "tự sửa" thống kê giữa lúc bạn đang làm bài.
DROP SCHEMA IF EXISTS p04 CASCADE;
CREATE SCHEMA p04;

-- ex03: bảng job; ANALYZE xong mới nạp thêm 100 000 dòng kind='new' (thống kê cũ không biết kind này)
CREATE TABLE p04.job (id int PRIMARY KEY, kind text NOT NULL, payload int NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p04.job SELECT i, (ARRAY['a','b','c'])[1 + i % 3], i FROM generate_series(1, 50000) i;
ANALYZE p04.job;
INSERT INTO p04.job SELECT 50000 + i, 'new', i FROM generate_series(1, 100000) i;

-- ex04: tag lệch (skew) mạnh, ~3 000 giá trị; hashint4 cho phân phối cố định giữa các lần chạy
CREATE TABLE p04.tag_event (id int PRIMARY KEY, tag int NOT NULL, payload int NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p04.tag_event
SELECT i, 1 + floor(power((hashint4(i) & 2147483647) / 2147483647.0, 3) * 3000)::int, i
FROM generate_series(1, 200000) i;
CREATE INDEX tag_event_tag_idx ON p04.tag_event (tag);
ANALYZE p04.tag_event;

-- ex05: zip xác định city (phụ thuộc hàm); 100 000 dòng, 50 city × 2 zip mỗi city
CREATE TABLE p04.addr (id int PRIMARY KEY, city int NOT NULL, zip int NOT NULL, note text) WITH (autovacuum_enabled = false);
INSERT INTO p04.addr SELECT i, 1 + i % 50, (1 + i % 50) * 10 + (i / 50) % 2, 'n' FROM generate_series(1, 100000) i;
ANALYZE p04.addr;

-- ex06: log theo thời gian; thống kê dừng ở 2026-09-30, sau đó nạp thêm 20 000 dòng của ngày 2026-10-01
CREATE TABLE p04.log (id int PRIMARY KEY, created_at timestamptz NOT NULL, msg text) WITH (autovacuum_enabled = false);
INSERT INTO p04.log SELECT i, timestamptz '2026-07-01 00:00+00' + i * interval '39 seconds', 'm' FROM generate_series(1, 200000) i;
CREATE INDEX log_created_idx ON p04.log (created_at);
ANALYZE p04.log;
INSERT INTO p04.log SELECT 200000 + i, timestamptz '2026-10-01 00:00+00' + i * interval '4 seconds', 'm' FROM generate_series(1, 20000) i;

-- ex07: fact ⋈ dim, a và b trùng nhau (b xác định bởi a), dim KHÔNG có index trên khóa join
CREATE TABLE p04.fact (id int PRIMARY KEY, a int NOT NULL, b int NOT NULL, k int NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p04.fact SELECT i, i % 1000, i % 1000, 1 + (i * 7) % 20000 FROM generate_series(1, 200000) i;
CREATE TABLE p04.dim (k int NOT NULL, label text NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p04.dim SELECT i, 'd' || i FROM generate_series(1, 20000) i;
ANALYZE p04.fact;
ANALYZE p04.dim;
