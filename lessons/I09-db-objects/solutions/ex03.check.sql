BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.v_active_customers$$) = '4', 'view có 4 khách active');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO i09.v_active_customers (id, name, email, status) VALUES (6, 'Phúc', 'phuc@x.vn', 'active')$$), 'INSERT khách active qua view');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.customers WHERE id = 6$$) = '1', 'dòng mới nằm trong bảng gốc');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO i09.v_active_customers (id, name, email, status) VALUES (7, 'Quân', 'quan@x.vn', 'blocked')$$, '44000'), 'INSERT khách blocked qua view bị chặn (44000)');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE i09.v_active_customers SET status = 'blocked' WHERE id = 1$$, '44000'), 'UPDATE đẩy dòng ra khỏi view bị chặn (44000)');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE i09.v_active_customers SET name = 'An Nguyễn' WHERE id = 1$$), 'UPDATE tên qua view');
SELECT pg_temp.ck(pg_temp.val($$SELECT name FROM i09.customers WHERE id = 1$$) = 'An Nguyễn', 'bảng gốc đã đổi tên');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM i09.v_active_customers WHERE id = 3$$) = '0', 'khách blocked (id 3) không thấy trong view');
ROLLBACK;
