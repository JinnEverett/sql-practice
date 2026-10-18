-- db: lab
-- mode: manual
-- Demo (N = 100 000, vài giây): chi phí của audit trigger khi UPDATE hàng loạt. Dọn sạch cuối script.
-- Đổi N thành 1 000 000 để tái hiện số đo trong ex09.md.
DROP SCHEMA IF EXISTS r05s CASCADE;
CREATE SCHEMA r05s;
CREATE TABLE r05s.p (id int PRIMARY KEY, name text NOT NULL, price numeric(12,2) NOT NULL, stock int NOT NULL, updated_at timestamptz NOT NULL DEFAULT now());
INSERT INTO r05s.p SELECT i, 'San pham ' || i, 1000 + i % 500, i % 50 FROM generate_series(1, 100000) i;
CREATE TABLE r05s.a1 (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, op text NOT NULL, row_id int NOT NULL, changed_at timestamptz NOT NULL DEFAULT now(), changed_by text NOT NULL DEFAULT current_user, old_row jsonb, new_row jsonb);
CREATE FUNCTION r05s.f1() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN INSERT INTO r05s.a1 (op, row_id, old_row, new_row) VALUES (TG_OP, NEW.id, to_jsonb(OLD), to_jsonb(NEW)); RETURN NULL; END $$;
VACUUM ANALYZE r05s.p;
\echo '--- không trigger'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) UPDATE r05s.p SET price = price + 1;
CREATE TRIGGER t1 AFTER UPDATE ON r05s.p FOR EACH ROW EXECUTE FUNCTION r05s.f1();
\echo '--- có audit trigger ghi cả hàng (old_row + new_row)'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) UPDATE r05s.p SET price = price + 1;
SELECT pg_size_pretty(pg_total_relation_size('r05s.a1')) AS audit_table_size;
DROP SCHEMA r05s CASCADE;
