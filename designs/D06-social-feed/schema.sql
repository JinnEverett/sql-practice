-- D06 · Social feed: follow graph, fan-out on write/read (hybrid), counter hot row. DB: lab, schema d06.
DROP SCHEMA IF EXISTS d06 CASCADE;
CREATE SCHEMA d06;
SET search_path = d06;

CREATE TABLE users (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    handle          text NOT NULL UNIQUE,
    followers_count integer NOT NULL DEFAULT 0,           -- denormalized, cập nhật theo lô/bất đồng bộ (xem REFERENCE)
    is_celebrity    boolean NOT NULL DEFAULT false        -- nhiều follower => KHÔNG fan-out on write, đọc theo kiểu pull
);

CREATE TABLE follows (
    follower_id bigint NOT NULL REFERENCES users(id),
    followee_id bigint NOT NULL REFERENCES users(id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (follower_id, followee_id),                -- "tôi follow ai" + chống follow trùng
    CHECK (follower_id <> followee_id)
);
CREATE INDEX follows_followee_idx ON follows (followee_id, follower_id);   -- "ai follow tôi" (fan-out, đếm)

-- id tăng dần ~ theo thời gian (identity): sắp xếp feed và keyset pagination dùng id, không cần created_at
CREATE TABLE posts (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id  bigint NOT NULL REFERENCES users(id),
    body       text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    like_count integer NOT NULL DEFAULT 0                  -- bản "ngây thơ", chỉ dùng trong thí nghiệm hot row
);
CREATE INDEX posts_author_idx ON posts (author_id, id DESC);

-- Fan-out on write: hộp thư đến của từng user. Mỗi bài của tác giả thường -> 1 dòng cho mỗi follower
CREATE TABLE feed_items (
    user_id bigint NOT NULL,
    post_id bigint NOT NULL,
    PRIMARY KEY (user_id, post_id)
) WITH (fillfactor = 100);
-- Không FK tới posts/users: bảng này ghi cực nhiều, mất dòng/ dòng mồ côi chấp nhận được (lọc lúc đọc, dọn nền)

-- Likes: đúng một lần mỗi (post, user); đếm bằng counter chia mảnh
CREATE TABLE likes (
    post_id bigint NOT NULL,
    user_id bigint NOT NULL,
    PRIMARY KEY (post_id, user_id)
);
CREATE TABLE like_counters (
    post_id bigint   NOT NULL,
    shard   smallint NOT NULL CHECK (shard BETWEEN 0 AND 15),
    n       bigint   NOT NULL DEFAULT 0,
    PRIMARY KEY (post_id, shard)
) WITH (fillfactor = 70);

-- Fan-out một bài cho follower của tác giả (không áp dụng với celebrity). Trả số dòng đã chèn.
CREATE FUNCTION fanout_post(p_post bigint) RETURNS bigint LANGUAGE sql SET search_path = d06 AS $$
    WITH p AS (SELECT id, author_id FROM posts WHERE id = p_post),
    ins AS (
        INSERT INTO feed_items (user_id, post_id)
        SELECT f.follower_id, p.id FROM p
        JOIN users a ON a.id = p.author_id AND NOT a.is_celebrity
        JOIN follows f ON f.followee_id = p.author_id
        ON CONFLICT DO NOTHING
        RETURNING 1)
    SELECT count(*) FROM ins $$;

-- Like idempotent + đếm theo mảnh ngẫu nhiên: 16 dòng thay cho 1 hot row
CREATE FUNCTION like_post(p_post bigint, p_user bigint) RETURNS boolean LANGUAGE plpgsql SET search_path = d06 AS $$
BEGIN
    INSERT INTO likes (post_id, user_id) VALUES (p_post, p_user) ON CONFLICT DO NOTHING;
    IF NOT FOUND THEN RETURN false; END IF;
    INSERT INTO like_counters (post_id, shard, n) VALUES (p_post, (random() * 15)::int, 1)
    ON CONFLICT (post_id, shard) DO UPDATE SET n = like_counters.n + 1;
    RETURN true;
END $$;

-- Feed hybrid: hộp thư (push) + bài mới của celebrity mà user follow (pull), keyset theo post id.
CREATE FUNCTION feed_page(p_user bigint, p_before bigint DEFAULT 9223372036854775807, p_limit int DEFAULT 20)
RETURNS TABLE (post_id bigint, author_id bigint) LANGUAGE sql STABLE SET search_path = d06 AS $$
    SELECT x.post_id, x.author_id FROM (
        (SELECT fi.post_id, p.author_id FROM feed_items fi JOIN posts p ON p.id = fi.post_id
          WHERE fi.user_id = p_user AND fi.post_id < p_before ORDER BY fi.post_id DESC LIMIT p_limit)
        UNION ALL
        (SELECT p.id, p.author_id FROM follows f JOIN users c ON c.id = f.followee_id AND c.is_celebrity
           CROSS JOIN LATERAL (SELECT id, author_id FROM posts WHERE author_id = c.id AND id < p_before ORDER BY id DESC LIMIT p_limit) p
          WHERE f.follower_id = p_user)
    ) x ORDER BY x.post_id DESC LIMIT p_limit $$;

-- Bảng cho thí nghiệm hot row
CREATE TABLE demo_hot (id int PRIMARY KEY, n bigint NOT NULL DEFAULT 0) WITH (fillfactor = 70);
CREATE TABLE demo_shards (id int, shard smallint, n bigint NOT NULL DEFAULT 0, PRIMARY KEY (id, shard)) WITH (fillfactor = 70);
