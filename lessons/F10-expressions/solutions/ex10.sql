-- db: shop_s
-- ordered
-- Giải thích:
--   * Mã đơn: to_char theo NGÀY GIỜ VN ('YYMMDD') + lpad(id, 6, '0').
--   * Số điện thoại: đưa '+84 9…' về '09…' bằng regexp_replace(phone, '^\+84\s*', '0'), rồi giữ 3 số đầu + '****' + 3 số cuối.
--     Phone NULL → cả biểu thức NULL → coalesce về '(không có)'.
--   * Email: chuẩn hóa lower(trim()), giữ ký tự đầu + '***@' + tên miền.
--   * coalesce(full_name, '(ẩn danh)') cho khách thiếu tên.
-- Bẫy: mask trực tiếp '+84 954511385' → '+84****385' (không đúng định dạng 09…); to_char theo UTC lệch ngày cho đơn 0h–7h sáng.
SELECT 'DH' || to_char(o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYMMDD') || '-' || lpad(o.id::text, 6, '0') AS order_code,
       coalesce(u.full_name, '(ẩn danh)') AS customer,
       coalesce(left(regexp_replace(u.phone, '^\+84\s*', '0'), 3) || '****' || right(u.phone, 3), '(không có)') AS phone_masked,
       left(lower(trim(u.email)), 1) || '***@' || split_part(lower(trim(u.email)), '@', 2) AS email_masked
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.id BETWEEN 146 AND 155
ORDER BY o.id;
