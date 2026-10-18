-- db: lab
-- mode: manual
-- Demo: sau trigger của ex06, EXPLAIN ANALYZE UPDATE hiện dòng "Trigger …: calls=N" (mỗi dòng đổi giá một lần gọi).
BEGIN;
CREATE FUNCTION pg_temp.demo_log() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RETURN NULL; END $$;
CREATE TEMP TABLE demo_p AS SELECT i AS id, 100::numeric AS price FROM generate_series(1, 1000) i;
CREATE TRIGGER t AFTER UPDATE OF price ON demo_p FOR EACH ROW WHEN (OLD.price IS DISTINCT FROM NEW.price) EXECUTE FUNCTION pg_temp.demo_log();
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) UPDATE demo_p SET price = price + 1;
ROLLBACK;
