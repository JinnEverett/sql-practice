-- R07 · dữ liệu nhỏ có đáp án tính tay được cho gaps & islands và sessionization. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS r07 CASCADE;
CREATE SCHEMA r07;

-- logins: ngày đăng nhập của user. Có ngày bị ghi hai lần (user 3), có khoảng trống, có cả user chỉ đăng nhập một ngày.
CREATE TABLE r07.logins (user_id int NOT NULL, login_at timestamptz NOT NULL);
INSERT INTO r07.logins VALUES
  (1, '2026-03-01 08:00+00'), (1, '2026-03-02 09:00+00'), (1, '2026-03-03 23:30+00'),
  (1, '2026-03-05 08:00+00'), (1, '2026-03-06 08:00+00'),
  (1, '2026-03-10 08:00+00'),
  (2, '2026-03-01 08:00+00'), (2, '2026-03-03 08:00+00'), (2, '2026-03-05 08:00+00'),
  (3, '2026-03-01 08:00+00'), (3, '2026-03-01 20:00+00'), (3, '2026-03-02 08:00+00'),
  (3, '2026-03-03 08:00+00'), (3, '2026-03-03 09:00+00'), (3, '2026-03-04 08:00+00'),
  (3, '2026-03-07 08:00+00');

-- hits: sự kiện của 2 visitor. Một phiên kết thúc khi im lặng quá 30 phút.
CREATE TABLE r07.hits (visitor text NOT NULL, at timestamptz NOT NULL);
INSERT INTO r07.hits VALUES
  ('a', '2026-03-01 09:00+00'), ('a', '2026-03-01 09:10+00'), ('a', '2026-03-01 09:40+00'),   -- khoảng 30 phút đúng: vẫn cùng phiên
  ('a', '2026-03-01 10:11+00'),                                                               -- 31 phút sau: phiên mới
  ('a', '2026-03-01 10:20+00'),
  ('a', '2026-03-02 09:00+00'),                                                               -- hôm sau: phiên mới
  ('b', '2026-03-01 09:05+00'), ('b', '2026-03-01 09:06+00'),
  ('b', '2026-03-01 12:00+00'), ('b', '2026-03-01 12:29+00'), ('b', '2026-03-01 12:59+00');
