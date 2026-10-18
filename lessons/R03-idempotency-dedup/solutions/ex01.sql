-- db: lab
-- mode: state
-- Giải thích: lô event có hai kiểu trùng: (a) trùng với event ĐÃ lưu (e2) → bỏ qua, không ghi đè: ON CONFLICT (event_id) DO NOTHING;
--   (b) trùng NGAY TRONG lô (e3, e5) → phải chọn đúng một bản (mới nhất theo received_at) bằng DISTINCT ON TRƯỚC khi chèn.
--   Nếu không, DO NOTHING giữ bản nào đến trước (thứ tự không đảm bảo) chứ không phải bản mới nhất.
-- Bẫy: INSERT … SELECT trơn → lỗi 23505 ở e2; DO UPDATE trong lô có trùng → lỗi "cannot affect row a second time"; DO NOTHING không dedupe → giữ nhầm e3 v1.
INSERT INTO r03.events (event_id, payload, received_at)
SELECT DISTINCT ON (event_id) event_id, payload, received_at
FROM r03.inbox
ORDER BY event_id, received_at DESC
ON CONFLICT (event_id) DO NOTHING;
