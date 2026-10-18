SELECT 'DH' || to_char(o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYMMDD') || '-' || lpad(o.id::text, 6, '0') AS order_code,
       coalesce(u.full_name, '(ẩn danh)') AS customer,
       coalesce(left(u.phone, 3) || '****' || right(u.phone, 3), '(không có)') AS phone_masked,
       left(lower(trim(u.email)), 1) || '***@' || split_part(lower(trim(u.email)), '@', 2) AS email_masked
FROM orders o JOIN users u ON u.id = o.user_id WHERE o.id BETWEEN 146 AND 155 ORDER BY o.id;
