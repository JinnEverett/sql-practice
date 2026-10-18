-- db: lab
-- mode: manual
-- Demo (không cần số đo): hai chính sách RLS cho thấy khác biệt trong plan. Chạy trong transaction rồi rollback.
BEGIN;
CREATE TEMP TABLE demo_o (id int PRIMARY KEY, user_id int, status text);
INSERT INTO demo_o SELECT i, i % 100, 'paid' FROM generate_series(1, 1000) i;
CREATE INDEX ON demo_o (user_id);
ANALYZE demo_o;
SELECT count(*) FROM demo_o WHERE user_id = 5;
ROLLBACK;
