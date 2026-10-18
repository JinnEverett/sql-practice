SELECT id, (attributes->'color')::text AS color, (attributes->'size')::text AS size, (attributes->>'weight_g')::int AS weight_g,
       (attributes->>'warranty_months')::int AS warranty_months
FROM products WHERE id <= 10 ORDER BY id;
