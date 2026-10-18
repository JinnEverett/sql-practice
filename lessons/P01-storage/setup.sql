-- P01 · dữ liệu cho ex03–ex06. Chạy trên DB `lab`. Chạy lại được nhiều lần.
CREATE EXTENSION IF NOT EXISTS pageinspect;
DROP SCHEMA IF EXISTS p01 CASCADE;
CREATE SCHEMA p01;

-- ex03/ex04: 3 loại tài liệu, dài 96 B / 6 KB nén tốt / 60 KB không nén được. Nội dung sinh từ md5 nên cố định giữa các lần chạy.
CREATE TABLE p01.docs (
  id   int PRIMARY KEY,
  kind text NOT NULL,          -- 'short' | 'medium' | 'long'
  body text NOT NULL
);
INSERT INTO p01.docs
SELECT i, 'short', repeat(md5(i::text), 3)                                   -- 96 B
FROM generate_series(1, 300) i;
INSERT INTO p01.docs
SELECT 1000 + i, 'medium', repeat(md5(i::text) || ' ', 190)                  -- 6 460 B, lặp nhiều nên nén tốt
FROM generate_series(1, 300) i;
INSERT INTO p01.docs
SELECT 2000 + i, 'long', (SELECT string_agg(md5(i::text || j), '') FROM generate_series(1, 1900) j)    -- 60 800 B
FROM generate_series(1, 300) i;
ANALYZE p01.docs;

-- ex05: cùng cột, thứ tự cột "xấu" (xen kẽ cột 1 byte và 8 byte)
CREATE TABLE p01.pad_bad (
  a boolean, b bigint, c boolean, d bigint, e boolean, f smallint
);
INSERT INTO p01.pad_bad SELECT i % 2 = 0, i, i % 3 = 0, i * 2, i % 5 = 0, (i % 100)::smallint FROM generate_series(1, 50000) i;

-- ex06: bộ đếm; 2000 dòng, fillfactor 100 (mặc định), index trên label
CREATE TABLE p01.counters (
  id    int PRIMARY KEY,
  label text NOT NULL,
  hits  int NOT NULL DEFAULT 0
);
INSERT INTO p01.counters SELECT i, 'lbl-' || lpad(i::text, 5, '0'), 0 FROM generate_series(1, 2000) i;
CREATE INDEX counters_label_idx ON p01.counters (label);
