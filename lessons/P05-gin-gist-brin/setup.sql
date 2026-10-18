-- P05 · dữ liệu cho ex05 và ex06. Chạy trên DB `lab`. Chạy lại được nhiều lần (~5 giây).
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;
DROP SCHEMA IF EXISTS p05 CASCADE;
CREATE SCHEMA p05;

-- ex05: đặt phòng; 300 000 khoảng thời gian 1 giờ rải trong ~3 năm
CREATE TABLE p05.booking (
  id     int PRIMARY KEY,
  room   int NOT NULL,
  during tstzrange NOT NULL
);
INSERT INTO p05.booking
SELECT i, 1 + (i % 50),
       tstzrange(timestamptz '2024-01-01 00:00+00' + (i * 5) * interval '1 minute',
                 timestamptz '2024-01-01 00:00+00' + (i * 5 + 60) * interval '1 minute')
FROM generate_series(1, 300000) i;

-- ex06: bảng sự kiện 400 000 dòng với 6 index "ai đó thêm vào cho chắc"
CREATE TABLE p05.t (
  id      int PRIMARY KEY,
  status  text NOT NULL,                 -- 'delivered' 90%, 'cancelled' 9%, 'refunded' 1%
  flag    boolean NOT NULL,              -- 50/50
  user_id int NOT NULL,
  ts      timestamptz NOT NULL,          -- tăng theo id (tương quan vật lý cao)
  payload jsonb NOT NULL,
  name    text NOT NULL
);
INSERT INTO p05.t
SELECT i,
       CASE WHEN i % 100 = 0 THEN 'refunded' WHEN i % 11 = 0 THEN 'cancelled' ELSE 'delivered' END,
       i % 2 = 0,
       1 + ((i::bigint * 7919) % 40000)::int,
       timestamptz '2025-01-01 00:00+00' + i * interval '79 seconds',
       jsonb_build_object('sku', i % 5000, 'tier', (ARRAY['a','b','c'])[1 + i % 3]),
       'item-' || md5(i::text)
FROM generate_series(1, 400000) i;
CREATE INDEX t_status_idx  ON p05.t (status);
CREATE INDEX t_flag_idx    ON p05.t (flag);
CREATE INDEX t_user_idx    ON p05.t (user_id);
CREATE INDEX t_ts_brin     ON p05.t USING brin (ts);
CREATE INDEX t_payload_gin ON p05.t USING gin (payload jsonb_path_ops);
CREATE INDEX t_name_trgm   ON p05.t USING gin (name gin_trgm_ops);
VACUUM ANALYZE p05.booking;
VACUUM ANALYZE p05.t;
