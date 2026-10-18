-- db: lab
-- mode: manual
-- Demo thu nhỏ (10k nút) trong transaction: xem plan trước/sau khi có index trên parent_id.
BEGIN;
CREATE TABLE i02_tree_demo AS SELECT g AS id, CASE WHEN g = 1 THEN NULL ELSE (g + 8) / 10 END AS parent_id FROM generate_series(1, 10000) g;
ALTER TABLE i02_tree_demo ADD PRIMARY KEY (id);
ANALYZE i02_tree_demo;
EXPLAIN (COSTS OFF) WITH RECURSIVE d AS (SELECT id FROM i02_tree_demo WHERE id = 12
  UNION ALL SELECT t.id FROM i02_tree_demo t JOIN d ON t.parent_id = d.id) SELECT count(*) FROM d;
CREATE INDEX ON i02_tree_demo (parent_id);
ANALYZE i02_tree_demo;
EXPLAIN (COSTS OFF) WITH RECURSIVE d AS (SELECT id FROM i02_tree_demo WHERE id = 12
  UNION ALL SELECT t.id FROM i02_tree_demo t JOIN d ON t.parent_id = d.id) SELECT count(*) FROM d;
ROLLBACK;
