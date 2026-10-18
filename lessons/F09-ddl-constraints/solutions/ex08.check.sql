BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.employees (id, full_name) VALUES (1, 'Sếp')$$), 'sếp không có quản lý, không có email: được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.employees (id, full_name, manager_id) VALUES (2, 'An', 1)$$), 'nhân viên thứ hai cũng chưa có email: được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.employees (id, full_name, manager_id, work_email) VALUES (3, 'Bình', 1, 'binh@x.vn')$$), 'có email: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.employees (id, full_name, manager_id, work_email) VALUES (4, 'Chi', 1, 'binh@x.vn')$$, '23505'), 'trùng email bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.employees (id, full_name, manager_id) VALUES (5, 'Dũng', 99)$$, '23503'), 'quản lý không tồn tại bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.employees (id, full_name, manager_id) VALUES (6, 'Em', 6)$$, '23514'), 'tự quản lý chính mình bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$DELETE FROM f09.employees WHERE id = 1$$), 'xóa sếp được');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) || '/' || count(manager_id) FROM f09.employees$$) = '2/0', 'An và Bình vẫn còn, manager_id về NULL');
ROLLBACK;
