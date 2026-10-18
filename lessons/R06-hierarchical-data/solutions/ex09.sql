-- db: lab
-- mode: manual
-- Demo (11 111 nút, chạy trong ~1 giây): cùng một cây k = 10, sâu 5 tầng, dựng bằng 4 cách; so truy vấn "cây con của nút 12".
-- Muốn tái hiện số đo ở ex09.md: đổi 5 thành 6 hoặc 7 (111 111 và 1 111 111 nút; mức 7 mất khoảng 1 phút để dựng).
DROP SCHEMA IF EXISTS r06b CASCADE;
CREATE SCHEMA r06b;
CREATE TABLE r06b.adj (id int PRIMARY KEY, parent_id int, depth int NOT NULL);
INSERT INTO r06b.adj
SELECT i, CASE WHEN i = 1 THEN NULL ELSE (i - 2) / 10 + 1 END, floor(log(10, (9 * (i - 1) + 1)::numeric))::int
FROM generate_series(1, (power(10, 5)::bigint - 1) / 9) i;                       -- nút i có cha (i-2)/10+1
CREATE INDEX adj_parent ON r06b.adj (parent_id);

CREATE TABLE r06b.lt AS
WITH RECURSIVE t AS (SELECT id, id::text::ltree AS path FROM r06b.adj WHERE parent_id IS NULL
  UNION ALL SELECT a.id, t.path || a.id::text FROM r06b.adj a JOIN t ON a.parent_id = t.id) SELECT * FROM t;
ALTER TABLE r06b.lt ADD PRIMARY KEY (id);
CREATE INDEX lt_gist ON r06b.lt USING gist (path);

CREATE TABLE r06b.closure (ancestor int NOT NULL, descendant int NOT NULL, depth int NOT NULL);
INSERT INTO r06b.closure
WITH RECURSIVE c AS (SELECT id AS ancestor, id AS descendant, 0 AS depth FROM r06b.adj
  UNION ALL SELECT c.ancestor, a.id, c.depth + 1 FROM c JOIN r06b.adj a ON a.parent_id = c.descendant) SELECT * FROM c;
ALTER TABLE r06b.closure ADD PRIMARY KEY (ancestor, descendant);
CREATE INDEX closure_desc ON r06b.closure (descendant);

CREATE TABLE r06b.ns AS
WITH RECURSIVE w AS (SELECT id, 0 AS depth, ARRAY[id] AS ord FROM r06b.adj WHERE parent_id IS NULL
  UNION ALL SELECT a.id, w.depth + 1, w.ord || a.id FROM r06b.adj a JOIN w ON a.parent_id = w.id),
n AS (SELECT id, depth, row_number() OVER (ORDER BY ord) AS p FROM w)
SELECT n.id, 2 * n.p - n.depth - 1 AS lft, 2 * n.p - n.depth - 1 + 2 * ((power(10, 5 - n.depth)::bigint - 1) / 9) - 1 AS rgt FROM n;
ALTER TABLE r06b.ns ADD PRIMARY KEY (id);
CREATE INDEX ns_lft ON r06b.ns (lft);
VACUUM ANALYZE r06b.adj; VACUUM ANALYZE r06b.lt; VACUUM ANALYZE r06b.closure; VACUUM ANALYZE r06b.ns;

SELECT 'adj' AS repr, pg_size_pretty(pg_total_relation_size('r06b.adj')) AS size
UNION ALL SELECT 'ltree', pg_size_pretty(pg_total_relation_size('r06b.lt'))
UNION ALL SELECT 'closure', pg_size_pretty(pg_total_relation_size('r06b.closure'))
UNION ALL SELECT 'nested set', pg_size_pretty(pg_total_relation_size('r06b.ns'));

\echo '--- Q1: cây con của nút 12'
EXPLAIN (ANALYZE, COSTS OFF) WITH RECURSIVE s AS (SELECT id FROM r06b.adj WHERE id = 12 UNION ALL SELECT a.id FROM r06b.adj a JOIN s ON a.parent_id = s.id) SELECT count(*) FROM s;
EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM r06b.lt WHERE path <@ (SELECT path FROM r06b.lt WHERE id = 12);
EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM r06b.closure WHERE ancestor = 12;
EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM r06b.ns n, r06b.ns r WHERE r.id = 12 AND n.lft BETWEEN r.lft AND r.rgt;
\echo '--- Q3: di chuyển cây con 12 sang làm con của 111 (trong transaction, ROLLBACK)'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) UPDATE r06b.adj SET parent_id = 111 WHERE id = 12;
EXPLAIN (ANALYZE, COSTS OFF) UPDATE r06b.lt SET path = (SELECT path FROM r06b.lt WHERE id = 111) || subpath(path, nlevel((SELECT path FROM r06b.lt WHERE id = 12)) - 1)
  WHERE path <@ (SELECT path FROM r06b.lt WHERE id = 12);
ROLLBACK;
DROP SCHEMA r06b CASCADE;
