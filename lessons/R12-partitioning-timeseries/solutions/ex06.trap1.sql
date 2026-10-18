-- sai: ATTACH thẳng — Postgres phải quét cả legacy_events để kiểm tra ranh giới (dưới ACCESS EXCLUSIVE)
ALTER TABLE r12.events_p ATTACH PARTITION r12.legacy_events FOR VALUES FROM ('2026-07-01 00:00+00') TO ('2026-08-01 00:00+00');
