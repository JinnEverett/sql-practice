CREATE EXTENSION IF NOT EXISTS dblink;
SELECT set_config('r04.q', pg_temp.clean(:'ans'), false);
-- session A: nhận job rồi giữ transaction mở 1.5 giây
SELECT pg_temp.bg_start('sess_a', 'BEGIN; ' || pg_temp.clean(:'ans') || '; SELECT pg_sleep(1.5); COMMIT');
SELECT pg_sleep(0.5);
-- session B (session chính): nhận job trong lúc A còn giữ khóa, chỉ chịu chờ khóa tối đa 300ms
DO $b$
DECLARE v bigint; msg text := 'ok'; t0 timestamptz := clock_timestamp();
BEGIN
  PERFORM set_config('lock_timeout', '300ms', true);
  BEGIN
    EXECUTE current_setting('r04.q') INTO v;
  EXCEPTION WHEN others THEN msg := SQLSTATE || ' ' || SQLERRM; v := NULL;
  END;
  PERFORM set_config('r04.b_id', coalesce(v::text, ''), false);
  PERFORM set_config('r04.b_msg', msg, false);
END $b$;
SELECT pg_temp.bg_wait('sess_a') AS a_res \gset
SELECT split_part(:'a_res', ' | ', 2) AS a_id \gset
SELECT pg_temp.ck(current_setting('r04.b_msg') = 'ok', 'session B không bị chặn bởi khóa của A (' || current_setting('r04.b_msg') || ')');
SELECT pg_temp.ck(:'a_id' = '3', 'session A nhận job ưu tiên cao nhất (id 3), nhận được: ' || :'a_id');
SELECT pg_temp.ck(current_setting('r04.b_id') = '2', 'session B nhận job kế tiếp (id 2), nhận được: ' || current_setting('r04.b_id'));
SELECT pg_temp.ck((SELECT count(*) FROM r04.jobs WHERE status = 'running' AND locked_by = 'worker-1') = 2, 'hai job khác nhau cùng ở trạng thái running');
