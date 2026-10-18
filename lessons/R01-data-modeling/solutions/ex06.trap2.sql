-- sai: chỉ chặn trùng số, không giới hạn số chính
ALTER TABLE r01.user_phones ADD CONSTRAINT user_phones_uq UNIQUE (user_id, phone);
