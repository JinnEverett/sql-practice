-- db: lab
-- mode: manual
-- Demo: INSERT … SELECT 100 000 dòng vào bảng có PK (cách nhanh nhất không cần file). Đo thời gian bằng \timing; WAL bằng pg_current_wal_lsn() trước/sau.
CREATE SCHEMA IF NOT EXISTS p10b;
DROP TABLE IF EXISTS p10b.ld;
CREATE TABLE p10b.ld (id int PRIMARY KEY, u int NOT NULL, ts timestamptz NOT NULL, grp int NOT NULL, amount int NOT NULL, pad text NOT NULL);
INSERT INTO p10b.ld SELECT i, i % 1000000, now(), i % 1000, i % 100000, md5(i::text) FROM generate_series(1, 100000) i;
DROP TABLE p10b.ld;
