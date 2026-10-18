-- db: shop_s
-- ordered
-- Giải thích: regexp_split_to_table(chuỗi, '\s+') tách một chuỗi thành NHIỀU DÒNG, mỗi dòng một từ. Chuẩn hóa unaccent+lower
--   trước khi tách để 'Áo' và 'ao' là một từ. Rồi đếm từ như bảng thường.
-- Bẫy: tách bằng ' ' (một khoảng trắng) → hai khoảng trắng liền nhau sinh từ rỗng; quên bỏ dấu.
SELECT token, count(*) AS n
FROM events,
     regexp_split_to_table(lower(unaccent(trim(properties->>'query'))), '\s+') AS token
WHERE event_type = 'search'
GROUP BY token
ORDER BY n DESC, token
LIMIT 10;
