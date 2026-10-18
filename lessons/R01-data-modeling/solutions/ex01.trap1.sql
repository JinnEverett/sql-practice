-- sai: chỉ lấy phần tử đầu tiên của mỗi chuỗi items → mất các dòng hàng thứ 2, thứ 3
SELECT order_no, split_part(split_part(items, ',', 1), ':', 1) AS sku, split_part(split_part(items, ',', 1), ':', 2)::int AS qty
FROM r01.legacy_orders ORDER BY order_no, sku;
