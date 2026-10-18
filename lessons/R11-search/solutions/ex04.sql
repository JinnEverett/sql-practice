-- db: shop_m
-- ordered
-- expect-rows: 5
-- Giải thích: fuzzy search chịu lỗi gõ sai bằng độ giống trigram (pg_trgm): chuỗi được cắt thành các bộ ba ký tự và similarity = tỉ lệ bộ ba chung (0..1).
--   Toán tử % trả true khi similarity > ngưỡng (mặc định 0.3, chỉnh bằng pg_trgm.similarity_threshold) và dùng được index GIN/GiST trigram.
--   Bỏ dấu CẢ HAI PHÍA trước khi so (lower() chỉ để rõ ý, vì pg_trgm đã bỏ qua hoa/thường), vì pg_trgm không phân biệt hoa/thường nhưng PHÂN BIỆT dấu ('ốp' ≠ 'op'). Sắp xếp similarity giảm dần, id làm tie-breaker.
-- Bẫy: ILIKE '%op lung samsug%' không khớp gì (gõ sai); so sánh name có dấu với chuỗi không dấu → similarity thấp; thiếu tie-breaker (nhiều sản phẩm cùng điểm).
SELECT id, name, round(similarity(lower(unaccent(name)), 'op lung samsug')::numeric, 3) AS sim
FROM products
WHERE lower(unaccent(name)) % 'op lung samsug'
ORDER BY sim DESC, id
LIMIT 5;
