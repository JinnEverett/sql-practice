-- db: shop_s
-- ordered
-- Giải thích: string_agg(biểu thức, dấu phân cách ORDER BY …) nối chuỗi trong mỗi nhóm theo thứ tự chỉ định.
--   ORDER BY bên trong string_agg là bắt buộc nếu muốn thứ tự xác định.
-- Bẫy: thiếu ORDER BY trong string_agg (thứ tự tùy ý); quantity là int, nối bằng || tự ép sang text (OK), nhưng concat với NULL…
SELECT oi.order_id,
       count(*) AS n_lines,
       string_agg(p.name || ' × ' || oi.quantity, ', ' ORDER BY oi.line_no) AS items
FROM order_items oi
JOIN products p ON p.id = oi.product_id
WHERE oi.order_id <= 5
GROUP BY oi.order_id
ORDER BY oi.order_id;
