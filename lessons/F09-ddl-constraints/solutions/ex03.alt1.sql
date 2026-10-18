-- dùng NO ACTION mặc định thay cho RESTRICT, index đặt tên
CREATE TABLE f09.c_orders (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id int NOT NULL REFERENCES f09.c_customers, created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE f09.c_order_items (order_id int REFERENCES f09.c_orders ON DELETE CASCADE, line_no smallint,
  product_id int NOT NULL REFERENCES f09.c_products ON DELETE NO ACTION, quantity int NOT NULL CHECK (quantity >= 1),
  PRIMARY KEY (order_id, line_no));
CREATE INDEX c_orders_customer_idx ON f09.c_orders (customer_id, created_at);
CREATE INDEX c_order_items_product_idx ON f09.c_order_items (product_id);
