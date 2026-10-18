\set ON_ERROR_STOP off
:ans
;
ROLLBACK;
\set ON_ERROR_STOP on
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(code, ',' ORDER BY code) FROM p06.sku$$) = 'A1,B2,C3', 'còn A1 (bản gốc), B2 và C3 được ghi: ' || pg_temp.val($$SELECT string_agg(code, ',' ORDER BY code) FROM p06.sku$$));
SELECT pg_temp.ck(pg_temp.val($$SELECT name FROM p06.sku WHERE code = 'A1'$$) = 'ban đầu', 'A1 giữ nguyên bản gốc (dòng trùng không ghi đè)');
