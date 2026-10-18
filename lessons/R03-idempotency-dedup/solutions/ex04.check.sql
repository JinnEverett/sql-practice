BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(id::text, ',' ORDER BY id) FROM r03.payments WHERE status = 'succeeded'$$) = '1,4,5,7', 'còn đúng các payment succeeded id 1,4,5,7 (bản sớm nhất mỗi đơn)');
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(id::text, ',' ORDER BY id) FROM r03.payments WHERE status = 'refunded'$$) = '2,6,8,9', 'các bản trùng chuyển thành refunded (id 2,8,9) + bản refunded cũ (6)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r03.payments$$) = '9', 'không xóa payment nào');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r03.payments (order_id, status, amount, created_at) VALUES (10, 'succeeded', 1, now())$$, '23505'), 'payment succeeded thứ hai cho đơn 10 bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r03.payments (order_id, status, amount, created_at) VALUES (10, 'failed', 1, now()), (10, 'failed', 1, now()), (10, 'refunded', 1, now())$$), 'nhiều payment failed/refunded cùng đơn vẫn được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r03.payments (order_id, status, amount, created_at) VALUES (20, 'succeeded', 1, now())$$), 'đơn mới có 1 payment succeeded: được');
ROLLBACK;
