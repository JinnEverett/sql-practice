-- db: lab
-- mode: manual
-- Demo thu nhỏ (100k dòng, chạy trong transaction rồi ROLLBACK): filenode đổi = bảng bị ghi lại (rewrite).
BEGIN;
CREATE TABLE f09.big_demo AS SELECT g AS id, now() AS created_at FROM generate_series(1, 100000) g;
CREATE TEMP TABLE fn AS SELECT 0 AS step, pg_relation_filenode('f09.big_demo') AS node;
ALTER TABLE f09.big_demo ADD COLUMN a int DEFAULT 0;
INSERT INTO fn SELECT 1, pg_relation_filenode('f09.big_demo');
ALTER TABLE f09.big_demo ADD COLUMN b timestamptz DEFAULT clock_timestamp();
INSERT INTO fn SELECT 2, pg_relation_filenode('f09.big_demo');
ALTER TABLE f09.big_demo ALTER COLUMN id TYPE bigint;
INSERT INTO fn SELECT 3, pg_relation_filenode('f09.big_demo');
ALTER TABLE f09.big_demo ADD CONSTRAINT big_demo_a_chk CHECK (a >= 0);
INSERT INTO fn SELECT 4, pg_relation_filenode('f09.big_demo');
SELECT step, node, node <> lag(node) OVER (ORDER BY step) AS rewritten FROM fn ORDER BY step;
ROLLBACK;
