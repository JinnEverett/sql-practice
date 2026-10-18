-- F03 · Dữ liệu riêng của bài: các bảng có NULL và chuỗi rỗng đặt ở chỗ dễ sập bẫy.
-- Chạy trên DB lab (idempotent, seed cố định):
--   MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d lab -v ON_ERROR_STOP=1 -X -q < lessons/F03-null/setup.sql

DROP SCHEMA IF EXISTS f03 CASCADE;
CREATE SCHEMA f03;
SELECT setseed(0.33);

-- Danh bạ import từ file Excel: city có thể NULL, chuỗi rỗng, hoặc chỉ toàn khoảng trắng.
CREATE TABLE f03.contacts (
  id   integer PRIMARY KEY,
  name text NOT NULL,
  city text
);
INSERT INTO f03.contacts
SELECT g,
       'Liên hệ ' || lpad(g::text, 2, '0'),
       CASE
         WHEN g % 7 = 0 THEN NULL
         WHEN g % 9 = 0 THEN ''
         WHEN g % 11 = 0 THEN '   '
         ELSE (ARRAY['Hà Nội','Đà Nẵng','Huế','Cần Thơ','Hải Phòng'])[1 + floor(random() * 5)::int]
       END
FROM generate_series(1, 30) g;

-- Sản phẩm import từ nhà cung cấp: brand NULL = chưa xác định.
CREATE TABLE f03.products_import (
  id    integer PRIMARY KEY,
  name  text NOT NULL,
  brand text
);
INSERT INTO f03.products_import
SELECT g,
       'SP-' || lpad(g::text, 3, '0'),
       CASE WHEN random() < 0.25 THEN NULL
            ELSE (ARRAY['Sony','Samsung','Apple','Xiaomi'])[1 + floor(random() * 4)::int] END
FROM generate_series(1, 40) g;

-- Chiến dịch quảng cáo: impressions = 0 khi chưa chạy; clicks NULL khi đối tác chưa gửi số liệu.
CREATE TABLE f03.campaigns (
  id          integer PRIMARY KEY,
  name        text NOT NULL,
  impressions integer NOT NULL,
  clicks      integer
);
INSERT INTO f03.campaigns VALUES
  (1,  'Back to school',   120000, 2400),
  (2,  'Mid-autumn',        80000, 1000),
  (3,  'Flash 9/9',        250000, 7500),
  (4,  'Tết sớm',               0,    0),
  (5,  'Brand day',         45000, NULL),
  (6,  'Free ship',         60000,  900),
  (7,  'Retarget T9',        3000,  150),
  (8,  'TikTok test',           0, NULL),
  (9,  'Zalo OA',           15000,  120),
  (10, 'Google Search',     30000, 1800),
  (11, 'Newsletter',         9000,    0),
  (12, 'KOL review',        70000, 2100);

-- Đánh giá sản phẩm: rating NULL = khách để lại bình luận nhưng không chấm sao.
CREATE TABLE f03.reviews (
  id         integer PRIMARY KEY,
  product_id integer NOT NULL,
  rating     smallint CHECK (rating BETWEEN 1 AND 5)
);
INSERT INTO f03.reviews
SELECT g,
       1 + (g % 3),
       CASE WHEN random() < 0.3 THEN NULL ELSE 1 + floor(random() * 5)::int END
FROM generate_series(1, 60) g;

-- Nhật ký cập nhật hồ sơ: giá trị cũ và mới của phone, city. NULL = chưa có thông tin.
CREATE TABLE f03.profile_changes (
  id        integer PRIMARY KEY,
  user_id   integer NOT NULL,
  old_phone text, new_phone text,
  old_city  text, new_city  text
);
INSERT INTO f03.profile_changes VALUES
  (1,  101, '0901111111', '0901111111', 'Hà Nội',  'Hà Nội'),     -- không đổi
  (2,  102, '0902222222', '0912222222', 'Huế',     'Huế'),        -- đổi phone
  (3,  103, NULL,         '0903333333', 'Huế',     'Huế'),        -- NULL → có phone
  (4,  104, '0904444444', NULL,         'Cần Thơ', 'Cần Thơ'),    -- xóa phone
  (5,  105, NULL,         NULL,         NULL,      NULL),         -- không đổi (toàn NULL)
  (6,  106, '0906666666', '0906666666', NULL,      'Đà Nẵng'),    -- NULL → có city
  (7,  107, '0907777777', '0907777777', 'Đà Nẵng', NULL),        -- xóa city
  (8,  108, NULL,         NULL,         'Hà Nội',  'Hải Phòng'),  -- đổi city
  (9,  109, '0909999999', '0909999999', 'Huế',     'Huế'),        -- không đổi
  (10, 110, NULL,         NULL,         'Hà Nội',  'Hà Nội'),     -- không đổi
  (11, 111, '0911111111', '0911111112', NULL,      NULL),         -- đổi phone
  (12, 112, NULL,         '0912121212', NULL,      'Huế'),        -- cả hai từ NULL
  (13, 113, '0913131313', '0913131313', 'Cần Thơ', 'Cần Thơ'),    -- không đổi
  (14, 114, '0914141414', NULL,         'Huế',     NULL),         -- xóa cả hai
  (15, 115, NULL,         NULL,         'Hải Phòng','Hải Phòng'); -- không đổi

ANALYZE f03.contacts, f03.products_import, f03.campaigns, f03.reviews, f03.profile_changes;
