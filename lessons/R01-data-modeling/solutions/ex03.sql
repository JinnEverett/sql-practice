-- db: lab
-- mode: check
-- reset
-- Giải thích: tách theo phụ thuộc hàm (3NF): customers (customer_id → name, city), products (sku → name), orders (order_id → ngày, khách),
--   order_lines ((order_id, sku) → giá lúc bán, số lượng). Giá lúc bán ở lại trong order_lines vì nó là THUỘC TÍNH CỦA DÒNG HÀNG, không của sản phẩm.
--   Dữ liệu mâu thuẫn: lấy giá trị ở dòng có line_id LỚN NHẤT (DISTINCT ON … ORDER BY …, line_id DESC).
--   Tạo bảng cha trước, bảng con sau; khai báo PK/FK/CHECK/NOT NULL để dữ liệu sai không vào lại được.
-- Bẫy: SELECT DISTINCT customer_id, name, city trên bảng phẳng vẫn ra 2 dòng cho khách 2 → vi phạm PK; quên FK; quên CHECK qty > 0.
CREATE TABLE r01.customers (customer_id int PRIMARY KEY, name text NOT NULL, city text);
CREATE TABLE r01.products  (sku text PRIMARY KEY, name text NOT NULL);
CREATE TABLE r01.orders (
  order_id    int PRIMARY KEY,
  ordered_on  date NOT NULL,
  customer_id int NOT NULL REFERENCES r01.customers
);
CREATE TABLE r01.order_lines (
  order_id   int  NOT NULL REFERENCES r01.orders,
  sku        text NOT NULL REFERENCES r01.products,
  unit_price numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  qty        int  NOT NULL CHECK (qty > 0),
  PRIMARY KEY (order_id, sku)
);
INSERT INTO r01.customers
  SELECT DISTINCT ON (customer_id) customer_id, customer_name, customer_city FROM r01.flat_sales ORDER BY customer_id, line_id DESC;
INSERT INTO r01.products
  SELECT DISTINCT ON (sku) sku, product_name FROM r01.flat_sales ORDER BY sku, line_id DESC;
INSERT INTO r01.orders
  SELECT DISTINCT order_id, ordered_on, customer_id FROM r01.flat_sales;
INSERT INTO r01.order_lines
  SELECT order_id, sku, unit_price, qty FROM r01.flat_sales;
