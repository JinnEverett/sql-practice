-- db: lab
-- mode: check
-- reset
-- Giải thích: quy tắc "mỗi đơn tối đa MỘT payment succeeded" là unique index PARTIAL: UNIQUE (order_id) WHERE status = 'succeeded'.
--   Dữ liệu cũ đang vi phạm nên phải dọn TRƯỚC khi tạo index: giữ payment succeeded sớm nhất của mỗi đơn, các bản sau chuyển thành 'refunded'
--   (không xóa: tiền đã trừ thật, kế toán cần dấu vết). Sau đó đơn có nhiều payment failed/refunded vẫn được.
-- Bẫy: tạo index trước khi dọn → lỗi 23505; DELETE các payment trùng → mất dấu vết giao dịch; UNIQUE (order_id, status) chặn luôn nhiều bản 'failed'.
UPDATE r03.payments p
SET status = 'refunded'
WHERE status = 'succeeded'
  AND EXISTS (SELECT 1 FROM r03.payments q
              WHERE q.order_id = p.order_id AND q.status = 'succeeded' AND q.id < p.id);
CREATE UNIQUE INDEX payments_one_success_per_order ON r03.payments (order_id) WHERE status = 'succeeded';
