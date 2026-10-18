-- sai: to_tsquery với đầu vào thô của người dùng → lỗi cú pháp
SELECT id, name FROM products WHERE to_tsvector('simple', unaccent(name)) @@ to_tsquery('simple', unaccent('"tai nghe" -sony')) ORDER BY id;
