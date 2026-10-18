-- db: shop_m
-- mode: check
-- Giải thích: chỉ 3.3% đơn ở trạng thái chưa xong. Partial index trên created_at với WHERE bao trùm điều kiện query: 0.76 MB (so với 22.5 MB)
--   và 46 buffers (so với 218 của index đầy đủ, vốn phải lọc status trên hàng chục nghìn dòng). Planner chứng minh được
--   `status IN ('pending','paid')` ⇒ `status IN ('pending','paid','shipped')` nên dùng được index.
-- Bẫy: WHERE status = 'pending' (không suy ra được → Seq Scan + Sort 12 013 buffers); index (status, created_at) đầy đủ (đúng nhưng 20+ MB).
CREATE INDEX orders_open_idx ON orders (created_at) WHERE status IN ('pending', 'paid', 'shipped');
