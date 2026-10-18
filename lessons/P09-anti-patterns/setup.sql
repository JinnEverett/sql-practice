-- P09 · dữ liệu cho ex05. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS p09 CASCADE;
CREATE SCHEMA p09;
CREATE TABLE p09.docs (
  id    int PRIMARY KEY,
  kind  text NOT NULL,        -- 'short' | 'long'
  title text NOT NULL,
  body  text NOT NULL         -- 'long': 60 KB không nén được → nằm ở TOAST
);
INSERT INTO p09.docs SELECT i, 'short', 'doc ' || i, repeat(md5(i::text), 3) FROM generate_series(1, 300) i;
INSERT INTO p09.docs SELECT 1000 + i, 'long', 'doc ' || (1000 + i),
       (SELECT string_agg(md5(i::text || j), '') FROM generate_series(1, 1900) j)
FROM generate_series(1, 300) i;
ANALYZE p09.docs;
