-- db: shop_s
-- mode: manual
-- Demo: ba kiểu tìm kiếm trên users/events, có và không có index (trong transaction, ROLLBACK). Đổi sang shop_m để thấy số đo ở ex08.md.
BEGIN;
\echo '--- Q1: ILIKE giữa chuỗi trên users.full_name'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM users WHERE full_name ILIKE '%nguyễn văn hải%';
\echo '--- Q2: full-text trên users.full_name'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM users WHERE to_tsvector('simple', full_name) @@ plainto_tsquery('simple', 'văn hải');
\echo '--- Q3: ILIKE trên từ khóa tìm kiếm trong events (jsonb)'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM events WHERE event_type = 'search' AND properties->>'query' ILIKE '%giày chạy%';
CREATE INDEX tmp_r11_1 ON users USING gin (full_name gin_trgm_ops);
CREATE INDEX tmp_r11_2 ON users USING gin (to_tsvector('simple', full_name));
CREATE INDEX tmp_r11_3 ON events USING gin ((properties->>'query') gin_trgm_ops) WHERE event_type = 'search';
ANALYZE users; ANALYZE events;
\echo '--- sau khi có index'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM users WHERE full_name ILIKE '%nguyễn văn hải%';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM users WHERE to_tsvector('simple', full_name) @@ plainto_tsquery('simple', 'văn hải');
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM events WHERE event_type = 'search' AND properties->>'query' ILIKE '%giày chạy%';
ROLLBACK;
