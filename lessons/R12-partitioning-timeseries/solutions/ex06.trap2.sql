-- sai: khoảng ATTACH không đúng với dữ liệu (tháng 8) → lỗi 23514 vì dòng tháng 7 nằm ngoài
ALTER TABLE r12.legacy_events ADD CONSTRAINT legacy_events_aug CHECK (ts >= '2026-08-01 00:00+00' AND ts < '2026-09-01 00:00+00') NOT VALID;
ALTER TABLE r12.events_p ATTACH PARTITION r12.legacy_events FOR VALUES FROM ('2026-08-01 00:00+00') TO ('2026-09-01 00:00+00');
