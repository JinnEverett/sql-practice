-- sai: không có partition default, tháng 4 bị từ chối; và tháng 2 để hở một ngày
CREATE TABLE r12.readings (device_id int NOT NULL, ts timestamptz NOT NULL, value numeric(10,2) NOT NULL, PRIMARY KEY (device_id, ts)) PARTITION BY RANGE (ts);
CREATE TABLE r12.readings_2026_01 PARTITION OF r12.readings FOR VALUES FROM ('2026-01-01 00:00+00') TO ('2026-01-31 00:00+00');
CREATE TABLE r12.readings_2026_02 PARTITION OF r12.readings FOR VALUES FROM ('2026-02-01 00:00+00') TO ('2026-03-01 00:00+00');
CREATE TABLE r12.readings_2026_03 PARTITION OF r12.readings FOR VALUES FROM ('2026-03-01 00:00+00') TO ('2026-04-01 00:00+00');
