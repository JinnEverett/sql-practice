-- sai: OFFSET 50 (đếm trang từ 0 nhầm thành trang 6)
SELECT id, created_at, status, total_amount FROM orders ORDER BY created_at DESC, id DESC LIMIT 10 OFFSET 50;
