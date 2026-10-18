BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT relkind::text FROM pg_class WHERE oid = 'r12.readings'::regclass$$) = 'p', 'r12.readings là bảng partitioned (relkind p)');
SELECT pg_temp.ck(pg_temp.val($$SELECT partstrat::text FROM pg_partitioned_table WHERE partrelid = 'r12.readings'::regclass$$) = 'r', 'chiến lược RANGE');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_inherits WHERE inhparent = 'r12.readings'::regclass$$) = '4', 'có 4 partition (3 tháng + default)');
INSERT INTO r12.readings VALUES (1, '2026-01-15 10:00+00', 1), (1, '2026-02-01 00:00+00', 2), (1, '2026-03-31 23:59:59+00', 3), (1, '2026-04-01 00:00+00', 4);
SELECT pg_temp.ck(pg_temp.val($$SELECT tableoid::regclass::text FROM r12.readings WHERE value = 1$$) = 'r12.readings_2026_01', '2026-01-15 vào readings_2026_01');
SELECT pg_temp.ck(pg_temp.val($$SELECT tableoid::regclass::text FROM r12.readings WHERE value = 2$$) = 'r12.readings_2026_02', 'đúng 2026-02-01 00:00 vào tháng 2 (cận trên tháng 1 là mở)');
SELECT pg_temp.ck(pg_temp.val($$SELECT tableoid::regclass::text FROM r12.readings WHERE value = 3$$) = 'r12.readings_2026_03', '2026-03-31 23:59:59 vào tháng 3');
SELECT pg_temp.ck(pg_temp.val($$SELECT tableoid::regclass::text FROM r12.readings WHERE value = 4$$) = 'r12.readings_default', '2026-04-01 rơi vào partition default');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r12.readings VALUES (1, '2026-01-15 10:00+00', 9)$$, '23505'), 'PK (device_id, ts) chặn trùng (23505)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r12.readings VALUES (2, '2026-01-15 10:00+00', 9)$$), 'thiết bị khác cùng thời điểm: được');
ROLLBACK;
