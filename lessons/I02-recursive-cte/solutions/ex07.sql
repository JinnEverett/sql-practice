-- db: lab
-- reset
-- ordered
-- Giải thích: neo = các chuyến đi từ SGN (1 chặng). Đệ quy: nối thêm chuyến từ điểm cuối hiện tại, với hai điều kiện dừng:
--   chưa quá 3 chặng (tối đa 2 lần nối chuyến) và không quay lại sân bay đã qua (mảng visited). Cuối cùng lọc tuyến kết thúc ở HAN.
-- Bẫy: quên giới hạn chặng → tuyến SGN→VCA→CXR→DAD→HAN (4 chặng, 1 250 000) lọt lên đầu; không chặn quay vòng
--   (ở đây giới hạn chặng vẫn làm query dừng, nhưng sinh tuyến vô nghĩa kiểu SGN→DAD→SGN→HAN).
WITH RECURSIVE r AS (
  SELECT dst AS at, ARRAY['SGN', dst] AS visited, 1 AS legs, price AS total_price
  FROM i02.flights
  WHERE src = 'SGN'
  UNION ALL
  SELECT f.dst, r.visited || f.dst, r.legs + 1, r.total_price + f.price
  FROM r
  JOIN i02.flights f ON f.src = r.at
  WHERE r.legs < 3 AND NOT f.dst = ANY (r.visited)
)
SELECT array_to_string(visited, '→') AS route, legs, total_price
FROM r
WHERE at = 'HAN'
ORDER BY total_price, route
LIMIT 3;
