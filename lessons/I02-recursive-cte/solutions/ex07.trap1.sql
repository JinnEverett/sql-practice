WITH RECURSIVE r AS (
  SELECT dst AS at, ARRAY['SGN', dst] AS visited, 1 AS legs, price AS total_price FROM i02.flights WHERE src = 'SGN'
  UNION ALL
  SELECT f.dst, r.visited || f.dst, r.legs + 1, r.total_price + f.price FROM r JOIN i02.flights f ON f.src = r.at
  WHERE NOT f.dst = ANY (r.visited))
SELECT array_to_string(visited, '→') AS route, legs, total_price FROM r WHERE at = 'HAN' ORDER BY total_price, route LIMIT 3;
