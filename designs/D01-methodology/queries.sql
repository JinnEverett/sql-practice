-- D01 · queries.sql — seed + query cho từng access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d01;
SET client_min_messages = warning;

-- §0 Seed cố định: 10k user, 100k bài, ~100k vote (sinh 1M cặp lệch về bài id nhỏ rồi DISTINCT nên còn ~100k)
INSERT INTO users (handle) SELECT 'u' || g FROM generate_series(1, 10000) g;
INSERT INTO posts (author_id, title, created_at)
SELECT 1 + (g % 10000), 'bài ' || g, timestamptz '2026-10-01' + (g * interval '22 seconds')
FROM generate_series(1, 100000) g;                         -- 100k bài trải ~25 ngày
INSERT INTO votes (post_id, user_id, value, created_at)
SELECT p, u, CASE WHEN (p + u) % 5 = 0 THEN -1 ELSE 1 END, now()
FROM (SELECT DISTINCT 1 + floor(100000 * power(((g * 7919) % 100000) / 100000.0, 2))::int AS p,
             1 + (g * 31) % 10000 AS u
      FROM generate_series(1::bigint, 1000000) g) s;
UPDATE posts p SET score = s.sc FROM (SELECT post_id, sum(value) sc FROM votes GROUP BY 1) s WHERE s.post_id = p.id;
ANALYZE users, posts, votes;

-- §1 A1 · vote + đổi vote + vote lặp (idempotent)
DO $$
DECLARE d1 int; d2 int; d3 int; s0 int; s3 int;
BEGIN
    SELECT score INTO s0 FROM posts WHERE id = 99999;
    DELETE FROM votes WHERE post_id = 99999 AND user_id = 4242;           -- đảm bảo user chưa vote
    d1 := cast_vote(99999, 4242, 1::smallint);    -- vote mới: +1
    d2 := cast_vote(99999, 4242, 1::smallint);    -- gửi lại (retry/double-click): 0
    d3 := cast_vote(99999, 4242, -1::smallint);   -- đổi ý: -2
    SELECT score INTO s3 FROM posts WHERE id = 99999;
    ASSERT d1 = 1 AND d2 = 0 AND d3 = -2, format('delta sai: %s %s %s', d1, d2, d3);
    ASSERT s3 = s0 - 1, 'score không khớp sau 3 lần vote';
END $$;

-- §2 A1 · constraint chặn dữ liệu bẩn ngay ở DB
DO $$
BEGIN
    BEGIN INSERT INTO votes (post_id, user_id, value) VALUES (1, 1, 5); ASSERT false, 'value=5 phải bị chặn';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN INSERT INTO votes (post_id, user_id, value) VALUES (1, 999999, 1); ASSERT false, 'user ma phải bị chặn';
    EXCEPTION WHEN foreign_key_violation THEN NULL; END;
END $$;

-- §3 A2 · top 20 bài 24h gần nhất theo score (khung "bây giờ" cố định để kết quả tái lập)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id, title, score FROM posts
WHERE created_at >= timestamptz '2026-10-25' - interval '24 hours' AND created_at < timestamptz '2026-10-25'
ORDER BY score DESC, id LIMIT 20;

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM (SELECT 1 FROM posts
        WHERE created_at >= timestamptz '2026-10-25' - interval '24 hours' AND created_at < timestamptz '2026-10-25'
        ORDER BY score DESC, id LIMIT 20) x;
    ASSERT n = 20, 'top 24h phải đủ 20 bài';
END $$;

-- §4 A3 · trang bài: bài + vote của chính người xem (1 round trip, đi theo PK)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT p.id, p.title, p.score, v.value AS my_vote
FROM posts p LEFT JOIN votes v ON v.post_id = p.id AND v.user_id = 4242
WHERE p.id = 500;

-- §5 A4 · lịch sử vote của 1 user (index votes_user_idx)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT post_id, value, created_at FROM votes WHERE user_id = 4242 ORDER BY created_at DESC LIMIT 50;

-- §6 Đối soát: denormalized score phải bằng sum(votes). Chạy định kỳ; lệch = có đường ghi lách qua cast_vote()
DO $$
DECLARE drift int;
BEGIN
    SELECT count(*) INTO drift FROM posts p
    LEFT JOIN (SELECT post_id, sum(value) s FROM votes GROUP BY 1) v ON v.post_id = p.id
    WHERE p.score <> COALESCE(v.s, 0);
    ASSERT drift = 0, format('%s bài lệch score', drift);
END $$;

-- §7 Ước lượng: kích thước thực đo để thay số vào phép tính ở bước 3
SELECT 'users' AS rel, count(*) AS n, pg_size_pretty(pg_total_relation_size('users')) AS total FROM users
UNION ALL SELECT 'posts', count(*), pg_size_pretty(pg_total_relation_size('posts')) FROM posts
UNION ALL SELECT 'votes', count(*), pg_size_pretty(pg_total_relation_size('votes')) FROM votes;
SELECT pg_total_relation_size('votes')::numeric / count(*) AS bytes_per_vote_incl_index FROM votes;
