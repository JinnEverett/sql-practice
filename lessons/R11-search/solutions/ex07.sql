-- db: shop_s
-- ordered
-- expect-rows: 4
-- Giải thích: ô tìm kiếm của người dùng có cú pháp kiểu Google: "cụm từ", -loại trừ, OR. websearch_to_tsquery hiểu cú pháp đó và KHÔNG BAO GIỜ ném lỗi cú pháp với đầu vào bất kỳ
--   (to_tsquery thì lỗi với 'tai nghe -sony' vì thiếu toán tử; plainto_tsquery bỏ qua mọi toán tử và AND hết các từ).
--   `"tai nghe" -sony` → 'tai' <-> 'nghe' & !'sony' (cụm "tai nghe" liền nhau, và KHÔNG chứa 'sony'). Bỏ dấu đầu vào bằng unaccent cho khớp văn bản đã bỏ dấu.
-- Bẫy: plainto_tsquery coi '-sony' như từ 'sony' (trả đúng sản phẩm Sony thay vì loại trừ); to_tsquery('simple', 'tai nghe -sony') → syntax error 42601 với dữ liệu người dùng nhập.
SELECT id, name
FROM products
WHERE to_tsvector('simple', unaccent(name)) @@ websearch_to_tsquery('simple', unaccent('"tai nghe" -sony'))
ORDER BY id;
