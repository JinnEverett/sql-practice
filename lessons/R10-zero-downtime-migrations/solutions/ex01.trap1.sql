-- sai: cách cũ — thêm cột, UPDATE toàn bảng, rồi SET NOT NULL (ghi lại mọi dòng)
ALTER TABLE r10.orders ADD COLUMN priority integer;
UPDATE r10.orders SET priority = 0;
ALTER TABLE r10.orders ALTER COLUMN priority SET NOT NULL;
ALTER TABLE r10.orders ALTER COLUMN priority SET DEFAULT 0;
