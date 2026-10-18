CREATE EXTENSION IF NOT EXISTS dblink;
:ans
;
SELECT r03.charge('k1', 1, 100000) AS id1 \gset
SELECT r03.charge('k1', 1, 100000) AS id1b \gset
SELECT r03.charge('k2', 2, 200000) AS id2 \gset
SELECT pg_temp.ck(:id1 IS NOT NULL AND :id1 = :id1b, 'gọi lại cùng key trả về cùng payment id');
SELECT pg_temp.ck(:id2 <> :id1, 'key khác tạo payment khác');
SELECT pg_temp.ck((SELECT count(*) FROM r03.pay2) = 2, 'chỉ có 2 payment sau 3 lần gọi (retry không trừ thêm tiền)');
-- hai request ĐỒNG THỜI cùng key 'kc': session A giữ transaction mở 1.2s sau khi gọi hàm
SELECT pg_temp.bg_start('sess_a', $q$BEGIN; SELECT r03.charge('kc', 5, 70000); SELECT pg_sleep(1.2); COMMIT$q$);
SELECT pg_sleep(0.4);
DO $race$
DECLARE v bigint; msg text := 'ok';
BEGIN
  BEGIN
    v := r03.charge('kc', 5, 70000);
  EXCEPTION WHEN others THEN msg := SQLSTATE || ' ' || SQLERRM; v := NULL;
  END;
  PERFORM set_config('r03.race_id', coalesce(v::text, ''), false);
  PERFORM set_config('r03.race_msg', msg, false);
END $race$;
SELECT pg_temp.bg_wait('sess_a') AS a_res \gset
SELECT pg_temp.ck(current_setting('r03.race_msg') = 'ok', 'request thứ hai cùng lúc không bị lỗi (' || current_setting('r03.race_msg') || ')');
SELECT pg_temp.ck(current_setting('r03.race_id') <> '' AND current_setting('r03.race_id')::bigint = (SELECT payment_id FROM r03.idem_keys WHERE key = 'kc'), 'cả hai request nhận cùng payment id đã commit');
SELECT pg_temp.ck((SELECT count(*) FROM r03.pay2 WHERE order_id = 5) = 1, 'đơn 5 chỉ bị trừ tiền đúng 1 lần');
