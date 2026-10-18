-- db: shop_s
-- ordered
-- Giải thích: GROUPING SETS liệt kê đúng những kiểu gom cần có, trong MỘT lần quét bảng: theo năm, theo phương thức, tổng chung.
--   Không có tổ hợp (năm, phương thức) vì không được hỏi. grouping() dùng để đặt nhãn và sắp xếp.
-- Bẫy: UNION ALL ba câu GROUP BY (đúng nhưng quét bảng 3 lần); ROLLUP(nam, method) sinh thêm dòng (năm, phương thức) không cần.
SELECT CASE WHEN grouping(extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')) = 1 THEN '(mọi năm)'
            ELSE extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::text END AS nam,
       CASE WHEN grouping(method) = 1 THEN '(mọi phương thức)' ELSE method END AS method,
       count(*) AS n_payments,
       sum(amount) AS amount
FROM payments
WHERE status = 'succeeded'
GROUP BY GROUPING SETS ((extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')), (method), ())
ORDER BY grouping(extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')), nam, grouping(method), method;
