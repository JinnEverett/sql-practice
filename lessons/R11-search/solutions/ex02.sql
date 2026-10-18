-- db: shop_s
-- ordered
-- expect-rows: 10
-- Giải thích: người dùng gõ có dấu lẫn không dấu ('áo thun' / 'ao thun'). Chuẩn hóa = bỏ dấu (unaccent) rồi chữ thường (lower) trước khi gom, và đếm số cách viết khác nhau.
--   unaccent là extension (có sẵn trong shop_*) và xử lý cả 'đ' → 'd'. Thứ tự lower/unaccent không quan trọng ở đây.
-- Bẫy: chỉ lower() (vẫn tách 'áo thun' và 'ao thun'); GROUP BY chuỗi gốc; quên lọc event_type = 'search' (event khác không có key query → NULL).
SELECT lower(unaccent(properties->>'query')) AS normalized_query,
       count(*) AS n_searches,
       count(DISTINCT properties->>'query') AS n_variants
FROM events
WHERE event_type = 'search'
GROUP BY 1
ORDER BY n_searches DESC, normalized_query;
