-- db: lab
-- reset
-- expect-rows: 1
-- Giải thích: bảng TOAST là relation riêng (pg_class.reltoastrelid). 300 giá trị 60 KB ≈ 2 300 page TOAST, trong khi heap chỉ 14 page
--   vì dòng long chỉ giữ con trỏ 18 B. 99.4% dung lượng của "bảng docs" nằm ngoài file heap mà pg_relation_size('docs') thấy.
-- Bẫy: pg_total_relation_size cho phần heap (đã gồm TOAST + index PK).
SELECT pg_relation_size(c.oid) / 8192 AS heap_pages,
       pg_relation_size(c.reltoastrelid) / 8192 AS toast_pages,
       round(100.0 * pg_relation_size(c.reltoastrelid) / (pg_relation_size(c.oid) + pg_relation_size(c.reltoastrelid)), 1) AS toast_pct
FROM pg_class c WHERE c.oid = 'p01.docs'::regclass;
