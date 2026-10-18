CREATE EXTENSION IF NOT EXISTS dblink;
:ans
;
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r08.bookings (room_id, during) VALUES (1, '[2026-03-01 09:30+00, 2026-03-01 10:30+00)')$$, '23P01'), 'đặt 9:30–10:30 phòng 1 (chồng lên đặt chỗ 9–10 và 10–11) bị chặn (23P01)');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r08.bookings (room_id, during) VALUES (1, '[2026-03-01 08:00+00, 2026-03-01 09:01+00)')$$, '23P01'), 'chồng 1 phút ở đầu bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r08.bookings (room_id, during) VALUES (1, '[2026-03-01 11:00+00, 2026-03-01 12:00+00)')$$), 'đặt liền kề 11:00–12:00 (ngay sau 10–11) được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r08.bookings (room_id, during) VALUES (2, '[2026-03-01 09:00+00, 2026-03-01 10:00+00)')$$), 'phòng khác cùng giờ: được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r08.bookings (room_id, during, status) VALUES (1, '[2026-03-01 09:00+00, 2026-03-01 10:00+00)', 'cancelled')$$), 'ghi thêm một đặt chỗ đã hủy trùng giờ: được');
SELECT pg_temp.ck(pg_temp.ok($$UPDATE r08.bookings SET status = 'cancelled' WHERE id = 1$$), 'hủy đặt chỗ 9–10');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r08.bookings (room_id, during) VALUES (1, '[2026-03-01 09:00+00, 2026-03-01 10:00+00)')$$), 'sau khi hủy, đặt lại đúng khung 9–10 được');
-- Đồng thời: phòng 3. Session A chèn rồi giữ transaction mở 1 giây; session chính chèn khung chồng lên trong lúc đó.
SELECT pg_temp.bg_start('sess_a', $q$BEGIN; INSERT INTO r08.bookings (room_id, during) VALUES (3, '[2026-03-01 09:00+00, 2026-03-01 10:00+00)'); SELECT pg_sleep(1.0); COMMIT$q$);
SELECT pg_sleep(0.3);
DO $race$
DECLARE msg text := 'inserted';
BEGIN
  BEGIN
    INSERT INTO r08.bookings (room_id, during) VALUES (3, '[2026-03-01 09:30+00, 2026-03-01 10:30+00)');
  EXCEPTION WHEN others THEN msg := SQLSTATE;
  END;
  PERFORM set_config('r08.race', msg, false);
END $race$;
SELECT pg_temp.bg_wait('sess_a') AS a_res \gset
SELECT pg_temp.ck(:'a_res' !~ 'ERROR', 'session A đặt thành công (' || :'a_res' || ')');
SELECT pg_temp.ck(current_setting('r08.race') = '23P01', 'session B đặt chồng khung bị từ chối 23P01 sau khi chờ A (nhận: ' || current_setting('r08.race') || ')');
SELECT pg_temp.ck((SELECT count(*) FROM r08.bookings WHERE room_id = 3) = 1, 'phòng 3 chỉ có đúng 1 đặt chỗ');
