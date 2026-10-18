-- sai: default volatile → Postgres viết lại toàn bộ bảng
ALTER TABLE r10.orders ADD COLUMN priority integer NOT NULL DEFAULT (random() * 0)::int;
