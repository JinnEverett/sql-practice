-- O04 · Connections. Chạy trên DB `lab`, schema `o04`. Chạy lại bao nhiêu lần cũng được.
-- Dữ liệu cố định (không phụ thuộc server) cho ex02, ex03; ex01 đọc thẳng pg_settings của server đang chạy.
DROP SCHEMA IF EXISTS o04 CASCADE;
CREATE SCHEMA o04;

-- Mỗi dịch vụ chạy `instances` bản, mỗi bản mở một pool `pool_size` kết nối tới Postgres.
CREATE TABLE o04.apps (app text PRIMARY KEY, instances int NOT NULL, pool_size int NOT NULL);
INSERT INTO o04.apps VALUES
  ('api', 6, 10), ('worker', 4, 5), ('cron', 1, 3), ('admin', 2, 5), ('reports', 3, 8);

-- Ảnh chụp tay của pg_stat_activity lúc có sự cố (đã rút gọn). idle_s = giây kể từ lần đổi state cuối;
-- xact_age_s = tuổi transaction (NULL khi không có transaction mở).
CREATE TABLE o04.activity_snapshot (
  pid int PRIMARY KEY, usename text NOT NULL, application_name text NOT NULL,
  state text NOT NULL, idle_s int NOT NULL, xact_age_s int, query text NOT NULL);
INSERT INTO o04.activity_snapshot VALUES
  (101, 'app',     'api-1',   'idle in transaction',            340, 345,  'UPDATE orders SET status = ''paid'' WHERE id = 7'),
  (102, 'app',     'api-2',   'idle',                             5, NULL, 'SELECT 1'),
  (103, 'app',     'api-3',   'idle',                          1200, NULL, 'SELECT * FROM products WHERE id = 3'),
  (104, 'app',     'worker',  'idle in transaction',             45,  50,  'SELECT * FROM jobs FOR UPDATE SKIP LOCKED'),
  (105, 'app',     'worker',  'idle in transaction (aborted)',   90,  95,  'INSERT INTO jobs VALUES (1)'),
  (106, 'report',  'reports', 'idle',                          2000, NULL, 'SELECT count(*) FROM orders'),
  (107, 'monitor', 'pgwatch', 'idle in transaction',            400, 400,  'SELECT * FROM pg_stat_activity'),
  (108, 'app',     'api-1',   'active',                           0,   3,  'SELECT pg_sleep(3)'),
  (109, 'app',     'cron',    'idle',                           899, NULL, 'SELECT 1'),
  (110, 'app',     'admin',   'idle',                           901, NULL, 'SELECT 1');
