-- db: shop_s
-- ordered
-- Giải thích: ILIKE là LIKE không phân biệt hoa/thường; '%…%' = chứa ở bất kỳ vị trí nào.
--   Với tiếng Việt có dấu, ILIKE so đúng chữ hoa/thường của ký tự có dấu ('Ố' ~ 'ố'), nhưng KHÔNG bỏ dấu ('tai' ≠ 'tài').
-- Bẫy: LIKE '%tai nghe%' (phân biệt hoa thường) bỏ sót 'Tai nghe …'; quên is_active.
SELECT id, name, price
FROM products
WHERE is_active AND name ILIKE '%tai nghe%'
ORDER BY id;
