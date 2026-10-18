-- db: shop_s
-- ordered
-- Giải thích: chuẩn hóa TRƯỚC khi tách: lower(trim(email)), rồi split_part(…, '@', 2) lấy phần sau @.
--   Tỉ lệ: 100.0 * count / tổng (scalar subquery), round 1 chữ số. 100.0 tránh chia số nguyên.
-- Bẫy: không lower → 'YAHOO.COM' thành nhóm riêng; 100 * count / tổng → chia nguyên ra số tròn.
SELECT split_part(lower(trim(email)), '@', 2) AS domain,
       count(*) AS n_users,
       round(100.0 * count(*) / (SELECT count(*) FROM users), 1) AS pct
FROM users
GROUP BY 1
ORDER BY n_users DESC, domain;
