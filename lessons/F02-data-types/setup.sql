-- F02 · Dữ liệu riêng của bài: mô phỏng các bảng "hệ thống cũ" chọn sai kiểu dữ liệu.
-- Chạy trên DB lab (idempotent, seed cố định):
--   MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d lab -v ON_ERROR_STOP=1 -X -q < lessons/F02-data-types/setup.sql

DROP SCHEMA IF EXISTS f02 CASCADE;
CREATE SCHEMA f02;
SELECT setseed(0.42);

-- Ví điện tử cũ lưu tiền tip (USD) bằng float. Mỗi giao dịch = tip gốc + tip bổ sung, cộng bằng float.
CREATE TABLE f02.legacy_wallet (
  id     integer PRIMARY KEY,
  amount double precision NOT NULL
);
INSERT INTO f02.legacy_wallet
SELECT g, (a * 0.1)::float8 + (b * 0.1)::float8
FROM (SELECT g, floor(random() * 5)::int AS a, floor(random() * 5)::int AS b
      FROM generate_series(1, 200) g) t;

-- Đơn sỉ B2B: hệ thống cũ lưu số lượng và đơn giá (VND) bằng integer.
CREATE TABLE f02.b2b_lines (
  id             integer PRIMARY KEY,
  qty            integer NOT NULL,
  unit_price_vnd integer NOT NULL
);
INSERT INTO f02.b2b_lines
SELECT g,
       (1 + floor(random() * 5000))::int,
       ((1 + floor(random() * 200)) * 10000)::int
FROM generate_series(1, 30) g;

-- Đối tác import từ nhiều nguồn: mã tham chiếu là UUID nhưng lưu bằng text, mỗi nguồn ghi một kiểu.
CREATE TABLE f02.partners (
  id           integer PRIMARY KEY,
  name         text NOT NULL,
  external_ref text NOT NULL
);
INSERT INTO f02.partners
SELECT g,
       'Đối tác ' || lpad(g::text, 2, '0'),
       CASE g % 4
         WHEN 0 THEN md5('partner' || g)::uuid::text                        -- chuẩn, chữ thường
         WHEN 1 THEN upper(md5('partner' || g)::uuid::text)                 -- chữ hoa
         WHEN 2 THEN '{' || md5('partner' || g)::uuid::text || '}'          -- có ngoặc nhọn
         ELSE md5('partner' || g)                                           -- không gạch nối
       END
FROM generate_series(1, 20) g;
-- Cùng một đối tác bị import 3 lần (id 21–23), mỗi lần một định dạng khác nhau.
INSERT INTO f02.partners VALUES
  (21, 'Công ty Giao Nhanh',     'A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11'),
  (22, 'Giao Nhanh (cũ)',        '{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}'),
  (23, 'GIAO NHANH JSC',         'a0eebc999c0b4ef8bb6d6bb9bd380a11'),
  (24, 'Giao Nhanh Express',     'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12');  -- khác 1 ký tự cuối

-- Đơn hàng từ hệ thống POS cũ: giờ đặt là giờ địa phương VN, lưu bằng timestamp KHÔNG có múi giờ.
-- is_paid là text, mỗi phiên bản POS ghi một kiểu.
CREATE TABLE f02.legacy_orders (
  id            integer PRIMARY KEY,
  created_local timestamp NOT NULL,   -- giờ Việt Nam (UTC+7)
  is_paid       text NOT NULL,
  total_vnd     bigint NOT NULL
);
INSERT INTO f02.legacy_orders
SELECT g,
       timestamp '2024-12-25 00:00' + random() * interval '380 days',
       (ARRAY['t','f','true','false','yes','no','Y','N','1','0','TRUE','False',' yes ','on','off'])
         [1 + floor(random() * 15)::int],
       ((1 + floor(random() * 500)) * 10000)::bigint
FROM generate_series(1, 120) g;
-- Các đơn sát giao thừa (giờ VN)
INSERT INTO f02.legacy_orders VALUES
  (121, '2025-01-01 03:00', 'yes',  500000),
  (122, '2025-01-01 06:59:59', 'no', 250000),
  (123, '2025-01-01 07:00', 'Y',    120000),
  (124, '2025-12-31 23:30', 't',    990000),
  (125, '2026-01-01 05:00', '1',    1500000),
  (126, '2026-01-01 07:00', 'TRUE', 300000),
  (127, '2026-01-01 09:15', 'f',    450000);

-- Kế hoạch trả góp: tổng tiền (VND, số nguyên) chia thành n kỳ.
CREATE TABLE f02.installment_plans (
  order_id integer PRIMARY KEY,
  total    bigint  NOT NULL,
  n        integer NOT NULL
);
INSERT INTO f02.installment_plans VALUES
  (1, 100000, 3), (2, 200000, 3), (3, 1200000, 12), (4, 999999, 6),
  (5, 2500002, 4), (6, 12345678, 12), (7, 5000000, 1), (8, 7, 2),
  (9, 3600000, 6), (10, 10000001, 3), (11, 450000, 4), (12, 18990000, 6);

ANALYZE f02.legacy_wallet, f02.b2b_lines, f02.partners, f02.legacy_orders, f02.installment_plans;
