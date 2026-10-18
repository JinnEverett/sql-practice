-- db: shop_s
-- expect-rows: 1
-- Giải thích: pg_relation_size chỉ tính heap (main fork), chia cho block_size ra số page. Mỗi dòng ≈ 98 B gồm tuple header 24–32 B,
--   line pointer 4 B và dữ liệu. 83 dòng/page × 98 B ≈ 8 KB nên page gần đầy.
-- Bẫy: pg_total_relation_size (gồm cả index PK); gõ cứng 8192; reltuples thay cho count(*) (chỉ là ước lượng).
SELECT pg_relation_size('orders') / current_setting('block_size')::int AS n_pages,
       count(*)                                                        AS n_rows,
       round(count(*)::numeric / (pg_relation_size('orders') / current_setting('block_size')::int), 1) AS rows_per_page,
       round(pg_relation_size('orders')::numeric / count(*))           AS bytes_per_row
FROM orders;
