-- sai: thiếu FK/CHECK, lấy DISTINCT nên khách 2 và sản phẩm VO ra 2 dòng → vi phạm PK
CREATE TABLE r01.customers (customer_id int PRIMARY KEY, name text NOT NULL, city text);
CREATE TABLE r01.products  (sku text PRIMARY KEY, name text NOT NULL);
CREATE TABLE r01.orders (order_id int PRIMARY KEY, ordered_on date NOT NULL, customer_id int NOT NULL);
CREATE TABLE r01.order_lines (order_id int NOT NULL, sku text NOT NULL, unit_price numeric(12,2) NOT NULL, qty int NOT NULL, PRIMARY KEY (order_id, sku));
INSERT INTO r01.customers SELECT DISTINCT customer_id, customer_name, customer_city FROM r01.flat_sales;
INSERT INTO r01.products SELECT DISTINCT sku, product_name FROM r01.flat_sales;
INSERT INTO r01.orders SELECT DISTINCT order_id, ordered_on, customer_id FROM r01.flat_sales;
INSERT INTO r01.order_lines SELECT order_id, sku, unit_price, qty FROM r01.flat_sales;
