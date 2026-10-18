BEGIN;
:ans
;
SELECT pg_temp.ck(to_regclass('f09.customers') IS NOT NULL, 'có bảng f09.customers');
SELECT pg_temp.ck(pg_temp.val($$SELECT data_type FROM information_schema.columns WHERE table_schema='f09' AND table_name='customers' AND column_name='id'$$) = 'bigint', 'id kiểu bigint');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.customers (email, full_name) VALUES ('a@x.vn', 'A')$$), 'chèn không có id, phone, created_at: thành công');
SELECT pg_temp.ck(pg_temp.val($$SELECT (id IS NOT NULL AND created_at IS NOT NULL)::text FROM f09.customers WHERE email = 'a@x.vn'$$) = 'true', 'id và created_at tự có giá trị');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.customers (id, email, full_name) VALUES (100, 'b@x.vn', 'B')$$, '428C9'), 'tự điền id bị chặn (428C9)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.customers (email, full_name) VALUES ('a@x.vn', 'A2')$$, '23505'), 'trùng email bị chặn (23505)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.customers (email) VALUES ('c@x.vn')$$, '23502'), 'thiếu full_name bị chặn (23502)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.customers (full_name) VALUES ('D')$$, '23502'), 'thiếu email bị chặn (23502)');
SELECT pg_temp.ck(pg_temp.val($$SELECT data_type FROM information_schema.columns WHERE table_schema='f09' AND table_name='customers' AND column_name='created_at'$$) = 'timestamp with time zone', 'created_at kiểu timestamptz');
ROLLBACK;
