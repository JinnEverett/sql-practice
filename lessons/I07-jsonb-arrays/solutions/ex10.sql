-- db: shop_s
-- mode: manual
-- Demo: plan dùng index GIN (jsonb_path_ops) cho @> và index biểu thức cho ->> (trong transaction).
BEGIN;
CREATE INDEX tmp_gin_demo ON events USING gin (properties jsonb_path_ops);
CREATE INDEX tmp_expr_demo ON events ((properties->>'utm_source'));
EXPLAIN (COSTS OFF) SELECT count(*) FROM events WHERE properties @> '{"utm_source": "tiktok"}';
EXPLAIN (COSTS OFF) SELECT count(*) FROM events WHERE properties->>'utm_source' = 'tiktok';
ROLLBACK;
