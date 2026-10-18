-- db: shop_s
-- ordered
-- Giải thích: unaccent() (extension, đã cài trong shop_*) bỏ dấu tiếng Việt: 'giày chạy bộ' → 'giay chay bo'. Chuẩn hóa thêm
--   lower(trim()). Gom theo dạng chuẩn hóa; count(DISTINCT raw) cho biết có bao nhiêu cách gõ khác nhau.
-- Bẫy: gom theo chuỗi gốc → 'áo thun' và 'ao thun' tách thành 2 dòng; unaccent nhưng không lower.
SELECT lower(trim(unaccent(properties->>'query'))) AS query_norm,
       count(*) AS n_searches,
       count(DISTINCT properties->>'query') AS n_variants
FROM events
WHERE event_type = 'search'
GROUP BY 1
ORDER BY n_searches DESC, query_norm;
