-- R10 · migration không downtime. Chạy trên DB `lab`. Chạy lại được nhiều lần.
-- Tham số: số dòng của bảng orders, mặc định 20 000. Đổi bằng:  psql -v n=1000000 -f setup.sql
\if :{?n}
\else
\set n 20000
\endif
DROP SCHEMA IF EXISTS r10 CASCADE;
CREATE SCHEMA r10;

-- (1) orders: bảng dùng cho ex01, ex02, ex03, ex08. Mọi dòng được chèn trong MỘT transaction nên có cùng xmin (ex01, ex03 dựa vào điều này).
CREATE TABLE r10.orders (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  status       text NOT NULL,
  customer_ref text,                    -- ex02: hiện nullable, mọi dòng đều đã có giá trị
  amount       numeric(12,2) NOT NULL,
  created_at   timestamptz NOT NULL,
  status_code  smallint);               -- ex03: cột mới, cần backfill từ status
INSERT INTO r10.orders (status, customer_ref, amount, created_at)
SELECT (ARRAY['pending', 'paid', 'shipped', 'delivered', 'cancelled'])[1 + i % 5],
       'C' || (i % 1000), 1000 + i % 500, timestamptz '2026-01-01' + i * interval '1 minute'
FROM generate_series(1, :n) i;
VACUUM ANALYZE r10.orders;

-- (2) users: có email trùng; một lần CREATE UNIQUE INDEX CONCURRENTLY đã thất bại và để lại index INVALID (ex04)
CREATE TABLE r10.users (id int PRIMARY KEY, email text NOT NULL, updated_at timestamptz NOT NULL);
INSERT INTO r10.users VALUES
  (1, 'a@x.vn', '2026-01-01 00:00+00'), (2, 'a@x.vn', '2026-02-01 00:00+00'),
  (3, 'b@x.vn', '2026-01-05 00:00+00'),
  (4, 'c@x.vn', '2026-01-01 00:00+00'), (5, 'c@x.vn', '2026-03-01 00:00+00'), (6, 'c@x.vn', '2026-03-01 00:00+00'),
  (7, 'd@x.vn', '2026-01-01 00:00+00');
\set ON_ERROR_STOP off
CREATE UNIQUE INDEX CONCURRENTLY users_email_uq ON r10.users (email);
\set ON_ERROR_STOP on

-- (3) orders2: đổi tên cột total → amount_vnd theo kiểu expand/contract; cột mới đã được thêm, chưa có dữ liệu (ex06)
CREATE TABLE r10.orders2 (id int PRIMARY KEY, total numeric(12,2), amount_vnd numeric(12,2));
INSERT INTO r10.orders2 (id, total) VALUES (1, 100000), (2, 250000), (3, 0), (4, NULL), (5, 75000);

-- (4) parent / child: thêm FK an toàn (ex07). Dữ liệu hiện tại hợp lệ.
CREATE TABLE r10.parent (id int PRIMARY KEY);
INSERT INTO r10.parent SELECT generate_series(1, 100);
CREATE TABLE r10.child (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, parent_id int NOT NULL);
INSERT INTO r10.child (parent_id) SELECT 1 + i % 100 FROM generate_series(1, 5000) i;
