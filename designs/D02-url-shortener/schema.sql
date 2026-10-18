-- D02 · URL shortener. DB: lab, schema d02.
DROP SCHEMA IF EXISTS d02 CASCADE;
CREATE SCHEMA d02;
SET search_path = d02;

-- Sinh code 7 ký tự base62 từ id tuần tự, qua một song ánh (nhân với hằng số nguyên tố cùng nhau với 62^7)
-- => code không đoán được thứ tự, không cần retry-on-collision, mọi id < 62^7 (3.52e12) cho code duy nhất.
CREATE FUNCTION base62(n bigint, width int DEFAULT 7) RETURNS text
LANGUAGE plpgsql IMMUTABLE STRICT AS $$
DECLARE
    alphabet constant text := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    s text := '';
BEGIN
    IF n < 0 THEN RAISE EXCEPTION 'n phải >= 0'; END IF;
    WHILE n > 0 LOOP
        s := substr(alphabet, (n % 62)::int + 1, 1) || s;
        n := n / 62;
    END LOOP;
    RETURN lpad(s, width, '0');
END $$;

CREATE FUNCTION short_code(id bigint) RETURNS text
LANGUAGE sql IMMUTABLE STRICT AS $$
    SELECT base62(((id::numeric * 1000000007) % 3521614606208)::bigint);   -- 3521614606208 = 62^7
$$;

CREATE SEQUENCE link_id_seq START 1;

CREATE TABLE links (
    id         bigint PRIMARY KEY DEFAULT nextval('link_id_seq'),
    code       text COLLATE "C" NOT NULL GENERATED ALWAYS AS (short_code(id)) STORED,
    long_url   text NOT NULL CHECK (long_url ~ '^https?://' AND length(long_url) <= 2048),
    owner_id   bigint,                                   -- NULL = ẩn danh
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    is_active  boolean NOT NULL DEFAULT true,
    CONSTRAINT links_code_uk UNIQUE (code)               -- đường đọc nóng nhất: code -> long_url
);
CREATE INDEX links_owner_idx ON links (owner_id, created_at DESC) WHERE owner_id IS NOT NULL;

-- Click: append-only, partition theo tháng => drop partition cũ thay cho DELETE
CREATE TABLE clicks (
    link_id    bigint NOT NULL,                          -- KHÔNG FK: ghi 100s/s, FK check mỗi lần = cost thừa; đối soát bằng job
    clicked_at timestamptz NOT NULL,
    country    char(2),
    referrer   text,
    ua_class   smallint                                  -- 0 desktop, 1 mobile, 2 bot
) PARTITION BY RANGE (clicked_at);
CREATE TABLE clicks_2026_08 PARTITION OF clicks FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE clicks_2026_09 PARTITION OF clicks FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE clicks_2026_10 PARTITION OF clicks FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE INDEX clicks_link_time_idx ON clicks (link_id, clicked_at);

-- Rollup theo ngày: dashboard đọc bảng này, không quét clicks
CREATE TABLE click_daily (
    link_id bigint NOT NULL,
    day     date   NOT NULL,
    n       bigint NOT NULL,
    bots    bigint NOT NULL DEFAULT 0,
    PRIMARY KEY (link_id, day)
);
