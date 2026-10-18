-- R01 · dữ liệu "di sản" để luyện chuẩn hóa. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS r01 CASCADE;
CREATE SCHEMA r01;

-- (1) Đơn hàng cũ: cột items nhét nhiều giá trị vào một ô ("sku:số lượng", ngăn bằng dấu phẩy) → vi phạm 1NF
CREATE TABLE r01.legacy_orders (order_no int PRIMARY KEY, customer text NOT NULL, items text NOT NULL);
INSERT INTO r01.legacy_orders VALUES
  (1001, 'An',   'BUT:10,VO:5'),
  (1002, 'Bình', 'BUT:3'),
  (1003, 'Chi',  'THUOC:1,BUT:4,VO:2'),
  (1004, 'An',   'VO:6,THUOC:2');

-- (2) Bảng bán hàng "phẳng": mọi thứ trong một bảng. Mỗi dòng = một dòng hàng của một đơn.
CREATE TABLE r01.flat_sales (
  line_id int PRIMARY KEY, order_id int NOT NULL, ordered_on date NOT NULL,
  customer_id int NOT NULL, customer_name text NOT NULL, customer_city text,
  sku text NOT NULL, product_name text NOT NULL, unit_price numeric(12,2) NOT NULL, qty int NOT NULL);
INSERT INTO r01.flat_sales VALUES
  ( 1, 1, '2026-01-05', 1, 'Nguyễn An',  'Hà Nội', 'BUT',   'Bút bi',      5000, 10),
  ( 2, 1, '2026-01-05', 1, 'Nguyễn An',  'Hà Nội', 'VO',    'Vở 96 trang', 12000, 5),
  ( 3, 2, '2026-01-09', 2, 'Trần Bình',  'TP.HCM', 'BUT',   'Bút bi',      5000, 3),
  ( 4, 2, '2026-01-09', 2, 'Trần Bình',  'Sài Gòn','VO',    'Vở 96 trang', 12000, 2),
  ( 5, 3, '2026-02-01', 3, 'Lê Chi',     'Đà Nẵng','THUOC', 'Thước kẻ',    8000, 1),
  ( 6, 3, '2026-02-01', 3, 'Lê Chi',     'Đà Nẵng','BUT',   'Bút bi',      5500, 4),
  ( 7, 4, '2026-02-10', 4, 'Phạm Dũng',  'Huế',    'VO',    'Vở 96 tr.',   12000, 6),
  ( 8, 4, '2026-02-10', 4, 'Phạm Dũng',  'Huế',    'THUOC', 'Thước kẻ',    8000, 2),
  ( 9, 5, '2026-03-02', 1, 'Nguyễn An',  'Hà Nội', 'THUOC', 'Thước kẻ',    8000, 2),
  (10, 6, '2026-03-15', 3, 'Lê Chi',     'Đà Nẵng','VO',    'Vở 96 trang', 12500, 2);

-- (3) Bảng giá theo khu vực: region NULL = giá toàn quốc
CREATE TABLE r01.price_list (product_id int NOT NULL, region text, price numeric(12,2) NOT NULL);

-- (4) Danh mục sản phẩm (đã chuẩn) để gắn tag
CREATE TABLE r01.catalog (id int PRIMARY KEY, name text NOT NULL);
INSERT INTO r01.catalog VALUES (1, 'Tai nghe'), (2, 'Sạc nhanh'), (3, 'Ốp lưng');

-- (5) Số điện thoại của user
CREATE TABLE r01.user_phones (user_id int NOT NULL, phone text NOT NULL, is_primary boolean NOT NULL DEFAULT false);
