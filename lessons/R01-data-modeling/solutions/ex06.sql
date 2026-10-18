-- db: lab
-- mode: check
-- reset
-- Giải thích: "mỗi user tối đa một số chính" = unique index PARTIAL: UNIQUE (user_id) WHERE is_primary. Dòng is_primary = false không vào index
--   nên không bị giới hạn. Cặp (user_id, phone) cũng phải duy nhất để không lưu cùng số hai lần.
-- Bẫy: UNIQUE (user_id, is_primary) chặn luôn cả việc có 2 số phụ (false, false); UNIQUE (user_id) chặn user có 2 số.
CREATE UNIQUE INDEX user_phones_primary_uq ON r01.user_phones (user_id) WHERE is_primary;
ALTER TABLE r01.user_phones ADD CONSTRAINT user_phones_uq UNIQUE (user_id, phone);
