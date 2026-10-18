-- db: shop_s
-- ordered
-- expect-rows: 6
-- Giải thích: giá trị trong MCV: rows = reltuples × freq. Ở shop_s freq là tần suất đúng trên cả bảng (mẫu phủ toàn bảng) nên est = actual.
--   Ở bảng lớn hơn 30 000 dòng est chỉ gần actual (sai số mẫu). EXPLAIN SELECT * FROM orders WHERE status = 'cancelled' cho rows=817.
-- Bẫy: dùng count(*) làm "ước lượng"; quên ép mảng most_common_vals sang text[] (kiểu anyarray không unnest được trực tiếp).
SELECT v AS status, round(c.reltuples * f)::bigint AS est_rows, a.n AS actual_rows
FROM pg_stats s
CROSS JOIN LATERAL unnest(s.most_common_vals::text::text[], s.most_common_freqs) AS m(v, f)
JOIN pg_class c ON c.oid = 'public.orders'::regclass
JOIN (SELECT status, count(*) AS n FROM orders GROUP BY status) a ON a.status = m.v
WHERE s.schemaname = 'public' AND s.tablename = 'orders' AND s.attname = 'status'
ORDER BY v;
