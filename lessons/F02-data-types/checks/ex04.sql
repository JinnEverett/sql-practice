-- db: lab
-- ordered
SELECT id, qty, unit_price_vnd, qty::bigint * unit_price_vnd AS line_total
FROM f02.b2b_lines ORDER BY line_total DESC, id;
