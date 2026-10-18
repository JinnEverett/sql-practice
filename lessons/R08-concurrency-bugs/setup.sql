-- R08 · các bảng nhỏ để tái hiện lỗi đồng thời. Chạy trên DB `lab`. Chạy lại được nhiều lần.
CREATE EXTENSION IF NOT EXISTS btree_gist;
DROP SCHEMA IF EXISTS r08 CASCADE;
CREATE SCHEMA r08;

-- (1) Bộ đếm (lost update)
CREATE TABLE r08.counters (id int PRIMARY KEY, n int NOT NULL);
INSERT INTO r08.counters VALUES (1, 0);

-- (2) Tồn kho và đơn hàng (oversell). CHECK (stock >= 0) là hàng rào cuối cùng.
CREATE TABLE r08.products (
  id      int PRIMARY KEY,
  name    text NOT NULL,
  stock   int NOT NULL CHECK (stock >= 0),
  price   numeric(12,2) NOT NULL,
  version int NOT NULL DEFAULT 0);
INSERT INTO r08.products VALUES (1, 'Tai nghe', 2, 100000, 0), (2, 'Sạc', 3, 50000, 0), (3, 'Cáp', 10, 20000, 0);
CREATE TABLE r08.orders (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id int NOT NULL REFERENCES r08.products,
  qty        int NOT NULL CHECK (qty > 0),
  created_at timestamptz NOT NULL DEFAULT now());

-- (3) Đặt phòng (double booking)
CREATE TABLE r08.bookings (
  id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id int NOT NULL,
  during  tstzrange NOT NULL,
  status  text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')));
INSERT INTO r08.bookings (room_id, during, status) VALUES
  (1, '[2026-03-01 09:00+00, 2026-03-01 10:00+00)', 'confirmed'),
  (1, '[2026-03-01 10:00+00, 2026-03-01 11:00+00)', 'confirmed'),
  (1, '[2026-03-01 09:30+00, 2026-03-01 10:30+00)', 'cancelled');

-- (4) Bác sĩ trực (write skew): luôn phải còn ít nhất một người trực
CREATE TABLE r08.doctors (id int PRIMARY KEY, name text NOT NULL, on_call boolean NOT NULL);
INSERT INTO r08.doctors VALUES (1, 'BS An', true), (2, 'BS Bình', true), (3, 'BS Chi', false);

-- (5) Chuyển tiền (deadlock). Hàm cố ý có pg_sleep(0.5) giữa hai lệnh UPDATE để mô phỏng logic nghiệp vụ chậm.
CREATE TABLE r08.accounts (id int PRIMARY KEY, balance numeric(12,2) NOT NULL CHECK (balance >= 0));
INSERT INTO r08.accounts VALUES (1, 100), (2, 100);
CREATE FUNCTION r08.transfer(p_from int, p_to int, p_amount numeric) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r08.accounts SET balance = balance - p_amount WHERE id = p_from;
  PERFORM pg_sleep(0.5);                                   -- giả lập xử lý nghiệp vụ chậm; GIỮ NGUYÊN dòng này
  UPDATE r08.accounts SET balance = balance + p_amount WHERE id = p_to;
END $$;
