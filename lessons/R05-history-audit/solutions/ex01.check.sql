BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(id::text, ',' ORDER BY id) FROM r05.active_accounts$$) = '1,3', 'view chỉ có tài khoản chưa xóa (id 1, 3)');
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema = 'r05' AND table_name = 'active_accounts'$$) = 'id,email,name', 'view có đúng cột id, email, name');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r05.accounts (email, name) VALUES ('b@x.vn', 'B mới')$$), 'đăng ký lại email của tài khoản đã xóa: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r05.accounts (email, name) VALUES ('a@x.vn', 'A2')$$, '23505'), 'trùng email đang hoạt động bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r05.accounts (email, name) VALUES ('A@X.VN', 'A3')$$, '23505'), 'trùng email khác hoa/thường bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r05.accounts SET deleted_at = now() WHERE email = 'a@x.vn'$$), 'xóa mềm tài khoản a@x.vn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r05.accounts (email, name) VALUES ('a@x.vn', 'A đăng ký lại')$$), 'sau khi xóa mềm, a@x.vn đăng ký lại được');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r05.active_accounts WHERE email = 'a@x.vn'$$) = '1', 'view chỉ thấy bản đang hoạt động');
ROLLBACK;
