BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT partstrat::text FROM pg_partitioned_table WHERE partrelid = 'r12.orders_by_region'::regclass$$) = 'l', 'chiến lược LIST');
INSERT INTO r12.orders_by_region VALUES (1, 'north', 10), (2, 'south', 20), (3, 'central', 30);
SELECT pg_temp.ck(pg_temp.val($$SELECT tableoid::regclass::text FROM r12.orders_by_region WHERE order_id = 1$$) = 'r12.orders_north', 'north → orders_north');
SELECT pg_temp.ck(pg_temp.val($$SELECT tableoid::regclass::text FROM r12.orders_by_region WHERE order_id = 2$$) = 'r12.orders_south', 'south → orders_south');
SELECT pg_temp.ck(pg_temp.val($$SELECT tableoid::regclass::text FROM r12.orders_by_region WHERE order_id = 3$$) = 'r12.orders_other', 'region lạ → orders_other (default)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r12.orders_by_region VALUES (1, 'north', 99)$$, '23505'), 'trùng (order_id, region) bị chặn (23505)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r12.orders_by_region VALUES (1, 'south', 99)$$), 'cùng order_id ở region khác vẫn chèn được (giới hạn của PK ghép)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_constraint WHERE conrelid = 'r12.orders_by_region'::regclass AND contype = 'p' AND array_length(conkey, 1) = 2$$) = '1', 'PK gồm 2 cột (order_id, region)');
ROLLBACK;
