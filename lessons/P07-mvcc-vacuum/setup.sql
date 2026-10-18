-- P07 · dữ liệu cho ex01–ex07. Chạy trên DB `lab`. Chạy lại được nhiều lần (~5 giây).
-- Mọi bảng tắt autovacuum để autovacuum không "dọn hộ" giữa lúc bạn đang đo.
CREATE EXTENSION IF NOT EXISTS pageinspect;
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_visibility;
DROP SCHEMA IF EXISTS p07 CASCADE;
CREATE SCHEMA p07;

-- ex01: 3 dòng; dòng 1 được UPDATE 3 lần (mỗi lần một lệnh riêng), dòng 3 bị DELETE
CREATE TABLE p07.ver (id int PRIMARY KEY, n int NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p07.ver VALUES (1, 0), (2, 0), (3, 0);
UPDATE p07.ver SET n = 1 WHERE id = 1;
UPDATE p07.ver SET n = 2 WHERE id = 1;
UPDATE p07.ver SET n = 3 WHERE id = 1;
DELETE FROM p07.ver WHERE id = 3;

-- ex02–ex04: 100 000 dòng, mỗi dòng bị UPDATE 3 lần (3 lệnh toàn bảng), index trên val → không HOT
CREATE TABLE p07.bloat (id int PRIMARY KEY, val int NOT NULL, pad text NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p07.bloat SELECT i, i, repeat('x', 50) FROM generate_series(1, 100000) i;
CREATE INDEX bloat_val_idx ON p07.bloat (val);
UPDATE p07.bloat SET val = val + 1;
UPDATE p07.bloat SET val = val + 1;
UPDATE p07.bloat SET val = val + 1;

-- ex05: bảng báo cáo, 10 000 dòng bị UPDATE toàn bảng 1 lần
CREATE TABLE p07.held (id int PRIMARY KEY, n int NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p07.held SELECT i, 0 FROM generate_series(1, 10000) i;
UPDATE p07.held SET n = n + 1;

-- ex06: bảng lịch sử, chỉ INSERT; 200 000 dòng
CREATE TABLE p07.hist (id int PRIMARY KEY, payload text NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p07.hist SELECT i, repeat('h', 40) FROM generate_series(1, 200000) i;

-- ex07: hàng đợi; nơi dữ liệu liên tục được thêm, sửa, xóa
CREATE TABLE p07.queue (id int PRIMARY KEY, state text NOT NULL, payload text NOT NULL) WITH (autovacuum_enabled = false);
INSERT INTO p07.queue SELECT i, 'new', 'q' FROM generate_series(1, 100000) i;
