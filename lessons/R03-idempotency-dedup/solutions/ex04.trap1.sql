-- sai: tạo index khi dữ liệu còn trùng → lỗi 23505
CREATE UNIQUE INDEX payments_one_success_per_order ON r03.payments (order_id) WHERE status = 'succeeded';
