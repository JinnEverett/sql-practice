BEGIN;
-- Ghi lại mọi lệnh DDL trên r10.orders: tại mỗi lệnh, có ràng buộc nào đang ở trạng thái chưa xác thực (NOT VALID) không?
CREATE TABLE r10.ddl_log (tag text, n_unvalidated int, query text);
CREATE FUNCTION r10.log_ddl() RETURNS event_trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r10.ddl_log SELECT tg_tag,
    (SELECT count(*) FROM pg_constraint WHERE conrelid = 'r10.orders'::regclass AND NOT convalidated)::int, left(current_query(), 200);
END $$;
CREATE EVENT TRIGGER r10_log_ddl ON ddl_command_end EXECUTE FUNCTION r10.log_ddl();
:ans
;
DROP EVENT TRIGGER r10_log_ddl;
SELECT pg_temp.ck(pg_temp.val($$SELECT attnotnull::text FROM pg_attribute WHERE attrelid = 'r10.orders'::regclass AND attname = 'customer_ref'$$) = 'true', 'customer_ref đã NOT NULL');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_constraint WHERE conrelid = 'r10.orders'::regclass AND contype = 'c'$$) = '0', 'không còn CHECK thừa');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_constraint WHERE conrelid = 'r10.orders'::regclass AND NOT convalidated$$) = '0', 'không còn ràng buộc NOT VALID');
SELECT pg_temp.ck((SELECT coalesce(max(n_unvalidated), 0) FROM r10.ddl_log) >= 1, 'đã đi qua trạng thái ràng buộc NOT VALID (trình tự an toàn), không SET NOT NULL trực tiếp');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r10.orders (status, customer_ref, amount, created_at) VALUES ('paid', NULL, 1, now())$$, '23502'), 'chèn NULL bị chặn (23502)');
ROLLBACK;
