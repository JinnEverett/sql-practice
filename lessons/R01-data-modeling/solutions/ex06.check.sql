BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r01.user_phones VALUES (1, '0901', true), (1, '0902', false), (1, '0903', false)$$), 'một user có 1 số chính + 2 số phụ');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.user_phones VALUES (1, '0904', true)$$, '23505'), 'số chính thứ hai của user 1 bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r01.user_phones VALUES (2, '0911', true)$$), 'user khác có số chính riêng');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.user_phones VALUES (1, '0902', false)$$, '23505'), 'lưu trùng cùng một số cho user bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r01.user_phones SET is_primary = false WHERE user_id = 1 AND phone = '0901'$$), 'bỏ cờ chính được');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r01.user_phones SET is_primary = true WHERE user_id = 1 AND phone = '0903'$$), 'chuyển cờ chính sang số khác được');
ROLLBACK;
