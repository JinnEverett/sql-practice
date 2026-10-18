-- sai: ghi đè vô điều kiện → A3 bị ghi giá cũ, A2 bị ghi lại dù giá không đổi
INSERT INTO r03.price_feed AS f (sku, price, src_updated_at)
SELECT DISTINCT ON (sku) sku, price, src_updated_at FROM r03.price_batch ORDER BY sku, src_updated_at DESC
ON CONFLICT (sku) DO UPDATE SET price = EXCLUDED.price, src_updated_at = EXCLUDED.src_updated_at
RETURNING f.sku;
