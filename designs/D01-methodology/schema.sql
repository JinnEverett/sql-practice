-- D01 · Ví dụ áp dụng khung 7 bước: hệ thống vote bài đăng (kiểu Reddit-lite). DB: lab, schema d01.
DROP SCHEMA IF EXISTS d01 CASCADE;
CREATE SCHEMA d01;
SET search_path = d01;

CREATE TABLE users (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    handle     text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT users_handle_uk UNIQUE (handle)
);

CREATE TABLE posts (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id  bigint NOT NULL REFERENCES users(id),
    title      text NOT NULL CHECK (length(title) BETWEEN 1 AND 300),
    created_at timestamptz NOT NULL DEFAULT now(),
    -- denormalized: score = sum(votes.value). Chỉ cập nhật qua d01.cast_vote() (cùng transaction với votes)
    score      integer NOT NULL DEFAULT 0
);
COMMENT ON COLUMN posts.score IS 'Bản sao của sum(votes.value); nguồn sự thật là bảng votes. Đối soát bằng queries.sql §6.';

CREATE TABLE votes (
    post_id    bigint NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id    bigint NOT NULL REFERENCES users(id),
    value      smallint NOT NULL CHECK (value IN (-1, 1)),
    created_at timestamptz NOT NULL DEFAULT now(),
    -- 1 người 1 phiếu / bài: rule nghiệp vụ nằm ở tầng DB, không tin app
    PRIMARY KEY (post_id, user_id)
);
-- Access pattern A4 (lịch sử vote của 1 user) cần đi từ user_id
CREATE INDEX votes_user_idx ON votes (user_id, created_at DESC);
-- Access pattern A2 (top bài mới): lọc theo created_at, sắp theo score
CREATE INDEX posts_created_idx ON posts (created_at DESC);

-- Vote idempotent + cập nhật score bằng delta, một câu lệnh, một transaction.
-- Trả về delta đã áp dụng (0 nếu vote lặp lại).
CREATE FUNCTION cast_vote(p_post bigint, p_user bigint, p_value smallint) RETURNS integer
LANGUAGE sql AS $$
    WITH v AS (
        INSERT INTO votes AS t (post_id, user_id, value) VALUES (p_post, p_user, p_value)
        ON CONFLICT (post_id, user_id) DO UPDATE SET value = EXCLUDED.value, created_at = now()
        RETURNING old.value AS old_v, new.value AS new_v          -- OLD/NEW trong RETURNING: Postgres 18
    ), u AS (
        UPDATE posts SET score = score + (v.new_v - COALESCE(v.old_v, 0))
        FROM v WHERE posts.id = p_post
        RETURNING v.new_v - COALESCE(v.old_v, 0) AS delta
    )
    SELECT delta FROM u;
$$;
