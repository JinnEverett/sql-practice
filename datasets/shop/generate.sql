-- Sinh dữ liệu cho schema shop. Tham số: -v N=<số đơn hàng>
-- Mọi bảng tăng theo N với tỉ lệ cố định; seed cố định nên cùng N luôn ra cùng dữ liệu.
-- Chỉ dùng INSERT ... SELECT generate_series (set-based), không lặp từng dòng.

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;  -- giữ thứ tự gọi random() ổn định giữa các lần chạy
SET work_mem = '256MB';                   -- chỉ cho phiên sinh dữ liệu
SELECT setseed(0.20241111) \g /dev/null

\set t0 '2024-01-01 00:00:00+07'
\set t1 '2026-09-30 23:59:59+07'

SELECT greatest(20, :N / 10)               AS u_count,
       greatest(50, least(:N / 50, 20000)) AS p_count,
       date '2026-09-30' - date '2024-01-01' AS d_count
\gset

\echo '  [1/6] categories'
-- Cây 3 tầng. lo/hi = khoảng giá (VND), kind = nhóm để chọn brand/thuộc tính. Hai cột này chỉ dùng khi sinh dữ liệu.
CREATE TEMP TABLE _cat (id, parent_id, name, slug, lo, hi, kind) AS VALUES
  ( 1, NULL::int, 'Thời trang',           'thoi-trang',        NULL::numeric, NULL::numeric, NULL::text),
  ( 2, NULL, 'Điện tử',                   'dien-tu',           NULL, NULL, NULL),
  ( 3, NULL, 'Nhà cửa & Đời sống',        'nha-cua-doi-song',  NULL, NULL, NULL),
  ( 4, NULL, 'Sách',                      'sach',              NULL, NULL, NULL),
  ( 5, NULL, 'Thể thao & Dã ngoại',       'the-thao-da-ngoai', NULL, NULL, NULL),
  ( 6, NULL, 'Làm đẹp',                   'lam-dep',           NULL, NULL, NULL),
  ( 7, NULL, 'Mẹ & Bé',                   'me-va-be',          NULL, NULL, NULL),
  ( 8, NULL, 'Thực phẩm',                 'thuc-pham',         NULL, NULL, NULL),
  ( 9,    1, 'Áo nam',                    'ao-nam',              99000,   800000, 'fashion'),
  (10,    1, 'Áo nữ',                     'ao-nu',               99000,   900000, 'fashion'),
  (11,    1, 'Giày dép',                  'giay-dep',           150000,  3000000, 'fashion'),
  (12,    1, 'Túi xách',                  'tui-xach',           150000,  5000000, 'fashion'),
  (13,    2, 'Điện thoại',                'dien-thoai',        2000000, 35000000, 'tech'),
  (14,    2, 'Laptop',                    'laptop',            8000000, 60000000, 'tech'),
  (15,    2, 'Phụ kiện điện tử',          'phu-kien-dien-tu',    50000,  1500000, 'tech'),
  (16,    2, 'Âm thanh',                  'am-thanh',           200000, 10000000, 'tech'),
  (17,    3, 'Nhà bếp',                   'nha-bep',             50000,  5000000, 'home'),
  (18,    3, 'Nội thất',                  'noi-that',           500000, 20000000, 'home'),
  (19,    3, 'Trang trí',                 'trang-tri',           50000,  2000000, 'home'),
  (20,    4, 'Sách tiếng Việt',           'sach-tieng-viet',     50000,   400000, 'book'),
  (21,    4, 'Sách ngoại văn',            'sach-ngoai-van',     150000,  1500000, 'book'),
  (22,    5, 'Dụng cụ tập luyện',         'dung-cu-tap-luyen',  100000, 15000000, 'sport'),
  (23,    5, 'Dã ngoại',                  'da-ngoai',           100000,  5000000, 'sport'),
  (24,    6, 'Chăm sóc da',               'cham-soc-da',         80000,  2000000, 'beauty'),
  (25,    6, 'Trang điểm',                'trang-diem',          80000,  1500000, 'beauty'),
  (26,    7, 'Đồ chơi',                   'do-choi',             50000,  3000000, 'kids'),
  (27,    7, 'Bỉm sữa',                   'bim-sua',            150000,  1000000, 'kids'),
  (28,    8, 'Đồ uống',                   'do-uong',             20000,   500000, 'food'),
  (29,    8, 'Đồ khô',                    'do-kho',              20000,   400000, 'food'),
  (30,    9, 'Áo thun nam',               'ao-thun-nam',         99000,   500000, 'fashion'),
  (31,    9, 'Áo sơ mi nam',              'ao-so-mi-nam',       199000,  1200000, 'fashion'),
  (32,   11, 'Giày chạy bộ',              'giay-chay-bo',       500000,  5000000, 'fashion'),
  (33,   11, 'Sandal',                    'sandal',             100000,  1500000, 'fashion'),
  (34,   16, 'Tai nghe',                  'tai-nghe',           150000,  8000000, 'tech'),
  (35,   16, 'Loa',                       'loa',                300000, 15000000, 'tech'),
  (36,   15, 'Cáp & sạc',                 'cap-sac',             50000,  1000000, 'tech'),
  (37,   15, 'Ốp lưng',                   'op-lung',             50000,   500000, 'tech'),
  (38,   20, 'Văn học',                   'van-hoc',             60000,   300000, 'book'),
  (39,   20, 'Kinh tế',                   'kinh-te',             80000,   400000, 'book'),
  (40,   20, 'Thiếu nhi',                 'thieu-nhi',           30000,   200000, 'book'),
  (41,   28, 'Cà phê',                    'ca-phe',              50000,   600000, 'food'),
  (42,   28, 'Trà',                       'tra',                 40000,   500000, 'food');

INSERT INTO categories (id, parent_id, name, slug)
SELECT id, parent_id, name, slug FROM _cat ORDER BY id;

\echo '  [2/6] users'
INSERT INTO users (id, email, full_name, phone, birth_date, country, city, created_at, deleted_at)
SELECT id,
       lower(unaccent(given)) || '.' || lower(unaccent(family)) || id || '@' || domain,
       CASE WHEN r_name >= 0.02 THEN family || ' ' || middle || ' ' || given END,
       CASE WHEN r_phone < 0.68 THEN '09' || lpad(phone_num::text, 8, '0')
            WHEN r_phone < 0.70 THEN '+84 9' || lpad(phone_num::text, 8, '0')
       END,
       CASE WHEN r_birth < 0.6 THEN date '1965-01-01' + floor(r_birth2 * 14600)::int END,
       country,
       CASE WHEN r_city < 0.05 THEN NULL
            WHEN city = 'TP. Hồ Chí Minh' AND r_city < 0.10
              THEN (ARRAY['TP.HCM', 'Ho Chi Minh', 'HCM'])[1 + floor(r_city2 * 3)::int]
            ELSE city
       END,
       created_at,
       CASE WHEN r_del < 0.02 THEN created_at + (:'t1'::timestamptz - created_at) * r_del2 END
FROM (
  SELECT g.*,
         CASE WHEN country = 'VN'
              THEN (ARRAY['TP. Hồ Chí Minh', 'TP. Hồ Chí Minh', 'TP. Hồ Chí Minh', 'Hà Nội', 'Hà Nội', 'Hà Nội',
                          'Đà Nẵng', 'Hải Phòng', 'Cần Thơ', 'Huế', 'Nha Trang'])[1 + floor(r_geo2 * 11)::int]
              ELSE CASE country WHEN 'SG' THEN 'Singapore' WHEN 'TH' THEN 'Bangkok' WHEN 'US' THEN 'San Jose'
                                WHEN 'JP' THEN 'Tokyo' WHEN 'KR' THEN 'Seoul' ELSE 'Sydney' END
         END AS city
  FROM (
    SELECT g AS id,
           (ARRAY['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ', 'Võ', 'Đặng', 'Bùi', 'Đỗ',
                  'Hồ', 'Ngô', 'Dương', 'Lý'])[1 + floor(random() ^ 1.8 * 16)::int] AS family,
           (ARRAY['Văn', 'Thị', 'Minh', 'Ngọc', 'Thanh', 'Hoàng', 'Quốc', 'Thu', 'Hải', 'Đức', 'Anh', 'Gia'])
             [1 + floor(random() * 12)::int] AS middle,
           (ARRAY['An', 'Bình', 'Châu', 'Dũng', 'Giang', 'Hà', 'Hải', 'Hạnh', 'Hiếu', 'Hoa', 'Hùng', 'Huy',
                  'Khánh', 'Lan', 'Linh', 'Long', 'Mai', 'Minh', 'Nam', 'Ngọc', 'Nhung', 'Phong', 'Phúc', 'Quân',
                  'Quang', 'Sơn', 'Tâm', 'Thảo', 'Trang', 'Trung', 'Tuấn', 'Uyên', 'Vy', 'Yến'])
             [1 + floor(random() * 34)::int] AS given,
           (ARRAY['gmail.com', 'gmail.com', 'gmail.com', 'gmail.com', 'yahoo.com', 'outlook.com', 'icloud.com',
                  'fpt.com.vn'])[1 + floor(random() * 8)::int] AS domain,
           CASE WHEN random() < 0.75 THEN 'VN'
                ELSE (ARRAY['SG', 'TH', 'US', 'JP', 'KR', 'AU'])[1 + floor(random() * 6)::int] END AS country,
           random() AS r_geo2,
           random() AS r_name, random() AS r_phone, floor(random() * 1e8)::bigint AS phone_num,
           random() AS r_birth, random() AS r_birth2, random() AS r_city, random() AS r_city2,
           random() AS r_del, random() AS r_del2,
           -- User cũ có id nhỏ; mật độ đăng ký tăng dần theo thời gian
           :'t0'::timestamptz
             + make_interval(secs => :d_count * 86400.0 * sqrt((g - 1)::float8 / :u_count) + random() * 60)
             AS created_at
    FROM generate_series(1, :u_count) g
  ) g
) x
ORDER BY id;

-- Email trùng có chủ đích (khác hoa/thường, thừa khoảng trắng). Xem DIRTY.md
UPDATE users u
SET email = CASE (u.id / 200) % 3
              WHEN 0 THEN upper(v.email)
              WHEN 1 THEN ' ' || v.email
              ELSE initcap(v.email) || ' '
            END
FROM users v
WHERE u.id % 200 = 7 AND v.id = u.id - 3;

\echo '  [3/6] products'
INSERT INTO products (id, category_id, sku, name, brand, price, stock, attributes, is_active, created_at)
SELECT p.id, p.cat_id, 'SKU-' || lpad(p.id::text, 6, '0'),
       c.name || ' ' || b.brand || ' ' || upper(substr(md5(p.id::text), 1, 4))
         || CASE WHEN p.r_ws < 0.005 THEN '  ' ELSE '' END,
       b.brand,
       CASE WHEN p.r_free < 0.003 THEN 0
            ELSE round(c.lo * exp(p.r_price::numeric * ln(c.hi / c.lo)), -3) END,
       CASE WHEN p.r_stock < 0.03 THEN 0 ELSE floor(p.r_stock2 ^ 2 * 500)::int END,
       jsonb_strip_nulls(jsonb_build_object(
         'color', CASE WHEN c.kind IN ('fashion', 'tech', 'home', 'sport') AND p.r_color < 0.97
                       THEN (ARRAY['đen', 'trắng', 'xám', 'xanh', 'đỏ', 'be'])[1 + floor(p.r_color2 * 6)::int] END,
         'weight_g', 50 + floor(p.r_w * 3000)::int,
         'size', CASE WHEN c.kind = 'fashion' THEN (ARRAY['S', 'M', 'L', 'XL'])[1 + floor(p.r_size * 4)::int] END,
         'warranty_months', CASE WHEN c.kind = 'tech' THEN (ARRAY[6, 12, 24])[1 + floor(p.r_size * 3)::int] END
       )),
       p.r_active >= 0.05,
       -- Danh mục sản phẩm có trước khi cửa hàng bắt đầu ghi nhận đơn
       timestamptz '2022-01-01 00:00:00+07'
         + make_interval(secs => 730 * 86400.0 * (p.id - 1) / :p_count + p.r_ws * 60)
FROM (
  SELECT g AS id, 9 + floor(random() * 34)::int AS cat_id,
         random() AS r_brand, random() AS r_price, random() AS r_free, random() AS r_stock, random() AS r_stock2,
         random() AS r_color, random() AS r_color2, random() AS r_w, random() AS r_size, random() AS r_active,
         random() AS r_ws
  FROM generate_series(1, :p_count) g
) p
JOIN _cat c ON c.id = p.cat_id
CROSS JOIN LATERAL (
  SELECT (CASE c.kind
            WHEN 'fashion' THEN ARRAY['Coolmate', 'Routine', 'Biti''s', 'Uniqlo', 'Nike', 'Adidas']
            WHEN 'tech'    THEN ARRAY['Apple', 'Samsung', 'Xiaomi', 'Sony', 'Anker', 'Asus']
            WHEN 'home'    THEN ARRAY['Lock&Lock', 'Sunhouse', 'IKEA', 'Điện Quang', 'Rạng Đông', 'Kangaroo']
            WHEN 'book'    THEN ARRAY['NXB Trẻ', 'Nhã Nam', 'Alpha Books', 'Kim Đồng', 'Penguin', 'O''Reilly']
            WHEN 'beauty'  THEN ARRAY['Cocoon', 'L''Oréal', 'Innisfree', 'La Roche-Posay', 'Maybelline', 'Some By Mi']
            WHEN 'food'    THEN ARRAY['Trung Nguyên', 'Phúc Long', 'Vinamilk', 'Highlands', 'TH true milk', 'Cozy']
            WHEN 'kids'    THEN ARRAY['Lego', 'Bobby', 'Huggies', 'Pigeon', 'Fisher-Price', 'Merries']
            ELSE                ARRAY['Decathlon', 'Nike', 'Adidas', 'Li-Ning', 'Coleman', 'Naturehike']
          END)[1 + floor(p.r_brand * 6)::int] AS brand
) b
ORDER BY p.id;

\echo '  [4/6] orders + order_items'
-- Bước 1: khung đơn hàng. Ngày đặt = tăng trưởng theo thời gian + đỉnh mùa sale (11/11, 12/12, Black Friday...)
-- Giờ đặt theo giờ Việt Nam, dồn vào 8h-23h; lưu dạng timestamptz (UTC).
CREATE TEMP TABLE _o AS
WITH raw AS MATERIALIZED (
  SELECT 1 + floor(:u_count * random() ^ 3)::bigint AS user_id,   -- lệch: user id nhỏ (user lâu năm) mua nhiều ("whale")
         random() AS r_kind, random() AS r_day, random() AS r_day2, random() AS r_time, random() AS r_time2,
         random() AS r_fix, random() AS r_fix2, random() AS r_status, random() AS r_items, random() AS r_disc,
         random() AS r_ship, random() AS r_upd, random() AS r_bad, random() AS r_bad2
  FROM generate_series(1, :N)
), timed AS (
  SELECT raw.*,
         ((CASE
             WHEN r_kind < 0.03 THEN (ARRAY[date '2024-11-11', date '2024-12-12', date '2025-11-11',
                                            date '2025-12-12', date '2026-09-09'])[1 + floor(r_day * 5)::int]
             WHEN r_kind < 0.15 THEN make_date(2024 + floor(r_day * 2)::int, 11, 1) + floor(r_day2 * 61)::int
             ELSE date '2024-01-01' + floor(:d_count * sqrt(r_day))::int
           END)
          + make_interval(secs => CASE WHEN r_time < 0.7 THEN 28800 + r_time2 * 54000 ELSE r_time2 * 86400 END)
         ) AT TIME ZONE 'Asia/Ho_Chi_Minh' AS ts0
  FROM raw
), fixed AS (
  SELECT t.*,
         CASE WHEN t.ts0 < u.created_at AND t.r_fix >= 0.0005   -- 0.05% cố ý để sai (đơn trước ngày đăng ký)
              THEN u.created_at + (:'t1'::timestamptz - u.created_at) * t.r_fix2
              ELSE t.ts0 END AS created_at
  FROM timed t JOIN users u ON u.id = t.user_id
)
SELECT row_number() OVER (ORDER BY created_at, user_id, r_status) AS id,
       user_id, created_at,
       CASE
         WHEN :'t1'::timestamptz - created_at < interval '3 days' THEN
           CASE WHEN r_status < 0.4 THEN 'pending' WHEN r_status < 0.7 THEN 'paid' ELSE 'shipped' END
         WHEN :'t1'::timestamptz - created_at < interval '10 days' THEN
           CASE WHEN r_status < 0.1 THEN 'paid' WHEN r_status < 0.55 THEN 'shipped'
                WHEN r_status < 0.95 THEN 'delivered' ELSE 'cancelled' END
         ELSE
           CASE WHEN r_status < 0.003 THEN 'pending'                -- đơn "treo" lâu ngày
                WHEN r_status < 0.09  THEN 'cancelled'
                WHEN r_status < 0.13  THEN 'refunded'
                ELSE 'delivered' END
       END AS status,
       1 + floor(r_items ^ 1.5 * 5)::int AS n_items,
       CASE WHEN r_disc < 0.15
            THEN (ARRAY['WELCOME10', 'VIP15', 'SALE20', 'FREESHIP'])[1 + floor(r_disc / 0.15 * 4)::int] END
         AS discount_code,
       CASE WHEN r_ship < 0.4 THEN 0 WHEN r_ship < 0.85 THEN 15000 ELSE 30000 END::numeric AS shipping_fee,
       r_upd, r_bad, r_bad2
FROM fixed;

-- Bước 2: dòng hàng. Sản phẩm phổ biến lệch về id nhỏ; 10% dòng có giá khác giá niêm yết hiện tại.
WITH li AS MATERIALIZED (
  SELECT o.id AS order_id, i AS line_no,
         1 + floor(:p_count * random() ^ 2)::bigint AS product_id,
         1 + floor(random() ^ 4 * 5)::int AS quantity,
         random() AS r_price, random() AS r_price2
  FROM _o o CROSS JOIN LATERAL generate_series(1, o.n_items) i
)
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price)
SELECT li.order_id, li.line_no, li.product_id, li.quantity,
       CASE WHEN li.r_price < 0.9 THEN p.price ELSE round(p.price * (0.7 + li.r_price2::numeric * 0.4), -3) END
FROM li JOIN products p ON p.id = li.product_id
ORDER BY li.order_id, li.line_no;

-- Bước 3: đơn hàng, tổng tiền tính từ dòng hàng (0.2% cố ý lệch, xem DIRTY.md)
WITH s AS (
  SELECT order_id, sum(quantity * unit_price) AS subtotal FROM order_items GROUP BY order_id
)
INSERT INTO orders (id, user_id, status, discount_code, shipping_fee, discount_amount, total_amount,
                    created_at, updated_at)
SELECT o.id, o.user_id, o.status, o.discount_code, o.shipping_fee, d.disc,
       s.subtotal + o.shipping_fee - d.disc
         + CASE WHEN o.r_bad < 0.002 THEN round((o.r_bad2 * 50)::numeric) * 1000 ELSE 0 END,
       o.created_at,
       least(o.created_at + CASE o.status
                              WHEN 'pending'   THEN interval '0'
                              WHEN 'paid'      THEN interval '5 minutes' * (1 + o.r_upd * 10)
                              WHEN 'shipped'   THEN interval '1 day' * (1 + o.r_upd)
                              WHEN 'delivered' THEN interval '1 day' * (2 + o.r_upd * 4)
                              WHEN 'cancelled' THEN interval '1 hour' * (1 + o.r_upd * 48)
                              ELSE                  interval '1 day' * (7 + o.r_upd * 14)  -- refunded
                            END,
             greatest(o.created_at, :'t1'::timestamptz))
FROM _o o
JOIN s ON s.order_id = o.id
CROSS JOIN LATERAL (
  SELECT CASE o.discount_code
           WHEN 'WELCOME10' THEN round(s.subtotal * 0.10, -3)
           WHEN 'VIP15'     THEN round(s.subtotal * 0.15, -3)
           WHEN 'SALE20'    THEN least(round(s.subtotal * 0.20, -3), 100000)
           WHEN 'FREESHIP'  THEN o.shipping_fee
           ELSE 0
         END AS disc
) d
ORDER BY o.id;

DROP TABLE _o;

\echo '  [5/6] payments'
WITH po AS MATERIALIZED (
  SELECT o.id, o.status, o.total_amount, o.created_at, o.updated_at,
         random() AS r_m, random() AS r_fail, random() AS r_dup, random() AS r_t, random() AS r_t2
  FROM orders o
  ORDER BY o.id
), m AS (
  SELECT po.*,
         CASE WHEN r_m < 0.55 THEN 'card' WHEN r_m < 0.75 THEN 'ewallet'
              WHEN r_m < 0.90 THEN 'bank_transfer' ELSE 'cod' END AS method,
         status IN ('paid', 'shipped', 'delivered', 'refunded') AS is_paid
  FROM po
), p AS (
  -- lần thanh toán thất bại
  SELECT id AS order_id, method, 'failed' AS status, total_amount AS amount,
         created_at + interval '1 minute' * (1 + r_t * 5) AS created_at
  FROM m WHERE (is_paid AND r_fail < 0.08) OR (status = 'cancelled' AND r_fail < 0.30)
  UNION ALL
  -- thanh toán thành công
  SELECT id, method, 'succeeded', total_amount, created_at + interval '1 minute' * (7 + r_t2 * 20)
  FROM m WHERE is_paid
  UNION ALL
  -- trừ tiền 2 lần (dữ liệu bẩn có chủ đích)
  SELECT id, method, 'succeeded', total_amount, created_at + interval '1 minute' * (7 + r_t2 * 20) + interval '3 seconds'
  FROM m WHERE is_paid AND status <> 'refunded' AND r_dup < 0.001
  UNION ALL
  -- hoàn tiền
  SELECT id, method, 'refunded', total_amount, updated_at
  FROM m WHERE status = 'refunded'
)
INSERT INTO payments (id, order_id, method, status, amount, created_at)
SELECT row_number() OVER (ORDER BY created_at, order_id, status), order_id, method, status, amount, created_at
FROM p
ORDER BY 1;

\echo '  [6/6] events'
-- Mỗi phiên truy cập (session) sinh 1-8 event cách nhau <= 150 giây. session_id KHÔNG được lưu:
-- muốn phân phiên phải tự suy ra từ khoảng cách thời gian (bài R07).
CREATE TEMP TABLE _s AS
WITH raw AS MATERIALIZED (
  SELECT g AS sid, random() AS r_user, 1 + floor(:u_count * random() ^ 2)::bigint AS uid,
         random() AS r_day, random() AS r_time, random() AS r_time2, random() AS r_dev, random() AS r_utm,
         random() AS r_fix, 1 + floor(random() ^ 2 * 8)::int AS n_ev
  FROM generate_series(1, :N) g
), timed AS (
  SELECT raw.*, CASE WHEN r_user < 0.7 THEN uid END AS user_id,
         ((date '2024-01-01' + floor(:d_count * sqrt(r_day))::int)
          + make_interval(secs => CASE WHEN r_time < 0.7 THEN 28800 + r_time2 * 54000 ELSE r_time2 * 86400 END)
         ) AT TIME ZONE 'Asia/Ho_Chi_Minh' AS ts0
  FROM raw
)
SELECT t.sid, t.user_id,
       CASE WHEN t.user_id IS NULL THEN 'anon-' || substr(md5(t.sid::text), 1, 12) END AS anonymous_id,
       CASE WHEN t.r_dev < 0.62 THEN 'mobile' WHEN t.r_dev < 0.95 THEN 'desktop' ELSE 'tablet' END AS device,
       CASE WHEN t.r_utm < 0.5 THEN NULL WHEN t.r_utm < 0.7 THEN 'google' WHEN t.r_utm < 0.85 THEN 'facebook'
            WHEN t.r_utm < 0.95 THEN 'tiktok' ELSE 'email' END AS utm_source,
       t.n_ev,
       CASE WHEN t.ts0 < u.created_at THEN u.created_at + (:'t1'::timestamptz - u.created_at) * t.r_fix
            ELSE t.ts0 END AS start_ts
FROM timed t LEFT JOIN users u ON u.id = t.user_id;

WITH ev AS MATERIALIZED (
  SELECT s.sid, s.user_id, s.anonymous_id, s.device, s.utm_source, i,
         s.start_ts + make_interval(secs => (i - 1) * 90 + random() * 60) AS created_at,
         CASE WHEN i = 1 THEN 'page_view'
              ELSE (ARRAY['page_view', 'product_view', 'product_view', 'product_view', 'search',
                          'add_to_cart', 'add_to_cart', 'checkout'])[1 + floor(random() * 8)::int] END AS event_type,
         1 + floor(:p_count * random() ^ 2)::bigint AS product_id,
         (ARRAY['áo thun', 'ao thun', 'tai nghe bluetooth', 'tai nghe', 'iphone 15', 'sạc nhanh', 'sach kinh te',
                'sách thiếu nhi', 'giày chạy bộ', 'giay chay bo', 'cà phê', 'laptop gaming'])
           [1 + floor(random() * 12)::int] AS term,
         random() AS r_dev
  FROM _s s CROSS JOIN LATERAL generate_series(1, s.n_ev) i
)
INSERT INTO events (id, user_id, anonymous_id, event_type, properties, created_at)
SELECT row_number() OVER (ORDER BY created_at, sid, i), user_id, anonymous_id, event_type,
       jsonb_strip_nulls(jsonb_build_object(
         'device',     CASE WHEN r_dev >= 0.01 THEN device END,      -- 1% thiếu key device
         'utm_source', CASE WHEN i = 1 THEN utm_source END,
         'product_id', CASE WHEN event_type IN ('product_view', 'add_to_cart') THEN product_id END,
         'query',      CASE WHEN event_type = 'search' THEN term END
       )),
       created_at
FROM ev
ORDER BY 1;

DROP TABLE _s;
DROP TABLE _cat;
