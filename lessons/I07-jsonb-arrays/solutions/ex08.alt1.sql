UPDATE i07.products SET attributes = attributes || '{"warranty_months": 12}' WHERE NOT attributes ? 'warranty_months';
UPDATE i07.products SET attributes = (attributes - 'weight_g') || jsonb_build_object('weight_kg', round((attributes->>'weight_g')::numeric / 1000, 3))
WHERE attributes ? 'weight_g';
UPDATE i07.products SET attributes = attributes - 'size' WHERE attributes->'size' = 'null'::jsonb;
