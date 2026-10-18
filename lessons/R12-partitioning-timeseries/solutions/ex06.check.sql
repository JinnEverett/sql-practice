BEGIN;
-- Ghi lại mọi lệnh ALTER TABLE ngay TRƯỚC khi chạy: bảng legacy_events lúc đó có bao nhiêu CHECK đã xác thực?
CREATE TABLE r12.ddl_log (tag text, query text, n_valid_checks int);
CREATE FUNCTION r12.log_ddl() RETURNS event_trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r12.ddl_log SELECT tg_tag, left(current_query(), 300),
    (SELECT count(*) FROM pg_constraint WHERE conrelid = 'r12.legacy_events'::regclass AND contype = 'c' AND convalidated)::int;
END $$;
CREATE EVENT TRIGGER r12_log_ddl ON ddl_command_start WHEN TAG IN ('ALTER TABLE') EXECUTE FUNCTION r12.log_ddl();
:ans
;
DROP EVENT TRIGGER r12_log_ddl;
SELECT pg_temp.ck(pg_temp.val($$SELECT relispartition::text FROM pg_class WHERE oid = 'r12.legacy_events'::regclass$$) = 'true', 'legacy_events đã là partition của events_p');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r12.events_p WHERE ts >= '2026-07-01 00:00+00' AND ts < '2026-08-01 00:00+00'$$) = '5000', 'truy vấn qua events_p thấy đủ 5000 dòng tháng 7');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM r12.events_p$$) = pg_temp.val($$SELECT (SELECT count(*) FROM r12.events_p_2026_01) + (SELECT count(*) FROM r12.events_p_2026_02) + (SELECT count(*) FROM r12.events_p_2026_03) + (SELECT count(*) FROM r12.events_p_2026_04) + (SELECT count(*) FROM r12.events_p_2026_05) + (SELECT count(*) FROM r12.events_p_2026_06) + 5000$$), 'tổng dòng = các tháng 1–6 + 5000 của tháng 7');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r12.events_p (device, ts, value) VALUES (1, '2026-07-15 12:00+00', 1)$$) AND pg_temp.val($$SELECT tableoid::regclass::text FROM r12.events_p WHERE ts = '2026-07-15 12:00+00' AND device = 1 AND value = 1$$) = 'r12.legacy_events', 'chèn dòng tháng 7 qua bảng cha được định tuyến vào legacy_events');
SELECT pg_temp.ck((SELECT coalesce(max(n_valid_checks), 0) FROM r12.ddl_log WHERE query ILIKE '%ATTACH PARTITION%') >= 1, 'lúc ATTACH PARTITION, legacy_events đã có CHECK được xác thực (ATTACH không phải quét bảng)');
SELECT pg_temp.ck(NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'r12.legacy_events'::regclass AND contype = 'c' AND NOT convalidated), 'không còn CHECK NOT VALID');
ROLLBACK;
