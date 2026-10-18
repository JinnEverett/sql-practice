BEGIN;
:ans
;
SELECT r09.provision_tenant('acme');
SELECT pg_temp.ck(to_regclass('t_acme.invoices') IS NOT NULL, 'có bảng t_acme.invoices');
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(column_name || ':' || data_type, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema = 't_acme' AND table_name = 'invoices'$$)
                = pg_temp.val($$SELECT string_agg(column_name || ':' || data_type, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema = 'r09' AND table_name = 'tpl_invoices'$$), 'cột giống khuôn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO t_acme.invoices (customer, amount) VALUES ('KH 1', 100)$$), 'chèn hóa đơn vào t_acme (identity tự sinh id)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO t_acme.invoices (customer, amount) VALUES ('KH 2', -1)$$, '23514'), 'CHECK amount >= 0 được sao chép');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_constraint WHERE conrelid = 't_acme.invoices'::regclass AND contype = 'p'$$) = '1', 'PK được sao chép');
SELECT pg_temp.ck(pg_temp.ok($$SELECT r09.provision_tenant('acme')$$), 'gọi lại với cùng slug không lỗi (idempotent)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM t_acme.invoices$$) = '1', 'gọi lại không xóa dữ liệu');
SELECT r09.provision_tenant('beta');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM t_beta.invoices$$) = '0', 'tenant beta có bảng riêng, không thấy dữ liệu của acme');
SELECT pg_temp.ck(pg_temp.fails($$SELECT r09.provision_tenant('x; DROP SCHEMA r09 CASCADE')$$, '22023'), 'slug độc hại bị từ chối với lỗi 22023');
SELECT pg_temp.ck(pg_temp.fails($$SELECT r09.provision_tenant('Bad-Slug')$$, '22023'), 'slug sai định dạng bị từ chối với lỗi 22023');
SELECT pg_temp.ck(to_regclass('r09.tenants') IS NOT NULL, 'schema r09 vẫn còn nguyên');
SET LOCAL ROLE r09_app;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO t_acme.invoices (customer, amount) VALUES ('KH app', 5)$$), 'role ứng dụng có quyền đọc/ghi bảng của tenant');
SET LOCAL search_path = t_acme;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM invoices$$) = '2', 'đặt search_path = t_acme thì tên bảng không cần tiền tố');
ROLLBACK;
