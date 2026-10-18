-- P03 · dữ liệu đọc plan. Chạy trên DB `lab`. Chạy lại được nhiều lần (~3 giây).
DROP SCHEMA IF EXISTS p03 CASCADE;
CREATE SCHEMA p03;
CREATE TABLE p03.u (
  id     int PRIMARY KEY,
  region text NOT NULL,
  name   text NOT NULL
);
INSERT INTO p03.u
SELECT i, (ARRAY['north','south','central','highland','delta'])[1 + i % 5], 'user-' || i
FROM generate_series(1, 20000) i;

CREATE TABLE p03.o (
  id         int PRIMARY KEY,
  user_id    int NOT NULL,
  status     text NOT NULL,
  created_at timestamptz NOT NULL,
  amount     int NOT NULL
);
INSERT INTO p03.o
SELECT i,
       1 + ((i::bigint * 7919) % 20000)::int,                                                    -- 20 000 khách × 20 đơn, rải đều trong bảng
       CASE WHEN i % 100 = 0 THEN 'pending' WHEN i % 10 = 1 THEN 'cancelled' ELSE 'delivered' END,
       timestamptz '2025-01-01 00:00+00' + i * interval '79 seconds',
       (i % 1000) * 1000
FROM generate_series(1, 400000) i;
CREATE INDEX o_user_idx    ON p03.o (user_id);
CREATE INDEX o_created_idx ON p03.o (created_at);
VACUUM ANALYZE p03.u;
VACUUM ANALYZE p03.o;

-- ex08: bảng có trigger đếm số lần UPDATE thật sự chạy (sequence không bị ROLLBACK hoàn tác)
CREATE TABLE p03.acct (id int PRIMARY KEY, balance int NOT NULL);
INSERT INTO p03.acct SELECT i, 100 FROM generate_series(1, 1000) i;
CREATE SEQUENCE p03.touch_seq;
CREATE FUNCTION p03.touch() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM nextval('p03.touch_seq'); RETURN NEW; END $$;
CREATE TRIGGER acct_touch BEFORE UPDATE ON p03.acct FOR EACH ROW EXECUTE FUNCTION p03.touch();
