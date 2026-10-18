-- db: shop_m
-- mode: manual
-- Demo: dung lượng của 4 loại index trên events (tạo trong transaction rồi ROLLBACK). Bật `\timing` để đo thời gian build.
BEGIN;
CREATE INDEX i_bt  ON events (created_at);
CREATE INDEX i_br  ON events USING brin (created_at);
CREATE INDEX i_gp  ON events USING gin (properties jsonb_path_ops);
CREATE INDEX i_go  ON events USING gin (properties);
SELECT relname, pg_relation_size(oid) / 1024 AS kb FROM pg_class WHERE relname IN ('i_bt', 'i_br', 'i_gp', 'i_go') ORDER BY relname;
ROLLBACK;
