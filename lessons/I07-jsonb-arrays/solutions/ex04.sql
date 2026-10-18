-- db: shop_s
-- ordered
-- Giải thích: jsonb_object_keys(obj) là hàm sinh nhiều dòng (mỗi key một dòng). Đặt trong FROM (LATERAL ngầm) rồi gom.
--   jsonb_typeof cho biết kiểu giá trị ('string', 'number', 'null'…), hữu ích khi khám phá dữ liệu bán cấu trúc.
-- Bẫy: count(DISTINCT id) thay vì count(*) (như nhau ở đây vì key không trùng trong 1 object); quên rằng key lồng sâu không hiện.
SELECT k AS key, count(*) AS n_products, string_agg(DISTINCT jsonb_typeof(attributes->k), ', ') AS types
FROM products, jsonb_object_keys(attributes) AS k
GROUP BY k
ORDER BY n_products DESC, key;
