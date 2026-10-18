-- db: lab
-- mode: state
-- Giải thích: MERGE với nguồn đã khử trùng. Thứ tự WHEN quan trọng: WHEN MATCHED AND qty = 0 phải đứng TRƯỚC WHEN MATCHED chung, vì MERGE lấy nhánh khớp đầu tiên. Không có WHEN NOT MATCHED BY SOURCE nên sản phẩm không có trong feed không bị đụng.
-- Bẫy: Đảo thứ tự 2 nhánh MATCHED → P-004 đi vào nhánh chung: stock = 0 nhưng vẫn is_active = true.
MERGE INTO f08.products p
USING (SELECT DISTINCT ON (sku) sku, name, qty, price FROM f08.stock_feed ORDER BY sku, received_at DESC) f ON f.sku = p.sku
WHEN MATCHED AND f.qty = 0 THEN UPDATE SET stock = 0, is_active = false, updated_at = now()
WHEN MATCHED THEN UPDATE SET stock = f.qty, price = COALESCE(f.price, p.price), is_active = true, updated_at = now()
WHEN NOT MATCHED THEN INSERT (sku, name, price, stock) VALUES (f.sku, f.name, f.price, f.qty);
