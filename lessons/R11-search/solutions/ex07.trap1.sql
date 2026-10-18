-- sai: plainto_tsquery bỏ qua toán tử loại trừ → ra đúng sản phẩm Sony
SELECT id, name FROM products WHERE to_tsvector('simple', unaccent(name)) @@ plainto_tsquery('simple', unaccent('"tai nghe" -sony')) ORDER BY id;
