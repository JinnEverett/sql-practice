-- db: lab
-- mode: state
-- Giải thích: UPDATE … FROM một bảng dẫn xuất đã khử trùng (DISTINCT ON). COALESCE(f.price, p.price) giữ giá cũ khi feed NULL. Dòng không khớp JOIN tự nhiên không bị đụng.
-- Bẫy: UPDATE … FROM f08.stock_feed trực tiếp: P-002 khớp 2 dòng feed, Postgres chọn một dòng BẤT KỲ (không báo lỗi) → kết quả không xác định. Luôn khử trùng nguồn trước.
UPDATE f08.products p
SET stock = f.qty, price = COALESCE(f.price, p.price), updated_at = now()
FROM (SELECT DISTINCT ON (sku) sku, qty, price FROM f08.stock_feed ORDER BY sku, received_at DESC) f
WHERE f.sku = p.sku;
