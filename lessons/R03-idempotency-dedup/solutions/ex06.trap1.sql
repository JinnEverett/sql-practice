-- sai: không dedupe lô → lỗi "ON CONFLICT DO UPDATE command cannot affect row a second time"
INSERT INTO r03.price_feed AS f (sku, price, src_updated_at)
SELECT sku, price, src_updated_at FROM r03.price_batch
ON CONFLICT (sku) DO UPDATE SET price = EXCLUDED.price, src_updated_at = EXCLUDED.src_updated_at
  WHERE EXCLUDED.src_updated_at > f.src_updated_at AND EXCLUDED.price IS DISTINCT FROM f.price
RETURNING f.sku;
