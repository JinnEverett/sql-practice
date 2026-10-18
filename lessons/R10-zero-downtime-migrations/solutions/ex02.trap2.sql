-- sai: CHECK không NOT VALID (quét dưới khóa mạnh) rồi SET NOT NULL, bỏ quên CHECK thừa
ALTER TABLE r10.orders ADD CONSTRAINT customer_ref_not_null CHECK (customer_ref IS NOT NULL);
ALTER TABLE r10.orders ALTER COLUMN customer_ref SET NOT NULL;
