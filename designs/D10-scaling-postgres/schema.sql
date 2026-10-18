-- D10 · Scaling Postgres: partition theo thời gian + shard theo khóa (hash) qua postgres_fdw. DB: lab, schema d10.
-- Shard thật cần Citus hoặc tương đương; ở đây dựng mô hình "tự làm" bằng hash partition mà các partition là foreign table
-- trỏ sang 2 database (d10_s1, d10_s2) để thấy rõ: chọn khóa shard, định tuyến, scatter-gather, và những gì mất đi (giao dịch xuyên shard).
\set ON_ERROR_STOP on
\connect lab
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
DROP SCHEMA IF EXISTS d10 CASCADE;
DROP SERVER IF EXISTS shard1 CASCADE;       -- server/user mapping thuộc database, không thuộc schema
DROP SERVER IF EXISTS shard2 CASCADE;
DROP DATABASE IF EXISTS d10_s1 WITH (FORCE);
DROP DATABASE IF EXISTS d10_s2 WITH (FORCE);
CREATE DATABASE d10_s1;
CREATE DATABASE d10_s2;

-- ===== Mỗi shard: bảng thật =====
\connect d10_s1
CREATE TABLE users_p0 (user_id bigint PRIMARY KEY, handle text NOT NULL, country char(2) NOT NULL, balance bigint NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX ON users_p0 (handle);          -- index theo cột KHÁC khóa shard vẫn là index cục bộ của từng shard (không có index toàn cục)
\connect d10_s2
CREATE TABLE users_p1 (user_id bigint PRIMARY KEY, handle text NOT NULL, country char(2) NOT NULL, balance bigint NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX ON users_p1 (handle);

-- ===== Router (database lab) =====
\connect lab
CREATE SCHEMA d10;
SET search_path = d10;

DO $$
DECLARE port text := current_setting('port');
BEGIN
    EXECUTE format('CREATE SERVER shard1 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host %L, port %L, dbname %L, use_remote_estimate %L, async_capable %L)', 'localhost', port, 'd10_s1', 'true', 'true');
    EXECUTE format('CREATE SERVER shard2 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host %L, port %L, dbname %L, use_remote_estimate %L, async_capable %L)', 'localhost', port, 'd10_s2', 'true', 'true');
END $$;
CREATE USER MAPPING FOR CURRENT_USER SERVER shard1 OPTIONS (user 'postgres', password 'postgres');
CREATE USER MAPPING FOR CURRENT_USER SERVER shard2 OPTIONS (user 'postgres', password 'postgres');

-- Khóa shard = user_id: mọi truy vấn nóng ("của user X") nằm gọn trên MỘT shard.
CREATE TABLE users (
    user_id bigint NOT NULL, handle text NOT NULL, country char(2) NOT NULL, balance bigint NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now()
) PARTITION BY HASH (user_id);
CREATE FOREIGN TABLE users_p0 PARTITION OF users FOR VALUES WITH (MODULUS 2, REMAINDER 0) SERVER shard1 OPTIONS (schema_name 'public', table_name 'users_p0');
CREATE FOREIGN TABLE users_p1 PARTITION OF users FOR VALUES WITH (MODULUS 2, REMAINDER 1) SERVER shard2 OPTIONS (schema_name 'public', table_name 'users_p1');

-- ===== Partition theo thời gian (một node) =====
CREATE TABLE events (
    id         bigint GENERATED ALWAYS AS IDENTITY,
    user_id    bigint NOT NULL,
    ts         timestamptz NOT NULL,
    kind       smallint NOT NULL,
    payload    text,
    PRIMARY KEY (id, ts)
) PARTITION BY RANGE (ts);
CREATE TABLE events_2026_08 PARTITION OF events FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE events_2026_09 PARTITION OF events FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE events_2026_10 PARTITION OF events FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE INDEX events_user_ts_idx ON events (user_id, ts DESC);
CREATE INDEX events_ts_brin ON events USING brin (ts) WITH (pages_per_range = 32);

-- Không partition cùng dữ liệu để so sánh (cùng cột, cùng index)
CREATE TABLE events_flat (LIKE events INCLUDING DEFAULTS);
ALTER TABLE events_flat ADD PRIMARY KEY (id, ts);
CREATE INDEX events_flat_user_ts_idx ON events_flat (user_id, ts DESC);
CREATE INDEX events_flat_ts_brin ON events_flat USING brin (ts) WITH (pages_per_range = 32);
