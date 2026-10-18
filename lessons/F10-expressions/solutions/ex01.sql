-- db: shop_s
-- ordered
-- Giải thích: CASE dạng "searched" xét từ trên xuống, nhánh đúng ĐẦU TIÊN thắng, nên chỉ cần viết cận trên mỗi nhánh.
--   Sắp theo thứ tự nghiệp vụ (không theo ABC): ORDER BY min(price) của mỗi nhóm. Cách khác: thêm cột thứ tự bằng CASE thứ hai.
-- Bẫy: ORDER BY segment xếp theo chữ cái (bình dân, cao cấp, trung cấp, xa xỉ); quên is_active.
SELECT CASE
         WHEN price < 100000   THEN 'bình dân'
         WHEN price < 1000000  THEN 'trung cấp'
         WHEN price < 10000000 THEN 'cao cấp'
         ELSE 'xa xỉ'
       END AS segment,
       count(*) AS n_products
FROM products
WHERE is_active
GROUP BY 1
ORDER BY min(price);
