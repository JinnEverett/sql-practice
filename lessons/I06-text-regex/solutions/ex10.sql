-- db: shop_s
-- mode: manual
-- Demo trong transaction: index B-tree thường không giúp '%…%', index trigram (pg_trgm) thì dùng được.
BEGIN;
CREATE INDEX tmp_btree_demo ON events ((properties->>'query'));
EXPLAIN (COSTS OFF) SELECT count(*) FROM events WHERE event_type = 'search' AND properties->>'query' ILIKE '%thun%';
CREATE INDEX tmp_trgm_demo ON events USING gin ((properties->>'query') gin_trgm_ops) WHERE event_type = 'search';
EXPLAIN (COSTS OFF) SELECT count(*) FROM events WHERE event_type = 'search' AND properties->>'query' ILIKE '%thun%';
ROLLBACK;
