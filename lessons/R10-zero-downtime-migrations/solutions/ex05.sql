-- db: lab
-- mode: manual
-- Demo: đổi t.id từ integer sang bigint theo expand/contract trên bảng 100 000 dòng (schema r10e), mỗi bước là một lệnh ngắn.
-- Không có đoạn nào giữ khóa mạnh lâu: bước duy nhất cần ACCESS EXCLUSIVE là bước hoán đổi (milli-giây), bọc bởi lock_timeout.
DROP SCHEMA IF EXISTS r10e CASCADE;
CREATE SCHEMA r10e;
CREATE TABLE r10e.t (id integer PRIMARY KEY, payload text NOT NULL);
INSERT INTO r10e.t SELECT i, 'dòng ' || i FROM generate_series(1, 100000) i;

-- Bước 1 (expand): thêm cột mới bigint (nullable, không default → tức thì) và trigger đồng bộ cho dòng mới/sửa
ALTER TABLE r10e.t ADD COLUMN id_new bigint;
CREATE FUNCTION r10e.sync_id() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN NEW.id_new := NEW.id; RETURN NEW; END $$;
CREATE TRIGGER t_sync_id BEFORE INSERT OR UPDATE OF id ON r10e.t FOR EACH ROW EXECUTE FUNCTION r10e.sync_id();

-- Bước 2 (backfill theo lô, mỗi lô một transaction; DO block chạy ở chế độ autocommit nên COMMIT được)
DO $$
DECLARE n int;
BEGIN
  LOOP
    UPDATE r10e.t SET id_new = id WHERE id IN (SELECT id FROM r10e.t WHERE id_new IS NULL ORDER BY id LIMIT 10000);
    GET DIAGNOSTICS n = ROW_COUNT;
    EXIT WHEN n = 0;
    COMMIT;
  END LOOP;
END $$;

-- Bước 3: unique index trên cột mới (không chặn ghi) và NOT NULL bằng CHECK NOT VALID → VALIDATE (R10 ex02)
CREATE UNIQUE INDEX CONCURRENTLY t_id_new_uq ON r10e.t (id_new);
ALTER TABLE r10e.t ADD CONSTRAINT id_new_nn CHECK (id_new IS NOT NULL) NOT VALID;
ALTER TABLE r10e.t VALIDATE CONSTRAINT id_new_nn;

-- Bước 4 (contract): hoán đổi trong MỘT transaction ngắn, có lock_timeout để không xếp hàng chặn mọi query
BEGIN;
SET LOCAL lock_timeout = '2s';
ALTER TABLE r10e.t DROP CONSTRAINT t_pkey;
ALTER TABLE r10e.t ADD CONSTRAINT t_pkey PRIMARY KEY USING INDEX t_id_new_uq;
ALTER TABLE r10e.t RENAME COLUMN id TO id_old;
ALTER TABLE r10e.t RENAME COLUMN id_new TO id;
DROP TRIGGER t_sync_id ON r10e.t;
ALTER TABLE r10e.t DROP CONSTRAINT id_new_nn;
COMMIT;

-- Bước 5 (dọn, sau khi mọi phiên bản code đã dùng cột mới): DROP COLUMN id_old (tức thì, không viết lại bảng)
ALTER TABLE r10e.t DROP COLUMN id_old;
SELECT a.attname, format_type(a.atttypid, a.atttypmod) AS type, a.attnotnull
FROM pg_attribute a WHERE a.attrelid = 'r10e.t'::regclass AND a.attnum > 0 AND NOT a.attisdropped ORDER BY a.attnum;
SELECT count(*) AS n_rows, min(id), max(id) FROM r10e.t;
DROP SCHEMA r10e CASCADE;
