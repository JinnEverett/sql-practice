-- db: shop_s
-- ordered
-- Giải thích: slug = lower(unaccent(name)), thay mọi cụm ký tự không phải [a-z0-9] bằng một dấu '-' (cờ 'g', dấu + gom cả cụm),
--   rồi bỏ '-' thừa ở hai đầu bằng trim(BOTH '-' FROM …). unaccent đổi 'Đ' → 'D' trước khi lower.
--   Kết quả cho thấy dữ liệu slug cũ không nhất quán: '&' lúc bị bỏ, lúc thành 'va'.
-- Bẫy: không unaccent → mọi chữ có dấu biến thành '-'; thiếu dấu + → '--' liên tiếp quanh '&'.
SELECT id, name, slug,
       trim(BOTH '-' FROM regexp_replace(lower(unaccent(name)), '[^a-z0-9]+', '-', 'g')) AS generated
FROM categories
WHERE slug <> trim(BOTH '-' FROM regexp_replace(lower(unaccent(name)), '[^a-z0-9]+', '-', 'g'))
ORDER BY id;
