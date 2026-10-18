UPDATE i07.products
SET attributes = jsonb_strip_nulls((attributes - 'weight_g') || jsonb_build_object('weight_kg', round((attributes->>'weight_g')::numeric / 1000, 3))
                 || '{"warranty_months": 12}'::jsonb);
