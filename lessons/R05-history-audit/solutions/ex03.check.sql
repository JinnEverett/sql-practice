BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r05.products SET price = price, name = name WHERE id = 1$$), 'UPDATE không đổi giá trị nào');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r05.product_audit2$$) = '0', 'UPDATE không đổi gì không sinh dòng audit');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r05.products SET price = 120000 WHERE id = 1$$), 'UPDATE giá');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r05.product_audit2 WHERE op = 'UPDATE'$$) = '1', 'sinh đúng 1 dòng audit');
SELECT pg_temp.ck(pg_temp.val($$SELECT (SELECT count(*) FROM jsonb_object_keys(changes))::text FROM r05.product_audit2 WHERE op = 'UPDATE'$$) = '1', 'changes chỉ chứa 1 key (price)');
SELECT pg_temp.ck(pg_temp.val($$SELECT ((changes->'price'->>'old')::numeric = 100000 AND (changes->'price'->>'new')::numeric = 120000)::text FROM r05.product_audit2 WHERE op = 'UPDATE'$$) = 'true', 'changes.price có old = 100000, new = 120000');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r05.products SET name = 'Tai nghe BT', stock = 3 WHERE id = 1$$), 'UPDATE hai cột');
SELECT pg_temp.ck(pg_temp.val($$SELECT (SELECT string_agg(k, ',' ORDER BY k) FROM jsonb_object_keys(changes) k) FROM r05.product_audit2 WHERE op = 'UPDATE' ORDER BY id DESC LIMIT 1$$) = 'name,stock', 'changes có đúng hai key name, stock');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r05.products (id, name, price, stock) VALUES (3, 'Cáp', 20000, 7)$$), 'INSERT');
SELECT pg_temp.ck(pg_temp.val($$SELECT (changes->>'name') FROM r05.product_audit2 WHERE op = 'INSERT'$$) = 'Cáp', 'INSERT lưu cả dòng trong changes');
SELECT pg_temp.ck(pg_temp.ok($$DELETE FROM r05.products WHERE id = 2$$), 'DELETE');
SELECT pg_temp.ck(pg_temp.val($$SELECT (changes->>'name') FROM r05.product_audit2 WHERE op = 'DELETE'$$) = 'Sạc', 'DELETE lưu dòng bị xóa trong changes');
ROLLBACK;
