-- P10a/P10b · bảng 10 triệu dòng để đo ở quy mô "l" mà KHÔNG cần sinh shop_l (~9 GB). Chạy trên DB `lab`.
-- Tạo schema p10l (check không đụng tới). ~1 GB heap + ~600 MB index, mất 1–2 phút. Xóa khi xong: DROP SCHEMA p10l CASCADE;
-- Đây là bảng tổng hợp (cùng cột với p10.t_*), KHÔNG phải shop_l: dùng để đo hiệu ứng quy mô trên bảng hẹp.
DROP SCHEMA IF EXISTS p10l CASCADE;
CREATE SCHEMA p10l;
CREATE TABLE p10l.t_l (
  id int PRIMARY KEY, u int NOT NULL, ts timestamptz NOT NULL, grp int NOT NULL, amount int NOT NULL, gen int NOT NULL, pad text NOT NULL)
WITH (autovacuum_enabled = false);
INSERT INTO p10l.t_l
SELECT i, (hashint4(i) & 2147483647) % 1000000,
       timestamptz '2025-01-01 00:00+00' + i * interval '30 seconds',
       (hashint4(i + 7) & 2147483647) % 1000,
       (hashint4(i + 13) & 2147483647) % 100000,
       i / 10,
       left(md5(i::text), 30)
FROM generate_series(1, 10000000) i;
CREATE INDEX t_l_u_idx  ON p10l.t_l (u);
CREATE INDEX t_l_ts_idx ON p10l.t_l (ts);
VACUUM ANALYZE p10l.t_l;
