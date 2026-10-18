-- R03 · dữ liệu nhỏ cho bài idempotency & dedup. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS r03 CASCADE;
CREATE SCHEMA r03;

-- (1) Event đã lưu + lô event mới nhận (có event trùng với bản đã lưu, và event trùng ngay trong lô)
CREATE TABLE r03.events (event_id text PRIMARY KEY, payload jsonb NOT NULL, received_at timestamptz NOT NULL);
INSERT INTO r03.events VALUES
  ('e1', '{"v": 1}', '2026-03-01 09:00+00'),
  ('e2', '{"v": 1}', '2026-03-01 09:01+00');
CREATE TABLE r03.inbox (event_id text NOT NULL, payload jsonb NOT NULL, received_at timestamptz NOT NULL);
INSERT INTO r03.inbox VALUES
  ('e2', '{"v": 9}', '2026-03-01 10:00+00'),
  ('e3', '{"v": 1}', '2026-03-01 10:00+00'),
  ('e3', '{"v": 2}', '2026-03-01 10:05+00'),
  ('e4', '{"v": 1}', '2026-03-01 10:02+00'),
  ('e5', '{"v": 1}', '2026-03-01 10:03+00'),
  ('e5', '{"v": 0}', '2026-03-01 09:59+00');

-- (2) Danh bạ có email trùng (khác hoa/thường, thừa khoảng trắng)
CREATE TABLE r03.contacts (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email      text NOT NULL,
  name       text NOT NULL,
  updated_at timestamptz NOT NULL);
INSERT INTO r03.contacts (email, name, updated_at) VALUES
  ('an@x.vn',       'An',        '2026-01-01 00:00+00'),
  ('AN@x.vn',       'An N',      '2026-02-01 00:00+00'),
  (' an@x.vn ',     'An Nguyen', '2026-02-01 00:00+00'),
  ('binh@x.vn',     'Binh',      '2026-01-05 00:00+00'),
  ('Binh@X.vn',     'Bình',      '2026-01-03 00:00+00'),
  ('chi@x.vn',      'Chi',       '2026-01-02 00:00+00'),
  ('dung@x.vn',     'Dũng',      '2026-03-01 00:00+00'),
  ('DUNG@x.vn ',    'Dung',      '2026-02-15 00:00+00'),
  ('em@x.vn',       'Em',        '2026-01-09 00:00+00');

-- (3) Payment bị trừ tiền hai/ba lần
CREATE TABLE r03.payments (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id   bigint NOT NULL,
  status     text NOT NULL CHECK (status IN ('succeeded', 'failed', 'refunded')),
  amount     numeric(12,2) NOT NULL,
  created_at timestamptz NOT NULL);
INSERT INTO r03.payments (order_id, status, amount, created_at) VALUES
  (10, 'succeeded', 500000, '2026-03-01 10:00:00+00'),
  (10, 'succeeded', 500000, '2026-03-01 10:00:03+00'),
  (11, 'failed',    120000, '2026-03-01 11:00:00+00'),
  (11, 'succeeded', 120000, '2026-03-01 11:05:00+00'),
  (12, 'succeeded',  80000, '2026-03-01 12:00:00+00'),
  (12, 'refunded',   80000, '2026-03-01 12:30:00+00'),
  (13, 'succeeded', 900000, '2026-03-01 13:00:00+00'),
  (13, 'succeeded', 900000, '2026-03-01 13:00:03+00'),
  (13, 'succeeded', 900000, '2026-03-01 13:00:06+00');

-- (4) Bảng cho hàm charge idempotent
CREATE TABLE r03.pay2 (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id   bigint NOT NULL,
  amount     numeric(12,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE r03.idem_keys (key text PRIMARY KEY, payment_id bigint);

-- (5) Bảng giá hiện tại và lô giá nhà cung cấp gửi tới
CREATE TABLE r03.price_feed (sku text PRIMARY KEY, price numeric(12,2) NOT NULL, src_updated_at timestamptz NOT NULL);
INSERT INTO r03.price_feed VALUES
  ('A1', 100, '2026-01-10 00:00+00'), ('A2', 200, '2026-01-10 00:00+00'),
  ('A3', 300, '2026-01-10 00:00+00'), ('A4', 400, '2026-01-10 00:00+00');
CREATE TABLE r03.price_batch (sku text NOT NULL, price numeric(12,2) NOT NULL, src_updated_at timestamptz NOT NULL);
INSERT INTO r03.price_batch VALUES
  ('A1', 110, '2026-02-01 00:00+00'),
  ('A2', 200, '2026-02-01 00:00+00'),
  ('A3', 350, '2026-01-05 00:00+00'),
  ('A5', 500, '2026-02-01 00:00+00'),
  ('A1', 120, '2026-02-05 00:00+00'),
  ('A4', 450, '2026-02-02 00:00+00');
