BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r05.products (id, name, price, stock) VALUES (3, 'Cáp', 20000, 7)$$), 'INSERT sản phẩm 3');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r05.products SET price = 120000 WHERE id = 1$$), 'UPDATE giá sản phẩm 1');
SELECT pg_temp.ck(pg_temp.ok($$DELETE FROM r05.products WHERE id = 2$$), 'DELETE sản phẩm 2');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r05.product_audit$$) = '3', 'có đúng 3 dòng audit (' || pg_temp.val($$SELECT count(*) FROM r05.product_audit$$) || ')');
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(op || ':' || row_id, ',' ORDER BY id) FROM r05.product_audit$$) = 'INSERT:3,UPDATE:1,DELETE:2', 'thao tác và id đúng thứ tự: INSERT:3,UPDATE:1,DELETE:2');
SELECT pg_temp.ck(pg_temp.val($$SELECT (old_row IS NULL AND new_row->>'name' = 'Cáp')::text FROM r05.product_audit WHERE op = 'INSERT'$$) = 'true', 'INSERT: old_row NULL, new_row có dữ liệu');
SELECT pg_temp.ck(pg_temp.val($$SELECT ((old_row->>'price')::numeric = 100000 AND (new_row->>'price')::numeric = 120000)::text FROM r05.product_audit WHERE op = 'UPDATE'$$) = 'true', 'UPDATE: có cả giá cũ 100000 và giá mới 120000');
SELECT pg_temp.ck(pg_temp.val($$SELECT (new_row IS NULL AND old_row->>'name' = 'Sạc')::text FROM r05.product_audit WHERE op = 'DELETE'$$) = 'true', 'DELETE: new_row NULL, old_row là dòng bị xóa');
SELECT pg_temp.ck(pg_temp.val($$SELECT (changed_by = current_user AND changed_at IS NOT NULL)::text FROM r05.product_audit WHERE op = 'INSERT'$$) = 'true', 'changed_by và changed_at được điền');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r05.products SET stock = stock + 1$$), 'UPDATE hàng loạt cả bảng (2 dòng còn lại)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r05.product_audit WHERE op = 'UPDATE'$$) = '3', 'UPDATE 2 dòng sinh thêm 2 dòng audit (mỗi dòng một bản ghi)');
ROLLBACK;
