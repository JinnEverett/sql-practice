-- sai: <= lấy luôn dòng cursor (id 9991) → lặp lại dòng cuối của trang trước
SELECT id, created_at, status, total_amount FROM orders
WHERE (created_at, id) <= ('2026-09-30 09:45:28.287597+00', 9991)
ORDER BY created_at DESC, id DESC LIMIT 10;
