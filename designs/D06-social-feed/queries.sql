-- D06 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d06;
SET client_min_messages = warning;

-- §0 Seed: 100k user, ~1.5M follow lệch mạnh (vài user rất nổi), 300k bài
INSERT INTO users (handle) SELECT 'u' || g FROM generate_series(1, 100000) g;
INSERT INTO follows (follower_id, followee_id)
SELECT DISTINCT ON (f, e) f, e FROM (
    SELECT 1 + (g % 100000) AS f,
           1 + floor(100000 * power((((g * 7919::bigint) % 1000003) / 1000003.0), 3))::int AS e
    FROM generate_series(1::bigint, 2500000)  g) s
WHERE f <> e ORDER BY f, e;
-- một "power user" (id 100000) follow thêm 2000 tài khoản: ca xấu của fan-out on read
INSERT INTO follows (follower_id, followee_id) SELECT 100000, g FROM generate_series(1, 2000) g ON CONFLICT DO NOTHING;
UPDATE users u SET followers_count = c.n FROM (SELECT followee_id, count(*) n FROM follows GROUP BY 1) c WHERE c.followee_id = u.id;
UPDATE users SET is_celebrity = true WHERE followers_count >= 5000;
INSERT INTO posts (author_id, body, created_at)
SELECT 1 + (g * 31) % 100000, 'post ' || g, timestamptz '2026-09-01' + g * interval '8 seconds'
FROM generate_series(1, 300000) g;
ANALYZE;

-- §1 Hình dạng đồ thị: đo số follower, ngưỡng celebrity
SELECT count(*) AS users, count(*) FILTER (WHERE is_celebrity) AS celebrities,
       max(followers_count) AS max_followers, round(avg(followers_count)) AS avg_followers,
       (SELECT count(*) FROM follows) AS follow_rows
FROM users;
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM users WHERE is_celebrity) BETWEEN 1 AND 2000, 'phải có celebrity nhưng không quá nhiều';
END $$;

-- §2 A1 · đăng bài + fan-out (tác giả thường). Đo write amplification = số dòng feed_items sinh ra / 1 bài
DO $$
DECLARE a bigint; pid bigint; n bigint; fc int;
BEGIN
    SELECT id, followers_count INTO a, fc FROM users WHERE NOT is_celebrity ORDER BY followers_count DESC LIMIT 1;   -- tác giả thường đông follower nhất
    INSERT INTO posts (author_id, body) VALUES (a, 'bài thử fan-out') RETURNING id INTO pid;
    n := fanout_post(pid);
    ASSERT n = fc, format('fan-out %s dòng nhưng tác giả có %s follower', n, fc);
    ASSERT fanout_post(pid) = 0, 'fan-out lặp lại phải không sinh thêm dòng (idempotent)';
    RAISE WARNING 'write amplification lớn nhất của tác giả thường: % dòng cho 1 bài', n;
    -- celebrity không fan-out
    SELECT id INTO a FROM users WHERE is_celebrity LIMIT 1;
    INSERT INTO posts (author_id, body) VALUES (a, 'bài celebrity') RETURNING id INTO pid;
    ASSERT fanout_post(pid) = 0, 'celebrity không fan-out on write';
END $$;

-- Dựng hộp thư cho 20k bài gần nhất của tác giả thường (giả lập hệ thống đã chạy một thời gian)
SELECT sum(fanout_post(id)) AS feed_rows_created, count(*) AS posts_fanned
FROM (SELECT p.id FROM posts p JOIN users a ON a.id = p.author_id AND NOT a.is_celebrity ORDER BY p.id DESC LIMIT 20000) s;
ANALYZE feed_items;

-- §3 A2 · đọc feed: PULL (fan-out on read) — gom bài của mọi người mình follow. Chi phí ~ số người follow
SELECT 100000 AS power_user \gset
SELECT user_id AS feed_user FROM feed_items GROUP BY 1 ORDER BY count(*) DESC, 1 LIMIT 1 \gset
-- Người bình thường follow ~25 tài khoản; power user follow ~2000
SELECT (SELECT count(*) FROM follows WHERE follower_id = 1) AS followings_normal,
       (SELECT count(*) FROM follows WHERE follower_id = :power_user) AS followings_power;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT p.id, p.author_id FROM posts p
WHERE p.author_id IN (SELECT followee_id FROM follows WHERE follower_id = :power_user)
ORDER BY p.id DESC LIMIT 20;

-- (đối chứng) cùng truy vấn pull cho người bình thường (user 1, 25 followings)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT p.id, p.author_id FROM posts p
WHERE p.author_id IN (SELECT followee_id FROM follows WHERE follower_id = 1)
ORDER BY p.id DESC LIMIT 20;

-- §4 A2 · đọc feed: PUSH — 1 index scan trên feed_items. Chi phí không phụ thuộc số người follow (user có nhiều dòng hộp thư nhất)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT fi.post_id, p.author_id FROM feed_items fi JOIN posts p ON p.id = fi.post_id
WHERE fi.user_id = :feed_user ORDER BY fi.post_id DESC LIMIT 20;

-- §5 A2 · hybrid (feed_page) + keyset pagination: trang 2 không trùng, không sót với trang 1
DO $$
DECLARE u bigint; last_id bigint; p1 bigint[]; p2 bigint[];
BEGIN
    SELECT user_id INTO u FROM feed_items GROUP BY 1 ORDER BY count(*) DESC, 1 LIMIT 1;
    SELECT array_agg(post_id ORDER BY post_id DESC) INTO p1 FROM feed_page(u, 9223372036854775807, 5);
    last_id := p1[array_length(p1, 1)];
    SELECT array_agg(post_id ORDER BY post_id DESC) INTO p2 FROM feed_page(u, last_id, 5);
    ASSERT array_length(p1, 1) = 5 AND array_length(p2, 1) = 5, format('mỗi trang 5 bài, có %s và %s', array_length(p1, 1), array_length(p2, 1));
    ASSERT NOT (p1 && p2), 'hai trang không được trùng bài';
    ASSERT p1[5] > p2[1], 'trang 2 phải cũ hơn trang 1';
END $$;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT * FROM feed_page(:feed_user, 9223372036854775807, 20);

-- §6 A3 · like: idempotent, counter chia mảnh cộng lại đúng
DO $$
DECLARE pid bigint := 1; ok1 boolean; ok2 boolean;
BEGIN
    FOR i IN 1..200 LOOP PERFORM like_post(pid, i); END LOOP;
    ok1 := like_post(pid, 5);                                           -- like lại cùng người
    ASSERT NOT ok1, 'like trùng phải bị bỏ qua';
    ASSERT (SELECT sum(n) FROM like_counters WHERE post_id = pid) = 200, 'tổng counter phải = số like';
    ASSERT (SELECT count(*) FROM like_counters WHERE post_id = pid) > 1, 'counter phải rải ra nhiều mảnh';
END $$;

-- §7 Đối soát counter với bảng sự thật (chạy nền): likes là nguồn sự thật
SELECT post_id, c.n AS counter, l.n AS truth FROM
    (SELECT post_id, sum(n) n FROM like_counters GROUP BY 1) c
    JOIN (SELECT post_id, count(*) n FROM likes GROUP BY 1) l USING (post_id) WHERE c.n <> l.n;

-- §8 Kích thước thực đo
ANALYZE;
SELECT relname, reltuples::bigint AS n, pg_size_pretty(pg_total_relation_size(oid)) AS total,
       round(pg_total_relation_size(oid)::numeric / NULLIF(reltuples, 0)) AS bytes_per_row
FROM pg_class WHERE relnamespace = 'd06'::regnamespace AND relname IN ('follows', 'posts', 'feed_items', 'users', 'likes', 'like_counters');
