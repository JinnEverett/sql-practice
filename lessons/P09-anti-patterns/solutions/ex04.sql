-- db: shop_m
-- mode: check
-- Giải thích: OFFSET N buộc đọc và bỏ N dòng: Sort 1M dòng tràn đĩa (32 MB), 11 000+ buffers, chi phí tăng tuyến tính theo trang. Keyset pagination: nhớ khóa của dòng cuối trang trước
--   và hỏi tiếp "những dòng sau khóa đó": `(created_at, id) < (…)` + index khớp ORDER BY → đọc đúng 20 dòng, chi phí hằng số cho mọi trang.
--   Cần khóa DUY NHẤT (thêm id vì created_at có thể trùng) và so sánh theo cặp (row comparison).
-- Bẫy: chỉ `created_at < X` (bỏ sót/trùng dòng cùng thời điểm); keyset mà thiếu index (vẫn Sort); đổi ORDER BY của index lệch với query.
CREATE INDEX ON orders (created_at DESC, id DESC);
-- query
SELECT id, created_at, total_amount FROM orders
WHERE (created_at, id) < ('2025-02-21 05:57:20.456226+00', 100001)
ORDER BY created_at DESC, id DESC LIMIT 20;
