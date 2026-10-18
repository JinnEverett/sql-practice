-- I04 · sổ nhập/xuất kho (ex09). Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS i04 CASCADE;
CREATE SCHEMA i04;
CREATE TABLE i04.stock_moves (
  id         int PRIMARY KEY,
  product_id int NOT NULL,
  moved_at   timestamptz NOT NULL,
  qty        int NOT NULL            -- dương = nhập, âm = xuất
);
INSERT INTO i04.stock_moves VALUES
  (1, 1, '2026-10-01 08:00+07',  10),
  (2, 1, '2026-10-01 12:00+07',  -4),
  (3, 1, '2026-10-02 09:00+07',  -5),
  (4, 1, '2026-10-02 15:00+07',  -3),   -- tồn 1 → -2: âm lần đầu
  (5, 1, '2026-10-03 08:00+07',  20),
  (6, 1, '2026-10-04 10:00+07', -25),   -- âm lần 2 (không lấy)
  (7, 2, '2026-10-01 09:00+07',   5),
  (8, 2, '2026-10-01 10:00+07',  -5),   -- về 0, không âm
  (9, 2, '2026-10-02 11:00+07',   3),
  (10, 3, '2026-10-01 07:00+07', -1),   -- âm ngay dòng đầu
  (11, 3, '2026-10-01 08:00+07', 10),
  (12, 4, '2026-10-02 08:00+07',  8),
  (13, 4, '2026-10-02 08:00+07', -9),   -- cùng thời điểm với dòng 12: xét theo id
  (14, 4, '2026-10-03 08:00+07',  6);
