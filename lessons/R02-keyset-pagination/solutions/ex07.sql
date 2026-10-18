-- db: lab
-- reset
-- ordered
-- expect-rows: 7
-- Giải thích: "trang trước" = 7 dòng đứng NGAY TRƯỚC dòng đầu trang hiện tại. Đảo chiều: lấy các dòng (created_at, id) > cursor theo thứ tự TĂNG,
--   LIMIT 7 (7 dòng gần cursor nhất), rồi đảo lại bằng ORDER BY ngoài để hiển thị theo thứ tự giảm như mọi trang khác.
-- Bẫy: giữ ORDER BY giảm cùng điều kiện > rồi LIMIT 7 sẽ lấy 7 dòng MỚI NHẤT của cả bảng, không phải 7 dòng sát cursor.
SELECT id, created_at, title
FROM (
  SELECT id, created_at, title
  FROM r02.feed
  WHERE (created_at, id) > ('2026-01-01 00:10+00', 52)
  ORDER BY created_at ASC, id ASC
  LIMIT 7
) prev
ORDER BY created_at DESC, id DESC;
