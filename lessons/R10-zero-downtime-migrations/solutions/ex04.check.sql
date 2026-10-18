DROP EVENT TRIGGER IF EXISTS r10_log_ddl;
CREATE TABLE r10.ddl_log (tag text, query text);
CREATE FUNCTION r10.log_ddl() RETURNS event_trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r10.ddl_log SELECT tg_tag, left(current_query(), 200);
END $$;
CREATE EVENT TRIGGER r10_log_ddl ON ddl_command_end EXECUTE FUNCTION r10.log_ddl();
:ans
;
DROP EVENT TRIGGER r10_log_ddl;
SELECT pg_temp.ck(pg_temp.val($$SELECT string_agg(id::text, ',' ORDER BY id) FROM r10.users$$) = '2,3,6,7', 'còn lại các dòng mới nhất mỗi email: id 2, 3, 6, 7');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM pg_index WHERE indrelid = 'r10.users'::regclass AND NOT indisvalid$$) = '0', 'không còn index INVALID');
SELECT pg_temp.ck(pg_temp.val($$SELECT (indisvalid AND indisunique)::text FROM pg_index WHERE indexrelid = 'r10.users_email_uq'::regclass$$) = 'true', 'users_email_uq tồn tại, hợp lệ và UNIQUE');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r10.users VALUES (8, 'a@x.vn', now())$$, '23505'), 'email trùng giờ bị chặn (23505)');
SELECT pg_temp.ck((SELECT count(*) FROM r10.ddl_log WHERE tag = 'CREATE INDEX' AND query ILIKE '%CONCURRENTLY%') >= 1, 'index được dựng bằng CREATE INDEX CONCURRENTLY (không chặn ghi)');
