BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT data_type || '(' || numeric_precision || ',' || numeric_scale || ')' FROM information_schema.columns WHERE table_schema='f09' AND table_name='imports' AND column_name='price'$$) = 'numeric(12,2)', 'cột price giờ là numeric(12,2)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM f09.imports$$) = '5', 'vẫn đủ 5 dòng');
SELECT pg_temp.ck(pg_temp.val($$SELECT sum(price) FROM f09.imports$$) = '4139000.00', 'tổng giá = 4139000.00');
SELECT pg_temp.ck(pg_temp.val($$SELECT price FROM f09.imports WHERE id = 1$$) = '1200000.00', '"1.200.000đ" → 1200000.00');
SELECT pg_temp.ck(pg_temp.val($$SELECT price FROM f09.imports WHERE id = 3$$) = '89000.00', '"89.000 đ" → 89000.00');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.imports VALUES (6, 'AB-0006', -5)$$, '23514'), 'giá âm bị chặn');
ROLLBACK;
