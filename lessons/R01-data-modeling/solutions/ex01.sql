-- db: lab
-- reset
-- ordered
-- expect-rows: 8
-- Giải thích: 1NF = mỗi ô một giá trị nguyên tử. Bung chuỗi bằng string_to_table(items, ',') (một dòng cho mỗi phần tử),
--   rồi tách "sku:qty" bằng split_part. Sau bước này (order_no, sku) mới là khóa tự nhiên của bảng chi tiết.
-- Bẫy: quên ép qty sang int (so sánh/cộng chuỗi), hoặc dùng string_to_array + unnest cho kết quả giống nhưng dài dòng hơn.
SELECT o.order_no,
       split_part(it, ':', 1)      AS sku,
       split_part(it, ':', 2)::int AS qty
FROM r01.legacy_orders o, string_to_table(o.items, ',') AS it
ORDER BY o.order_no, sku;
