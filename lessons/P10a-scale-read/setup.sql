-- P10a · bảng thí nghiệm quy mô. Chạy trên DB `lab`. Chạy lại được nhiều lần (~10 giây).
-- Cùng schema ở 2 quy mô: p10.t_s (10 000 dòng) và p10.t_m (1 000 000 dòng); t_l (10M) có script riêng: setup-large.sql.
--   id : tăng dần (PK)               u   : đều trong [0, 1 000 000), KHÔNG tương quan với vị trí vật lý
--   ts : tăng theo id (tương quan 1) grp : 1 000 nhóm đều nhau
--   amount : 0..99 999               gen : id / 10, tương quan hoàn toàn với ts nhưng KHÔNG có index (ex08)
--   pad : đệm ~30 byte
DROP SCHEMA IF EXISTS p10 CASCADE;
CREATE SCHEMA p10;
CREATE FUNCTION p10.build(tbl text, n int) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE format($f$
    CREATE TABLE p10.%1$I (
      id int PRIMARY KEY, u int NOT NULL, ts timestamptz NOT NULL, grp int NOT NULL, amount int NOT NULL, gen int NOT NULL, pad text NOT NULL)
    WITH (autovacuum_enabled = false)$f$, tbl);
  EXECUTE format($f$
    INSERT INTO p10.%1$I
    SELECT i, (hashint4(i) & 2147483647) %% 1000000,
           timestamptz '2025-01-01 00:00+00' + i * interval '30 seconds',
           (hashint4(i + 7) & 2147483647) %% 1000,
           (hashint4(i + 13) & 2147483647) %% 100000,
           i / 10,
           left(md5(i::text), 30)
    FROM generate_series(1, %2$s) i$f$, tbl, n);
  EXECUTE format('CREATE INDEX %1$I ON p10.%2$I (u)', tbl || '_u_idx', tbl);
  EXECUTE format('CREATE INDEX %1$I ON p10.%2$I (ts)', tbl || '_ts_idx', tbl);
END $$;
SELECT p10.build('t_s', 10000);
SELECT p10.build('t_m', 1000000);
VACUUM ANALYZE p10.t_s;
VACUUM ANALYZE p10.t_m;

-- bảng 200 000 dòng để join (ex03): khóa id 1..200 000, dò theo t_m.amount + 1
CREATE TABLE p10.mid (id int PRIMARY KEY, label text NOT NULL, pad text NOT NULL);
INSERT INTO p10.mid SELECT g, 'm' || g, repeat('y', 40) FROM generate_series(1, 200000) g;
VACUUM ANALYZE p10.mid;
