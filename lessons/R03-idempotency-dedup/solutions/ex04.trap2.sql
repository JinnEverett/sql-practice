-- sai: xóa các bản trùng thay vì đánh dấu refunded; và UNIQUE (order_id, status) cũng chặn nhiều bản failed
DELETE FROM r03.payments p WHERE status = 'succeeded' AND EXISTS (SELECT 1 FROM r03.payments q WHERE q.order_id = p.order_id AND q.status = 'succeeded' AND q.id < p.id);
CREATE UNIQUE INDEX payments_one_success_per_order ON r03.payments (order_id, status);
