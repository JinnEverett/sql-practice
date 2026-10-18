CREATE EXTENSION IF NOT EXISTS dblink;
:ans
;
-- Tuần tự: bác sĩ 1, 2 đang trực
SELECT r08.go_off_call(1) AS r1 \gset
SELECT r08.go_off_call(2) AS r2 \gset
SELECT r08.go_off_call(3) AS r3 \gset
SELECT pg_temp.ck(:'r1' = 't', 'tuần tự: BS 1 nghỉ trực được (còn BS 2)');
SELECT pg_temp.ck(:'r2' = 'f', 'tuần tự: BS 2 là người cuối cùng, không được nghỉ');
SELECT pg_temp.ck(:'r3' = 'f', 'BS 3 vốn không trực: false');
UPDATE r08.doctors SET on_call = (id IN (1, 2));
-- Đồng thời: A (BS 1) giữ transaction mở 1 giây sau khi gọi hàm; B (BS 2) gọi hàm trong lúc đó
SELECT pg_temp.bg_start('sess_a', 'BEGIN; SELECT r08.go_off_call(1); SELECT pg_sleep(1.0); COMMIT');
SELECT pg_sleep(0.3);
DO $race$
DECLARE v boolean; msg text := 'ok';
BEGIN
  BEGIN
    v := r08.go_off_call(2);
  EXCEPTION WHEN others THEN msg := SQLSTATE || ' ' || SQLERRM; v := NULL;
  END;
  PERFORM set_config('r08.b_res', coalesce(v::text, 'null'), false);
  PERFORM set_config('r08.b_msg', msg, false);
END $race$;
SELECT pg_temp.bg_wait('sess_a') AS a_res \gset
SELECT pg_temp.ck(:'a_res' ~ '\| t \|', 'session A (BS 1) nghỉ trực thành công (' || :'a_res' || ')');
SELECT pg_temp.ck(current_setting('r08.b_msg') = 'ok', 'session B không lỗi (' || current_setting('r08.b_msg') || ')');
SELECT pg_temp.ck(current_setting('r08.b_res') = 'false', 'session B (BS 2) bị từ chối vì A đã nghỉ (nhận: ' || current_setting('r08.b_res') || ')');
SELECT pg_temp.ck((SELECT count(*) FROM r08.doctors WHERE on_call) >= 1, 'luôn còn ít nhất 1 bác sĩ trực (còn ' || (SELECT count(*) FROM r08.doctors WHERE on_call) || ')');
