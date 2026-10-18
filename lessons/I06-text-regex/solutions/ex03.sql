-- db: shop_s
-- ordered
-- Giải thích: bỏ mọi ký tự không phải số (\D, cờ 'g' = thay tất cả), rồi bỏ tiền tố '84' hoặc '0' ở đầu, rồi gắn '+84'.
--   Hai lớp regexp_replace đọc từ trong ra ngoài. Chuẩn E.164 cho số VN: +84 và 9 số, không khoảng trắng.
-- Bẫy: quên cờ 'g' (chỉ thay ký tự đầu tiên); thay '^0' trước khi bỏ ký tự lạ → '+84 9…' thành '+84+849…'.
SELECT id, phone,
       '+84' || regexp_replace(regexp_replace(phone, '\D', '', 'g'), '^(84|0)', '') AS phone_e164
FROM users
WHERE id <= 60 AND phone IS NOT NULL
ORDER BY id;
