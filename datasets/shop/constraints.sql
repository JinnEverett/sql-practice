-- Thêm ràng buộc SAU khi nạp dữ liệu (nhanh hơn nhiều so với kiểm tra từng dòng lúc INSERT).
-- Lưu ý: Postgres KHÔNG tự tạo index cho cột FK. Đây là chủ ý, bài học sẽ khai thác.
-- users.email cố tình KHÔNG có UNIQUE vì dữ liệu có email trùng (xem DIRTY.md).

ALTER TABLE categories
  ADD FOREIGN KEY (parent_id) REFERENCES categories (id),
  ADD UNIQUE (slug);

ALTER TABLE products
  ADD FOREIGN KEY (category_id) REFERENCES categories (id),
  ADD UNIQUE (sku),
  ADD CHECK (price >= 0),
  ADD CHECK (stock >= 0);

ALTER TABLE orders
  ADD FOREIGN KEY (user_id) REFERENCES users (id),
  ADD CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded'));

ALTER TABLE order_items
  ADD FOREIGN KEY (order_id) REFERENCES orders (id),
  ADD FOREIGN KEY (product_id) REFERENCES products (id),
  ADD CHECK (quantity > 0);

ALTER TABLE payments
  ADD FOREIGN KEY (order_id) REFERENCES orders (id),
  ADD CHECK (method IN ('card', 'ewallet', 'bank_transfer', 'cod')),
  ADD CHECK (status IN ('succeeded', 'failed', 'refunded'));

ALTER TABLE events
  ADD FOREIGN KEY (user_id) REFERENCES users (id);

-- Đồng bộ identity sequence sau khi nạp id tường minh
SELECT setval(pg_get_serial_sequence('users', 'id'), max(id)) FROM users;
SELECT setval(pg_get_serial_sequence('products', 'id'), max(id)) FROM products;
SELECT setval(pg_get_serial_sequence('orders', 'id'), max(id)) FROM orders;
SELECT setval(pg_get_serial_sequence('payments', 'id'), max(id)) FROM payments;
SELECT setval(pg_get_serial_sequence('events', 'id'), max(id)) FROM events;
