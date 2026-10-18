CREATE EXTENSION IF NOT EXISTS dblink;
:ans
;
-- Tuần tự: hàm phải còn mô phỏng xử lý chậm (>= 0.45 giây) và chuyển đúng tiền
SELECT clock_timestamp() AS t0 \gset
SELECT r08.transfer(1, 2, 10);
SELECT extract(epoch FROM clock_timestamp() - :'t0'::timestamptz) AS secs \gset
SELECT pg_temp.ck(:secs >= 0.45, 'giữ nguyên bước xử lý chậm 0.5 giây (đo được ' || round(:secs::numeric, 2) || ' giây)');
SELECT pg_temp.ck((SELECT balance FROM r08.accounts WHERE id = 1) = 90 AND (SELECT balance FROM r08.accounts WHERE id = 2) = 110, 'tuần tự: 1 → 2 chuyển 10 đúng (90 / 110)');
-- Đồng thời, chiều ngược nhau: A chuyển 1 → 2 (10), B chuyển 2 → 1 (5), B bắt đầu 0.2 giây sau A
SELECT pg_temp.bg_start('sess_a', 'SELECT r08.transfer(1, 2, 10)');
SELECT pg_sleep(0.2);
DO $race$
DECLARE msg text := 'ok';
BEGIN
  BEGIN
    PERFORM r08.transfer(2, 1, 5);
  EXCEPTION WHEN others THEN msg := SQLSTATE || ' ' || SQLERRM;
  END;
  PERFORM set_config('r08.b_msg', msg, false);
END $race$;
SELECT pg_temp.bg_wait('sess_a') AS a_res \gset
SELECT pg_temp.ck(:'a_res' !~ 'ERROR', 'session A không bị hủy (' || :'a_res' || ')');
SELECT pg_temp.ck(current_setting('r08.b_msg') = 'ok', 'session B không bị hủy (' || current_setting('r08.b_msg') || ')');
SELECT pg_temp.ck((SELECT balance FROM r08.accounts WHERE id = 1) = 85 AND (SELECT balance FROM r08.accounts WHERE id = 2) = 115, 'cả hai khoản chuyển được áp dụng: 85 / 115 (thực tế ' || (SELECT balance FROM r08.accounts WHERE id = 1) || ' / ' || (SELECT balance FROM r08.accounts WHERE id = 2) || ')');
