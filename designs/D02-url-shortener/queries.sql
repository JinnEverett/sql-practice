-- D02 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d02;
SET client_min_messages = warning;

-- §0 Seed: 200k link, 1M click (phân phối lệch: link id nhỏ hot), 3 tháng
INSERT INTO links (long_url, owner_id, created_at)
SELECT 'https://example.com/p/' || g, CASE WHEN g % 4 = 0 THEN NULL ELSE g % 5000 END,
       timestamptz '2026-08-01' + (g * interval '30 seconds')
FROM generate_series(1, 200000) g;
INSERT INTO clicks (link_id, clicked_at, country, referrer, ua_class)
SELECT 1 + floor(200000 * power(((g * 7919::bigint) % 200000) / 200000.0, 3))::int,
       timestamptz '2026-08-01' + (g * interval '6 seconds'),
       (ARRAY['VN','US','SG','JP','TH'])[1 + g % 5],
       CASE WHEN g % 3 = 0 THEN 'https://t.co/x' END, (g % 10 = 0)::int
FROM generate_series(1, 1000000) g;
ANALYZE links, clicks;

-- §1 Sinh code: song ánh, không đụng độ, round trip
DO $$
DECLARE dup int; bad int;
BEGIN
    ASSERT base62(0) = '0000000' AND base62(61) = '000000z' AND base62(62) = '0000010', 'base62 sai';
    SELECT count(*) - count(DISTINCT code) INTO dup FROM links;
    ASSERT dup = 0, 'code trùng';
    SELECT count(*) INTO bad FROM links WHERE code !~ '^[0-9A-Za-z]{7}$';
    ASSERT bad = 0, 'code sai định dạng';
    -- hai id liền nhau không cho code liền nhau (khó enumerate)
    ASSERT (SELECT count(*) FROM links a JOIN links b ON b.id = a.id + 1 WHERE substr(a.code, 1, 4) = substr(b.code, 1, 4)) < 1000,
           'code còn tuần tự';
END $$;

-- §2 A1 · tạo link (code do DB sinh), trả code
INSERT INTO links (long_url, owner_id) VALUES ('https://example.com/new', 42) RETURNING id, code;

-- §3 A2 · redirect: code -> long_url (đường nóng nhất, 1 index scan)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT long_url FROM links
WHERE code = short_code(777) AND is_active AND (expires_at IS NULL OR expires_at > now());

DO $$
BEGIN
    ASSERT (SELECT long_url FROM links WHERE code = short_code(777)) = 'https://example.com/p/777', 'lookup sai';
END $$;

-- §4 A3 · ghi click rồi rollup idempotent cho 1 ngày đã đóng (tính lại cả ngày, KHÔNG cộng dồn => chạy lại an toàn)
CREATE FUNCTION rollup_day(d date) RETURNS bigint LANGUAGE sql AS $$
    WITH r AS (
        INSERT INTO click_daily AS c (link_id, day, n, bots)
        SELECT link_id, d, count(*), count(*) FILTER (WHERE ua_class = 2)
        FROM clicks
        WHERE clicked_at >= d::timestamptz AND clicked_at < (d + 1)::timestamptz
        GROUP BY link_id
        ON CONFLICT (link_id, day) DO UPDATE SET n = EXCLUDED.n, bots = EXCLUDED.bots
        RETURNING 1)
    SELECT count(*) FROM r $$;
SELECT rollup_day(date '2026-08-15') AS links_rolled;
DO $$
DECLARE a bigint; b bigint;
BEGIN
    SELECT sum(n) INTO a FROM click_daily WHERE day = '2026-08-15';
    PERFORM rollup_day(date '2026-08-15');                                  -- chạy lại
    SELECT sum(n) INTO b FROM click_daily WHERE day = '2026-08-15';
    ASSERT a = b AND a = (SELECT count(*) FROM clicks WHERE clicked_at >= '2026-08-15' AND clicked_at < '2026-08-16'),
           'rollup không idempotent hoặc sai tổng';
END $$;

-- §5 A4 · dashboard 1 link 30 ngày: đọc click_daily (rẻ) thay vì clicks
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT day, n FROM click_daily WHERE link_id = 1 AND day >= date '2026-08-01' ORDER BY day;

-- §6 Partition pruning: truy vấn có khoảng thời gian chỉ chạm 1 partition
DO $$
DECLARE r text; parts int := 0;
BEGIN
    FOR r IN EXECUTE $q$EXPLAIN SELECT count(*) FROM clicks WHERE clicked_at >= '2026-09-10' AND clicked_at < '2026-09-11'$q$ LOOP
        IF r ~ 'clicks_2026_\d\d' AND r ~ 'Scan' THEN parts := parts + 1; END IF;
    END LOOP;
    ASSERT parts = 1, format('pruning: %s partition bị quét', parts);
END $$;

-- §7 Retention: bỏ tháng cũ bằng DETACH + DROP (không DELETE, không bloat)
CREATE TABLE clicks_2026_07 PARTITION OF clicks FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
ALTER TABLE clicks DETACH PARTITION clicks_2026_07;
DROP TABLE clicks_2026_07;

-- §8 Kích thước thực đo
SELECT 'links' rel, count(*) n, pg_size_pretty(pg_total_relation_size('links')) total, round(pg_total_relation_size('links')::numeric / count(*)) B_per_row FROM links
UNION ALL SELECT 'clicks', (SELECT count(*) FROM clicks), pg_size_pretty(sum(pg_total_relation_size(c.oid))),
       round(sum(pg_total_relation_size(c.oid))::numeric / (SELECT count(*) FROM clicks))
FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid WHERE i.inhparent = 'clicks'::regclass GROUP BY 1;
