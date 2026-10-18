BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.fails($$UPDATE r06.cat SET parent_id = 5 WHERE id = 5$$, '23514'), 'nút tự làm cha của chính nó bị chặn (23514)');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE r06.cat SET parent_id = 16 WHERE id = 2$$, '23514'), 'đặt cha của 2 là con trực tiếp của nó (16) bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE r06.cat SET parent_id = 34 WHERE id = 2$$, '23514'), 'đặt cha của 2 là cháu của nó (34) bị chặn (chu trình dài)');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r06.cat SET parent_id = 3 WHERE id = 16$$), 'chuyển 16 sang cha 3 (hợp lệ) được');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r06.cat SET parent_id = NULL WHERE id = 16$$), 'biến 16 thành gốc được');
SELECT pg_temp.ck(pg_temp.fails($$UPDATE r06.cat SET parent_id = 35 WHERE id = 16$$, '23514'), 'sau khi 16 thành gốc: đặt 16 làm con của hậu duệ 35 vẫn bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r06.cat (id, parent_id, name, slug) VALUES (100, 34, 'Tai nghe chụp tai', 'chup-tai')$$), 'thêm nút mới dưới nút có sẵn được');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r06.cat SET name = 'Đổi tên' WHERE id = 2$$), 'đổi tên (không đụng parent_id) được');
SELECT pg_temp.ck(pg_temp.val($$SELECT parent_id FROM r06.cat WHERE id = 2$$) IS NULL, 'sau các lệnh bị chặn, dữ liệu của nút 2 không đổi');
ROLLBACK;
