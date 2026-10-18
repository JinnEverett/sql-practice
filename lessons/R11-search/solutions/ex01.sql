-- db: shop_s
-- ordered
-- expect-rows: 5
-- Giải thích: full-text search (FTS) biến văn bản thành tsvector (danh sách từ đã chuẩn hóa + vị trí) và câu hỏi thành tsquery; toán tử @@ kiểm tra khớp.
--   Tiếng Việt không có stemmer/stopword sẵn trong Postgres nên dùng cấu hình 'simple' (chỉ tách từ theo khoảng trắng/dấu câu, đưa về chữ thường).
--   plainto_tsquery('simple', 'tai nghe') = 'tai' & 'nghe': tên sản phẩm phải chứa CẢ HAI từ, không phân biệt hoa/thường, không cần đứng cạnh nhau.
-- Bẫy: name LIKE '%tai nghe%' phân biệt hoa/thường nên bỏ sót 'Tai nghe …' (T hoa); config 'english' bỏ/biến đổi từ theo tiếng Anh.
SELECT id, name
FROM products
WHERE to_tsvector('simple', name) @@ plainto_tsquery('simple', 'tai nghe')
ORDER BY id;
