BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.products (sku, name, price) VALUES ('AB-0001', 'Chuột', 100000)$$), 'chèn hợp lệ (chỉ sku, name, price)');
SELECT pg_temp.ck(pg_temp.val($$SELECT stock || '/' || status FROM f09.products WHERE sku = 'AB-0001'$$) = '0/draft', 'mặc định stock = 0, status = draft');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.products (id, sku, name, price, stock, status) VALUES (50, 'ZZ-9999', 'Quà', 0, 5, 'archived')$$), 'điền tay id, giá 0, status archived: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price) VALUES ('ab-0002', 'x', 1)$$, '23514'), 'sku chữ thường bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price) VALUES ('AB-002', 'x', 1)$$, '23514'), 'sku 3 chữ số bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price) VALUES ('XAB-00011', 'x', 1)$$, '23514'), 'sku "chứa" mẫu nhưng dư ký tự bị chặn (regex phải neo ^…$)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price) VALUES ('AB-0001', 'x', 1)$$, '23505'), 'trùng sku bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price) VALUES ('AB-0003', 'x', -1)$$, '23514'), 'giá âm bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price) VALUES ('AB-0004', 'x', NULL)$$, '23502'), 'giá NULL bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price, stock) VALUES ('AB-0005', 'x', 1, -1)$$, '23514'), 'tồn âm bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price, status) VALUES ('AB-0006', 'x', 1, 'deleted')$$, '23514'), 'status lạ bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.products (sku, name, price, status) VALUES ('AB-0007', 'x', 1, NULL)$$, '23502'), 'status NULL bị chặn');
SELECT pg_temp.ck(pg_temp.val($$SELECT numeric_precision || ',' || numeric_scale FROM information_schema.columns WHERE table_schema='f09' AND table_name='products' AND column_name='price'$$) = '12,2', 'price kiểu numeric(12,2)');
ROLLBACK;
