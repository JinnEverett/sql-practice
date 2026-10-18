WITH RECURSIVE need AS (
  SELECT child AS part, qty * 10 AS total_qty FROM i02.bom WHERE parent = 'Laptop'
  UNION ALL
  SELECT b.child, b.qty * 10 FROM need JOIN i02.bom b ON b.parent = need.part)
SELECT part, sum(total_qty) AS total_qty FROM need WHERE NOT EXISTS (SELECT 1 FROM i02.bom b WHERE b.parent = need.part)
GROUP BY part ORDER BY part;
