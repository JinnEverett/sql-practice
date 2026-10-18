-- R02 · dữ liệu nhỏ có nhiều giá trị trùng để thấy lỗi phân trang. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS r02 CASCADE;
CREATE SCHEMA r02;

-- feed: 200 bài, mỗi nhóm 5 bài CÙNG created_at (các phút liên tiếp) → sắp theo created_at một mình không đủ để phân trang
CREATE TABLE r02.feed (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at timestamptz NOT NULL,
  title      text NOT NULL);
INSERT INTO r02.feed (created_at, title)
SELECT timestamptz '2026-01-01 00:00+00' + (i / 5) * interval '1 minute', 'Bài ' || i FROM generate_series(0, 199) i;
CREATE INDEX feed_created_idx ON r02.feed (created_at DESC, id DESC);

-- members: 60 thành viên, 15 người không có ngày sinh (NULL), ngày sinh trùng nhau
CREATE TABLE r02.members (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name       text NOT NULL,
  birth_date date);
INSERT INTO r02.members (name, birth_date)
SELECT 'Thành viên ' || i, CASE WHEN i % 4 = 0 THEN NULL ELSE date '1990-01-01' + ((i * 7) % 20) * 30 END
FROM generate_series(1, 60) i;

-- tickets: 60 phiếu hỗ trợ, sắp theo (status tăng dần, created_at giảm dần, id giảm dần) → hướng sắp xếp hỗn hợp
CREATE TABLE r02.tickets (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  status     text NOT NULL CHECK (status IN ('closed', 'open', 'pending')),
  created_at timestamptz NOT NULL);
INSERT INTO r02.tickets (status, created_at)
SELECT (ARRAY['open', 'pending', 'closed'])[i % 3 + 1], timestamptz '2026-02-01 00:00+00' + (i % 10) * interval '1 hour'
FROM generate_series(1, 60) i;
