-- R05 · lịch sử dữ liệu: soft delete, audit log, SCD2. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS r05 CASCADE;
CREATE SCHEMA r05;

-- (1) Soft delete
CREATE TABLE r05.accounts (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email      text NOT NULL,
  name       text NOT NULL,
  deleted_at timestamptz);
INSERT INTO r05.accounts (email, name, deleted_at) VALUES
  ('a@x.vn', 'A', NULL),
  ('b@x.vn', 'B', '2026-02-01 00:00+00'),
  ('c@x.vn', 'C', NULL);

-- (2) Bảng được audit + hai bảng nhật ký (ex02: ghi cả hàng; ex03: chỉ ghi phần thay đổi)
CREATE TABLE r05.products (
  id         int PRIMARY KEY,
  name       text NOT NULL,
  price      numeric(12,2) NOT NULL,
  stock      int NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now());
INSERT INTO r05.products (id, name, price, stock) VALUES (1, 'Tai nghe', 100000, 10), (2, 'Sạc', 50000, 5);
CREATE TABLE r05.product_audit (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  op         text NOT NULL,
  row_id     int NOT NULL,
  changed_at timestamptz NOT NULL DEFAULT now(),
  changed_by text NOT NULL DEFAULT current_user,
  old_row    jsonb,
  new_row    jsonb);
CREATE TABLE r05.product_audit2 (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  op         text NOT NULL,
  row_id     int NOT NULL,
  changed_at timestamptz NOT NULL DEFAULT now(),
  changes    jsonb);

-- (3) Nhật ký thay đổi có sẵn để dựng lại trạng thái quá khứ (ex04)
CREATE TABLE r05.audit_log (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name text NOT NULL,
  row_id     int NOT NULL,
  op         text NOT NULL CHECK (op IN ('INSERT', 'UPDATE', 'DELETE')),
  changed_at timestamptz NOT NULL,
  new_row    jsonb);                                   -- NULL khi DELETE
INSERT INTO r05.audit_log (table_name, row_id, op, changed_at, new_row) VALUES
  ('products', 1, 'INSERT', '2026-01-01 09:00+00', '{"name": "Tai nghe", "price": 100}'),
  ('products', 2, 'INSERT', '2026-01-05 09:00+00', '{"name": "Sạc", "price": 50}'),
  ('products', 1, 'UPDATE', '2026-02-01 09:00+00', '{"name": "Tai nghe", "price": 120}'),
  ('users',    1, 'UPDATE', '2026-02-10 09:00+00', '{"name": "Nhiễu", "price": 1}'),
  ('products', 2, 'DELETE', '2026-03-01 09:00+00', NULL),
  ('products', 3, 'INSERT', '2026-03-15 09:00+00', '{"name": "Ốp", "price": 30}'),
  ('products', 1, 'UPDATE', '2026-04-10 09:00+00', '{"name": "Tai nghe", "price": 150}'),
  ('products', 3, 'UPDATE', '2026-04-20 09:00+00', '{"name": "Ốp", "price": 35}'),
  ('products', 4, 'INSERT', '2026-04-25 09:00+00', '{"name": "Cáp", "price": 20}'),
  ('products', 1, 'UPDATE', '2026-05-20 09:00+00', '{"name": "Tai nghe", "price": 140}');

-- (4) SCD type 2: lịch sử giá. valid_to NULL = đang hiệu lực. Khoảng nửa mở [valid_from, valid_to)
CREATE TABLE r05.price_history (
  product_id int NOT NULL,
  price      numeric(12,2) NOT NULL,
  valid_from timestamptz NOT NULL,
  valid_to   timestamptz,
  PRIMARY KEY (product_id, valid_from));
INSERT INTO r05.price_history VALUES
  (1, 100, '2026-01-01 00:00+00', '2026-02-01 00:00+00'),
  (1, 120, '2026-02-01 00:00+00', '2026-04-10 00:00+00'),
  (1, 150, '2026-04-10 00:00+00', NULL),
  (2,  50, '2026-01-05 00:00+00', NULL);
CREATE TABLE r05.orders (id int PRIMARY KEY, product_id int NOT NULL, qty int NOT NULL, ordered_at timestamptz NOT NULL);
INSERT INTO r05.orders VALUES
  (1, 1, 2, '2026-01-15 10:00+00'),
  (2, 1, 1, '2026-02-01 00:00+00'),
  (3, 1, 3, '2026-03-01 10:00+00'),
  (4, 1, 1, '2026-04-10 00:00+00'),
  (5, 2, 4, '2026-05-01 10:00+00'),
  (6, 1, 1, '2026-05-15 10:00+00'),
  (7, 2, 1, '2026-01-02 10:00+00');

-- (5) Lịch sử giá bị lỗi: sản phẩm 1 có hai khoảng chồng nhau; sản phẩm 3 có khoảng trống (hợp lệ)
CREATE TABLE r05.price_history_bad (
  product_id int NOT NULL,
  price      numeric(12,2) NOT NULL,
  valid_from timestamptz NOT NULL,
  valid_to   timestamptz,
  PRIMARY KEY (product_id, valid_from));
INSERT INTO r05.price_history_bad VALUES
  (1, 100, '2026-01-01 00:00+00', '2026-03-01 00:00+00'),
  (1, 120, '2026-02-15 00:00+00', '2026-05-01 00:00+00'),
  (1, 130, '2026-05-01 00:00+00', NULL),
  (2,  50, '2026-01-01 00:00+00', '2026-02-01 00:00+00'),
  (2,  60, '2026-02-01 00:00+00', NULL),
  (3,  30, '2026-01-01 00:00+00', '2026-03-01 00:00+00'),
  (3,  35, '2026-04-01 00:00+00', NULL);
