BEGIN;
:ans
;
SELECT r12.ensure_month('2026-08-15') AS n1 \gset
SELECT pg_temp.ck(:'n1' = 'events_p_2026_08', 'trả về tên partition events_p_2026_08 (nhận ' || :'n1' || ')');
SELECT pg_temp.ck(pg_temp.val($$SELECT pg_get_expr(relpartbound, oid) FROM pg_class WHERE oid = 'r12.events_p_2026_08'::regclass$$) = $q$FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00')$q$, 'ranh giới đúng [2026-08-01, 2026-09-01) UTC');
SELECT pg_temp.ck(pg_temp.ok($$SELECT r12.ensure_month('2026-08-31')$$), 'gọi lại cho cùng tháng không lỗi (idempotent)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r12.events_p (device, ts, value) VALUES (1, '2026-08-31 23:59:59+00', 1)$$), 'chèn dòng cuối tháng 8 được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r12.events_p (device, ts, value) VALUES (1, '2026-09-01 00:00+00', 1)$$, '23514'), 'tháng 9 chưa có partition: bị từ chối (23514)');
SELECT r12.ensure_month('2026-12-31') AS n2 \gset
SELECT pg_temp.ck(:'n2' = 'events_p_2026_12' AND pg_temp.val($$SELECT pg_get_expr(relpartbound, oid) FROM pg_class WHERE oid = 'r12.events_p_2026_12'::regclass$$) = $q$FOR VALUES FROM ('2026-12-01 00:00:00+00') TO ('2027-01-01 00:00:00+00')$q$, 'tháng 12 kết thúc ở 2027-01-01');
SELECT pg_temp.ck(pg_temp.ok($$SELECT r12.ensure_month('2026-07-01')$$) AND to_regclass('r12.events_p_2026_07') IS NOT NULL, 'tạo được cả tháng 7');
ROLLBACK;
