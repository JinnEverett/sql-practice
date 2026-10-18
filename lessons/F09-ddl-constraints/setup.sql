-- F09 · DDL & constraints. Chạy trên DB `lab`. Chạy lại bao nhiêu lần cũng được (reset về ban đầu).
DROP SCHEMA IF EXISTS f09 CASCADE;
CREATE SCHEMA f09;
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- cho ex09 (exclusion constraint trên cột số nguyên)

-- ex03: bảng cha có sẵn
CREATE TABLE f09.c_customers (id int PRIMARY KEY, name text NOT NULL);
CREATE TABLE f09.c_products  (id int PRIMARY KEY, name text NOT NULL);
INSERT INTO f09.c_customers VALUES (1, 'An'), (2, 'Bình');
INSERT INTO f09.c_products  VALUES (1, 'Chuột'), (2, 'Bàn phím'), (3, 'Tai nghe');

-- ex04: bảng cũ, email bẩn
CREATE TABLE f09.legacy_users (
  id         int PRIMARY KEY,
  email      text NOT NULL,
  created_at timestamptz NOT NULL
);
INSERT INTO f09.legacy_users VALUES
  (1, 'an@x.vn',      '2026-01-01 09:00+07'),
  (2, 'An@X.vn',      '2026-02-01 09:00+07'),
  (3, 'binh@x.vn',    '2026-01-05 09:00+07'),
  (4, ' binh@x.vn ',  '2026-01-03 09:00+07'),
  (5, 'Chi@x.vn',     '2026-01-07 09:00+07'),
  (6, 'dung@x.vn',    '2026-01-08 09:00+07'),
  (7, 'DUNG@x.vn',    '2026-01-08 09:00+07');

-- ex10: giá nhập từ file Excel, đang lưu dạng text
CREATE TABLE f09.imports (
  id    int PRIMARY KEY,
  sku   text NOT NULL,
  price text NOT NULL
);
INSERT INTO f09.imports VALUES
  (1, 'AB-0001', '1.200.000đ'),
  (2, 'AB-0002', '350000'),
  (3, 'AB-0003', '89.000 đ'),
  (4, 'AB-0004', ' 2.500.000 '),
  (5, 'AB-0005', '0');
