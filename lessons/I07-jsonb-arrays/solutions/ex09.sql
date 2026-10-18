-- db: shop_s
-- ordered
-- Giải thích: jsonpath: '$ ? (điều kiện)' lọc chính object; @ là phần tử đang xét. @@ trả boolean cho biểu thức jsonpath
--   dạng vị từ; @? kiểm tra jsonpath có trả kết quả nào không. Key thiếu → điều kiện là "unknown" → không khớp (không lỗi).
--   Cách viết bằng ->> và ép kiểu cũng đúng; jsonpath gọn hơn khi điều kiện lồng sâu và dùng được index GIN.
-- Bẫy: so sánh chuỗi '(attributes->>'weight_g') > '2000'' (so theo chữ: '500' > '2000').
SELECT id, name, (attributes->>'weight_g')::int AS weight_g, (attributes->>'warranty_months')::int AS warranty_months
FROM products
WHERE attributes @? '$ ? (@.weight_g > 2000 && @.warranty_months >= 12)'
ORDER BY id;
