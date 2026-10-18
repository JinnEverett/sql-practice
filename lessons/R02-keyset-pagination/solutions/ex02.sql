-- db: shop_s
-- ordered
-- expect-rows: 10
-- Giải thích: keyset = "lấy các dòng đứng SAU dòng cuối của trang trước" thay vì đếm bỏ qua. Với thứ tự (created_at DESC, id DESC),
--   "sau" nghĩa là (created_at, id) < (cursor_ts, cursor_id). So sánh row-value (a, b) < (x, y) là so từ điển, đúng ngữ nghĩa và dùng được index.
--   Chi phí không phụ thuộc vị trí trang: B-tree nhảy thẳng tới cursor.
-- Bẫy: created_at < cursor_ts một mình bỏ sót các dòng cùng created_at nhưng id nhỏ hơn.
SELECT id, created_at, status, total_amount
FROM orders
WHERE (created_at, id) < ('2026-09-30 09:45:28.287597+00', 9991)
ORDER BY created_at DESC, id DESC
LIMIT 10;
