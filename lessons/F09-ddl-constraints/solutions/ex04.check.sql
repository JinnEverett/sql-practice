BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(id::text, ',' ORDER BY id) FROM f09.legacy_users$$) = '1,4,5,6', 'còn đúng id 1,4,5,6');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM f09.legacy_users WHERE email <> lower(trim(email))$$) = '0', 'mọi email đã chuẩn hóa');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.legacy_users VALUES (8, ' AN@x.vn ', now())$$, '23'), 'chèn " AN@x.vn " bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.legacy_users VALUES (9, 'chi@x.vn', now())$$, '23'), 'chèn "chi@x.vn" bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.legacy_users VALUES (10, 'em@x.vn', now())$$), 'chèn email mới được');
ROLLBACK;
