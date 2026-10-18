-- db: lab
-- mode: state
-- Giải thích: DISTINCT ON (sku) … ORDER BY sku, received_at DESC lấy bản mới nhất mỗi sku; NOT EXISTS lọc sku đã có. Đây là anti join chuẩn.
-- Bẫy: Quên DISTINCT ON → P-010 xuất hiện 2 lần trong feed → lỗi unique (sku). Dùng NOT IN (SELECT sku …) cũng được ở đây vì sku NOT NULL, nhưng NOT EXISTS an toàn hơn với NULL.
INSERT INTO f08.products (sku, name, price, stock)
SELECT DISTINCT ON (f.sku) f.sku, f.name, f.price, f.qty
FROM f08.stock_feed f
WHERE NOT EXISTS (SELECT 1 FROM f08.products p WHERE p.sku = f.sku)
ORDER BY f.sku, f.received_at DESC;
