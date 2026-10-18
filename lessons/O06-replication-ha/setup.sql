-- O06 · Replication & HA. Chạy trên DB `lab`, schema `o06`. Chạy lại bao nhiêu lần cũng được.
-- Dữ liệu CỐ ĐỊNH (không cần replica thật) cho ex01–ex03: ảnh chụp pg_stat_replication và bảng phiên của một ứng dụng.
DROP SCHEMA IF EXISTS o06 CASCADE;
CREATE SCHEMA o06;

-- Ảnh chụp pg_stat_replication của 5 replica. replay_lag NULL = replica đang nhàn rỗi và đã bắt kịp (Postgres để NULL).
CREATE TABLE o06.replica_status (
  replica text PRIMARY KEY, state text NOT NULL,
  sent_lsn pg_lsn NOT NULL, write_lsn pg_lsn NOT NULL, flush_lsn pg_lsn NOT NULL, replay_lsn pg_lsn NOT NULL,
  replay_lag interval);
INSERT INTO o06.replica_status VALUES
  ('r1', 'streaming', '0/9000000',  '0/9000000',  '0/9000000',  '0/9000000',  NULL),
  ('r2', 'streaming', '0/10000000', '0/F800000',  '0/F000000',  '0/E000000',  '00:00:02.5'),
  ('r3', 'streaming', '0/10000000', '0/10000000', '0/10000000', '0/FF00000',  '00:00:09'),
  ('r4', 'catchup',   '0/8000000',  '0/4000000',  '0/3000000',  '0/2000000',  '00:01:10'),
  ('r5', 'streaming', '0/10000000', '0/10000000', '0/10000000', '0/FFF0000',  '00:00:00.2');

-- Mỗi người dùng nhớ LSN của lần ghi gần nhất của họ ("token" read-your-writes); NULL = chưa ghi gì.
CREATE TABLE o06.sessions (user_id int PRIMARY KEY, last_write_lsn pg_lsn);
INSERT INTO o06.sessions VALUES
  (1, '0/9000000'), (2, '0/10000000'), (3, '0/F000000'), (4, NULL), (5, '0/A000000'), (6, '0/20000000');

-- Vị trí replay hiện tại của các replica đang phục vụ đọc.
CREATE TABLE o06.replicas_now (replica text PRIMARY KEY, replay_lsn pg_lsn NOT NULL);
INSERT INTO o06.replicas_now VALUES ('r1', '0/10000000'), ('r2', '0/E000000'), ('r3', '0/9000000');
