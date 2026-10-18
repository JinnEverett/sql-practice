BEGIN;
:ans
;
SELECT pg_temp.ck(to_regclass('p01.counters_label_idx') IS NOT NULL, 'index counters_label_idx còn nguyên');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p01.counters$$) = '2000', 'còn 2 000 dòng');
UPDATE p01.counters SET hits = hits + 1 WHERE id % 10 = 0;
CREATE TEMP TABLE hot AS
SELECT count(*) FILTER (WHERE (t_infomask2 & 32768) <> 0) AS heap_only
FROM generate_series(0, pg_relation_size('p01.counters') / 8192 - 1) g,
     LATERAL heap_page_items(get_raw_page('p01.counters', g::int));
SELECT pg_temp.ck(heap_only >= 180, heap_only || '/200 phiên bản mới là HOT (cần ≥ 180)') FROM hot;
ROLLBACK;
