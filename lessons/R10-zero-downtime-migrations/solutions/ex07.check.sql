BEGIN;
CREATE TABLE r10.ddl_log (tag text, n_unvalidated int);
CREATE FUNCTION r10.log_ddl() RETURNS event_trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r10.ddl_log SELECT tg_tag, (SELECT count(*) FROM pg_constraint WHERE conrelid = 'r10.child'::regclass AND NOT convalidated)::int;
END $$;
CREATE EVENT TRIGGER r10_log_ddl ON ddl_command_end EXECUTE FUNCTION r10.log_ddl();
:ans
;
DROP EVENT TRIGGER r10_log_ddl;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_constraint WHERE conrelid = 'r10.child'::regclass AND contype = 'f' AND convalidated$$) = '1', 'có đúng 1 FK trên child và đã được xác thực (VALIDATED)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_constraint WHERE conrelid = 'r10.child'::regclass AND NOT convalidated$$) = '0', 'không còn ràng buộc NOT VALID');
SELECT pg_temp.ck((SELECT coalesce(max(n_unvalidated), 0) FROM r10.ddl_log) >= 1, 'đã đi qua trạng thái NOT VALID (không ADD FOREIGN KEY một phát)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r10.child (parent_id) VALUES (999)$$, '23503'), 'FK hoạt động: parent không tồn tại bị chặn (23503)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r10.child (parent_id) VALUES (5)$$), 'parent hợp lệ: được');
ROLLBACK;
