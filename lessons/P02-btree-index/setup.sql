-- P02 · ex08: bảng đơn hàng rút gọn với 5 index (có index thừa). Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS p02 CASCADE;
CREATE SCHEMA p02;
CREATE TABLE p02.ord (
  id         int PRIMARY KEY,
  user_id    int NOT NULL,
  status     text NOT NULL,
  created_at timestamptz NOT NULL,
  amount     numeric(12,2) NOT NULL
);
INSERT INTO p02.ord
SELECT i,
       1 + ((i::bigint * 7919) % 30000)::int,                                         -- 30 000 khách, mỗi khách 10 đơn
       CASE WHEN i % 1009 = 0 THEN 'pending' WHEN i % 13 = 0 THEN 'cancelled' ELSE 'delivered' END,
       timestamptz '2025-01-01 00:00+00' + i * interval '100 seconds',
       (i % 1000) * 1000
FROM generate_series(1, 300000) i;
CREATE INDEX ord_user              ON p02.ord (user_id);
CREATE INDEX ord_user_dup          ON p02.ord (user_id);                           -- trùng hệt ord_user
CREATE INDEX ord_user_created      ON p02.ord (user_id, created_at);
CREATE INDEX ord_user_created_stat ON p02.ord (user_id, created_at, status);
CREATE INDEX ord_status            ON p02.ord (status);
VACUUM ANALYZE p02.ord;
