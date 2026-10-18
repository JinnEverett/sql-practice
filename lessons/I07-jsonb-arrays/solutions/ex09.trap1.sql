SELECT id, name, (attributes->>'weight_g')::int AS weight_g, (attributes->>'warranty_months')::int AS warranty_months
FROM products WHERE attributes->>'weight_g' > '2000' AND (attributes->>'warranty_months')::int >= 12 ORDER BY id;
