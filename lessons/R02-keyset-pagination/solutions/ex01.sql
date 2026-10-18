-- db: shop_s
-- ordered
-- expect-rows: 10
-- Giải thích: trang n (kích thước k) = OFFSET (n-1)*k LIMIT k. Sắp xếp PHẢI duy nhất (thêm id làm tie-breaker), nếu không hai lần chạy
--   có thể trả về thứ tự trùng khóa khác nhau và trang bị lặp/thiếu dòng.
-- Bẫy: trang 5 → OFFSET 40 (không phải 50); ORDER BY created_at DESC một mình không duy nhất.
SELECT id, created_at, status, total_amount
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 10 OFFSET 40;
