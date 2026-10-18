-- sai: SET NOT NULL trực tiếp — quét cả bảng dưới ACCESS EXCLUSIVE
ALTER TABLE r10.orders ALTER COLUMN customer_ref SET NOT NULL;
