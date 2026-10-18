-- P10b · dữ liệu cho ex03, ex04, ex07, ex08. Chạy trên DB `lab`. Chạy lại được nhiều lần (~2 giây).
-- Các hàm "chậm" (pg_sleep 0.5 ms mỗi dòng) làm các thao tác quét bảng/xây index kéo dài vài giây, để việc bị khóa hay không dễ quan sát.
DROP SCHEMA IF EXISTS p10b CASCADE;
CREATE SCHEMA p10b;

-- ex03: nạp từ staging
CREATE TABLE p10b.src (id int PRIMARY KEY, v int NOT NULL, pad text NOT NULL);
INSERT INTO p10b.src SELECT i, i % 100, md5(i::text) FROM generate_series(1, 5000) i;
CREATE TABLE p10b.dst (id int PRIMARY KEY, v int NOT NULL, pad text NOT NULL);

CREATE FUNCTION p10b.slow_id(i int) RETURNS int LANGUAGE plpgsql IMMUTABLE AS $$ BEGIN PERFORM pg_sleep(0.0005); RETURN i; END $$;
CREATE FUNCTION p10b.slow_ok(i int) RETURNS boolean LANGUAGE plpgsql IMMUTABLE AS $$ BEGIN PERFORM pg_sleep(0.0005); RETURN i >= 0; END $$;

-- ex04: bảng đang có ghi liên tục; xây index trên slow_id(id) mất ~5.7 giây
CREATE TABLE p10b.t4 (id int PRIMARY KEY, pad text NOT NULL);
INSERT INTO p10b.t4 SELECT i, 'x' FROM generate_series(1, 5000) i;

-- ex07: thêm CHECK slow_ok(id) mất ~5.7 giây khi quét
CREATE TABLE p10b.t7 (id int PRIMARY KEY, pad text NOT NULL);
INSERT INTO p10b.t7 SELECT i, 'x' FROM generate_series(1, 5000) i;

-- ex08: bảng 100 000 dòng cần thêm cột bigint
CREATE TABLE p10b.big (id int PRIMARY KEY, amount int NOT NULL);
INSERT INTO p10b.big SELECT i, i * 3 FROM generate_series(1, 100000) i;
ANALYZE p10b.big;
