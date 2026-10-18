CREATE EXTENSION IF NOT EXISTS dblink;
DROP EVENT TRIGGER IF EXISTS r10_log_ddl;
CREATE TABLE r10.ddl_log (tag text, lock_timeout text);
CREATE FUNCTION r10.log_ddl() RETURNS event_trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r10.ddl_log VALUES (tg_tag, current_setting('lock_timeout'));
END $$;
CREATE EVENT TRIGGER r10_log_ddl ON ddl_command_end EXECUTE FUNCTION r10.log_ddl();
-- Session A: một báo cáo đang đọc bảng orders (giữ ACCESS SHARE) trong 1.5 giây
SELECT pg_temp.bg_start('a', 'BEGIN; SELECT count(*) FROM r10.orders; SELECT pg_sleep(1.5); COMMIT');
-- Session C: một truy vấn bình thường đến sau 0.5 giây; ghi lại nó phải chờ bao lâu
SELECT pg_temp.bg_start('c', 'SELECT pg_sleep(0.5); SELECT clock_timestamp()::text; SELECT count(*) FROM r10.orders; SELECT clock_timestamp()::text');
SELECT pg_sleep(0.2);
-- Session chính chạy migration của bạn
:ans
;
DROP EVENT TRIGGER r10_log_ddl;
SELECT pg_temp.bg_wait('a') AS a_res \gset
SELECT pg_temp.bg_wait('c') AS c_res \gset
SELECT extract(epoch FROM split_part(:'c_res', ' | ', 3)::timestamptz - split_part(:'c_res', ' | ', 1)::timestamptz) AS c_wait \gset
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM information_schema.columns WHERE table_schema = 'r10' AND table_name = 'orders' AND column_name = 'note'$$) = '1', 'cột note đã được thêm');
SELECT pg_temp.ck((SELECT lock_timeout FROM r10.ddl_log WHERE tag = 'ALTER TABLE' ORDER BY ctid DESC LIMIT 1) NOT IN ('0', '0ms'), 'ALTER chạy với lock_timeout khác 0 (' || coalesce((SELECT lock_timeout FROM r10.ddl_log WHERE tag = 'ALTER TABLE' ORDER BY ctid DESC LIMIT 1), 'NULL') || ')');
SELECT pg_temp.ck(:c_wait < 0.6, 'truy vấn thường đến sau chỉ chờ ' || round(:c_wait::numeric, 2) || ' giây (< 0.6): ALTER không chặn hàng đợi lâu');
SELECT pg_temp.ck(:'a_res' !~ 'ERROR', 'báo cáo của session A chạy xong bình thường');
