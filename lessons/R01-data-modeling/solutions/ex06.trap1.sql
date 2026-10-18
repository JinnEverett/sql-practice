-- sai: (user_id, is_primary) chặn luôn việc có hai số phụ
ALTER TABLE r01.user_phones ADD CONSTRAINT bad_uq UNIQUE (user_id, is_primary);
ALTER TABLE r01.user_phones ADD CONSTRAINT user_phones_uq UNIQUE (user_id, phone);
