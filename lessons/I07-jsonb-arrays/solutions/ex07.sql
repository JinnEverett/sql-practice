-- db: shop_s
-- ordered
-- Giải thích: array_agg(product_id ORDER BY product_id) gom thành mảng đã sắp. Toán tử @> trên mảng: "chứa mọi phần tử của".
--   HAVING lọc trên mảng đã gom. cardinality() = số phần tử.
-- Bẫy: WHERE product_id IN (1, 4) rồi đếm → tìm đơn chứa 1 HOẶC 4; quên ép ARRAY[1, 4]::bigint[] (product_id kiểu bigint).
SELECT order_id, array_agg(product_id ORDER BY product_id) AS product_ids
FROM order_items
GROUP BY order_id
HAVING array_agg(product_id) @> ARRAY[1, 4]::bigint[]
ORDER BY order_id;
