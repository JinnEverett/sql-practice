-- db: lab
-- mode: check
-- reset
-- Giải thích: partitioning chia một bảng logic thành nhiều bảng vật lý theo khóa partition; ứng dụng vẫn INSERT/SELECT trên bảng cha, Postgres định tuyến dòng vào đúng partition.
--   RANGE hợp với thời gian: mỗi partition một khoảng NỬA MỞ [from, to) nên 2026-02-01 00:00 thuộc partition tháng 2, không thuộc tháng 1.
--   Dòng ngoài mọi khoảng bị TỪ CHỐI (lỗi 23514) trừ khi có partition DEFAULT hứng. PK/UNIQUE trên bảng partition PHẢI chứa khóa partition (ts), vì mỗi partition có index riêng và Postgres
--   không có index toàn cục: ở đây PK (device_id, ts).
--   Ghi giờ UTC tường minh ('…+00') để ranh giới không phụ thuộc múi giờ của phiên.
-- Bẫy: PK (device_id) mà thiếu ts → lỗi 0A000 "unique constraint on partitioned table must include all partitioning columns"; quên DEFAULT → INSERT dòng tháng 4 lỗi;
--   khoảng chồng nhau/để hở; dùng ranh giới '2026-01-31' (hở một ngày).
CREATE TABLE r12.readings (
  device_id int NOT NULL,
  ts        timestamptz NOT NULL,
  value     numeric(10,2) NOT NULL,
  PRIMARY KEY (device_id, ts)
) PARTITION BY RANGE (ts);
CREATE TABLE r12.readings_2026_01 PARTITION OF r12.readings FOR VALUES FROM ('2026-01-01 00:00+00') TO ('2026-02-01 00:00+00');
CREATE TABLE r12.readings_2026_02 PARTITION OF r12.readings FOR VALUES FROM ('2026-02-01 00:00+00') TO ('2026-03-01 00:00+00');
CREATE TABLE r12.readings_2026_03 PARTITION OF r12.readings FOR VALUES FROM ('2026-03-01 00:00+00') TO ('2026-04-01 00:00+00');
CREATE TABLE r12.readings_default PARTITION OF r12.readings DEFAULT;
