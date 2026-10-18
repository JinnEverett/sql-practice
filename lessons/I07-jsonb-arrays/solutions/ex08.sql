-- db: lab
-- mode: state
-- Giải thích: jsonb là bất biến: "sửa" = tính object mới rồi gán lại. Các toán tử:
--   obj - 'key' (xóa key) · obj || '{"k": v}' (thêm/ghi đè key, bên phải thắng) · jsonb_set(obj, '{k}', v) (đặt giá trị theo đường dẫn)
--   · jsonb_strip_nulls(obj) (xóa key có giá trị null). Ở đây weight_kg = NULL cho sản phẩm không có weight_g → strip đi luôn.
-- Bẫy: (attributes->>'weight_g')::int / 1000 → chia nguyên ra 0; ghi đè warranty_months của sản phẩm đã có; quên xóa weight_g.
UPDATE i07.products
SET attributes = jsonb_strip_nulls(
      (attributes - 'weight_g')
      || jsonb_build_object('weight_kg', round((attributes->>'weight_g')::numeric / 1000, 3))
      || CASE WHEN attributes ? 'warranty_months' THEN '{}'::jsonb ELSE '{"warranty_months": 12}'::jsonb END
    );
