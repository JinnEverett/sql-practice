-- sai: thiếu các cặp tự thân (n, n, 0)
WITH RECURSIVE c AS (
  SELECT parent_id AS ancestor, id AS descendant, 1 AS depth FROM r06.cat WHERE parent_id IS NOT NULL
  UNION ALL
  SELECT c.ancestor, k.id, c.depth + 1 FROM c JOIN r06.cat k ON k.parent_id = c.descendant)
INSERT INTO r06.cat_closure (ancestor, descendant, depth) SELECT ancestor, descendant, depth FROM c;
