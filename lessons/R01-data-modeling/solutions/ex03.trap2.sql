-- sai: dữ liệu đúng nhưng không có ràng buộc nào (FK, CHECK) → dữ liệu sai vẫn chui vào được
CREATE TABLE r01.customers (customer_id int PRIMARY KEY, name text NOT NULL, city text);
CREATE TABLE r01.products  (sku text PRIMARY KEY, name text NOT NULL);
CREATE TABLE r01.orders (order_id int PRIMARY KEY, ordered_on date NOT NULL, customer_id int);
CREATE TABLE r01.order_lines (order_id int, sku text, unit_price numeric(12,2), qty int, PRIMARY KEY (order_id, sku));
INSERT INTO r01.customers SELECT DISTINCT ON (customer_id) customer_id, customer_name, customer_city FROM r01.flat_sales ORDER BY customer_id, line_id DESC;
INSERT INTO r01.products SELECT DISTINCT ON (sku) sku, product_name FROM r01.flat_sales ORDER BY sku, line_id DESC;
INSERT INTO r01.orders SELECT DISTINCT order_id, ordered_on, customer_id FROM r01.flat_sales;
INSERT INTO r01.order_lines SELECT order_id, sku, unit_price, qty FROM r01.flat_sales;
