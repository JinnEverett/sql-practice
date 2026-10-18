-- db: shop_s
-- ordered
-- Giải thích: substr(sku, 5) bỏ tiền tố 'SKU-', ép ::int để mất các số 0 đầu, rồi nối lại với 'P'.
--   trim() bỏ khoảng trắng hai đầu. Nối chuỗi bằng || (NULL ở một vế làm cả chuỗi NULL; concat/concat_ws thì bỏ qua NULL).
-- Bẫy: ltrim(substr(sku,5), '0') cũng được, nhưng sẽ ra chuỗi rỗng nếu số là 0; length(name) đếm cả khoảng trắng thừa.
SELECT id,
       'P' || substr(sku, 5)::int AS code,
       upper(brand) || ' · ' || trim(name) AS title,
       length(name) - length(trim(name)) AS n_extra_spaces
FROM products
WHERE id <= 10 OR name <> trim(name)
ORDER BY id;
