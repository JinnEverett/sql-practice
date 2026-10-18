-- D10 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql (đã dựng d10_s1, d10_s2 và schema lab.d10).
SET search_path = d10;
SET client_min_messages = warning;

-- §0 Seed. users: 200k dòng, ghi qua router (định tuyến theo hash(user_id) sang 2 shard). events: 3M dòng trải 3 tháng, cùng dữ liệu vào bảng partition và bảng phẳng.
ALTER FOREIGN TABLE users_p0 OPTIONS (ADD batch_size '1000');
ALTER FOREIGN TABLE users_p1 OPTIONS (ADD batch_size '1000');
INSERT INTO users (user_id, handle, country, balance)
SELECT g, 'u' || g, (ARRAY['VN','US','SG','JP','TH','KR','ID','PH'])[1 + g % 8], 1000000 FROM generate_series(1, 200000) g;
INSERT INTO events (id, user_id, ts, kind, payload) OVERRIDING SYSTEM VALUE
SELECT g, 1 + (g * 7919::bigint) % 200000, timestamptz '2026-08-01' + g * interval '2.6 seconds', (g % 5)::smallint, 'p' || g
FROM generate_series(1, 3000000) g;
INSERT INTO events_flat SELECT * FROM events;
VACUUM (ANALYZE) events_flat;
VACUUM (ANALYZE) events;
ANALYZE users;
SELECT (SELECT count(*) FROM events) AS events, (SELECT count(*) FROM events_flat) AS events_flat, (SELECT count(*) FROM users) AS users;

-- §1 Định tuyến theo hash: cân bằng giữa 2 shard, và biết user nằm ở đâu
DO $$
DECLARE c0 bigint; c1 bigint; where_is text;
BEGIN
    SELECT count(*) INTO c0 FROM users_p0;
    SELECT count(*) INTO c1 FROM users_p1;
    ASSERT c0 + c1 = 200000, 'đủ dòng';
    ASSERT abs(c0 - c1) < 0.02 * 200000, format('lệch shard quá 2%%: %s vs %s', c0, c1);    -- hash phân bố đều, khác với range theo id
    SELECT tableoid::regclass::text INTO where_is FROM users WHERE user_id = 12345;
    ASSERT where_is IN ('users_p0', 'users_p1'), 'phải biết shard';
    RAISE WARNING 'shard sizes: p0=% p1=% ; user 12345 nằm ở %', c0, c1, where_is;
END $$;

-- §2 Truy vấn CÓ khóa shard chỉ chạm MỘT shard (partition pruning trên foreign partition)
DO $$
DECLARE r text; touched int := 0;
BEGIN
    FOR r IN EXECUTE 'EXPLAIN (COSTS OFF) SELECT * FROM users WHERE user_id = 12345' LOOP
        IF r ~ 'Foreign Scan' THEN touched := touched + 1; END IF;
    END LOOP;
    ASSERT touched = 1, format('truy vấn theo khóa shard phải chạm đúng 1 shard, chạm %s', touched);
END $$;
EXPLAIN (VERBOSE, COSTS OFF) SELECT balance FROM users WHERE user_id = 12345;

-- §3 Truy vấn KHÔNG có khóa shard phải hỏi mọi shard (scatter-gather). Ở N shard: N round trip, độ trễ = shard chậm nhất.
DO $$
DECLARE r text; touched int := 0;
BEGIN
    FOR r IN EXECUTE $q$EXPLAIN (COSTS OFF) SELECT * FROM users WHERE handle = 'u777'$q$ LOOP
        IF r ~ 'Foreign Scan' THEN touched := touched + 1; END IF;
    END LOOP;
    ASSERT touched = 2, 'tìm theo cột không phải khóa shard phải hỏi cả 2 shard';
END $$;
EXPLAIN (VERBOSE, COSTS OFF) SELECT * FROM users WHERE handle = 'u777';

-- §4 Tổng hợp xuyên shard: không đẩy aggregate xuống => kéo toàn bộ dòng về router; đẩy xuống => mỗi shard trả vài dòng
SET enable_partitionwise_aggregate = off;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT country, count(*), sum(balance) FROM users GROUP BY country;
SET enable_partitionwise_aggregate = on;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT country, count(*), sum(balance) FROM users GROUP BY country;
DO $$
DECLARE a bigint; b bigint;
BEGIN
    SET LOCAL enable_partitionwise_aggregate = off;
    SELECT sum(c) INTO a FROM (SELECT count(*) c FROM users GROUP BY country) x;
    SET LOCAL enable_partitionwise_aggregate = on;
    SELECT sum(c) INTO b FROM (SELECT count(*) c FROM users GROUP BY country) x;
    ASSERT a = 200000 AND b = 200000, 'hai cách phải cho cùng kết quả';
END $$;

-- §5 Partition theo thời gian: truy vấn có khoảng thời gian chỉ chạm các partition liên quan
DO $$
DECLARE r text; seen text := '';
BEGIN
    FOR r IN EXECUTE $q$EXPLAIN (COSTS OFF) SELECT count(*) FROM events WHERE ts >= '2026-09-10' AND ts < '2026-09-11'$q$ LOOP seen := seen || r || E'\n'; END LOOP;
    ASSERT seen ~ 'events_2026_09' AND seen !~ 'events_2026_08' AND seen !~ 'events_2026_10', 'chỉ partition tháng 9 được quét';
END $$;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT count(*) FROM events WHERE ts >= '2026-09-10' AND ts < '2026-09-11';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT count(*) FROM events_flat WHERE ts >= '2026-09-10' AND ts < '2026-09-11';

-- §6 Truy vấn nóng "sự kiện gần nhất của user" trên bảng partition vs bảng phẳng (cùng index (user_id, ts DESC))
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT id, ts FROM events WHERE user_id = 777 ORDER BY ts DESC LIMIT 20;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT id, ts FROM events_flat WHERE user_id = 777 ORDER BY ts DESC LIMIT 20;

-- §7 MÔ HÌNH (không phải đo) hit-rate của cache khi truy cập lệch kiểu Zipf (độ lệch s), 1M khóa, cache giữ K khóa nóng nhất
WITH p AS (SELECT s FROM (VALUES (0.8::float8), (1.0), (1.2)) v(s)),
     w AS (SELECT p.s, r, 1.0 / power(r, p.s) AS wt FROM p, generate_series(1, 1000000) r),
     tot AS (SELECT s, sum(wt) t FROM w GROUP BY s)
SELECT w.s AS zipf_s,
       round((100 * sum(wt) FILTER (WHERE r <= 1000)  / t)::numeric, 1) AS hit_pct_cache_0_1pct,
       round((100 * sum(wt) FILTER (WHERE r <= 10000) / t)::numeric, 1) AS hit_pct_cache_1pct,
       round((100 * sum(wt) FILTER (WHERE r <= 50000) / t)::numeric, 1) AS hit_pct_cache_5pct
FROM w JOIN tot USING (s) GROUP BY w.s, t ORDER BY w.s;

-- §8 Kích thước thực đo
SELECT 'events (partitioned)' AS rel, pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS total
FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid WHERE i.inhparent = 'events'::regclass
UNION ALL SELECT 'events_flat', pg_size_pretty(pg_total_relation_size('events_flat'));
