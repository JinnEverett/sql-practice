BEGIN;
:ans
;
SELECT pg_temp.ck((SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns
                   WHERE table_schema = 'i09' AND table_name = 'v_order_summary') = 'order_id,customer_name,total,status',
                  'v_order_summary có 4 cột, status ở cuối');
SELECT pg_temp.ck(pg_temp.val($$SELECT status FROM i09.v_order_summary WHERE order_id = 1$$) = 'paid', 'cột status đúng giá trị');
SELECT pg_temp.ck(to_regclass('i09.v_big_orders') IS NOT NULL, 'v_big_orders (view phụ thuộc) vẫn còn');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.v_big_orders$$) = '7', 'v_big_orders vẫn chạy: 7 đơn ≥ 900000 (đơn 6–12)');
ROLLBACK;
