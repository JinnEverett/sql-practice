-- db: lab
-- mode: state
-- Giải thích: DELETE … USING là JOIN cho DELETE. Ngoặc quanh OR là bắt buộc vì AND ưu tiên hơn OR.
-- Bẫy: Thiếu ngoặc: p.id = c.product_id AND NOT p.is_active OR p.stock = 0 → vế stock = 0 không còn gắn với JOIN, xóa nhầm cả giỏ.
DELETE FROM f08.cart_items c USING f08.products p WHERE p.id = c.product_id AND (NOT p.is_active OR p.stock = 0);
