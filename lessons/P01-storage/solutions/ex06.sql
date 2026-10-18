-- db: lab
-- mode: check
-- reset
-- Giải thích: thứ tự cũ b(8) a(1)+7 pad … tốn byte đệm: 24 header + 1+7 +8 +1+7 +8 +1+1 pad +2 = 60 → 64 B (căn 8). Thứ tự b, d, f, a, c, e:
--   8+8+2+1+1+1 = 21 → 24+21 = 45 → 48 B. Cộng line pointer 4 B: 68 → 52 B/dòng, tiết kiệm khoảng 24%.
-- Bẫy: giữ nguyên thứ tự; "tiết kiệm" bằng cách đổi bigint → int/smallint (làm mất dữ liệu lớn).
CREATE TABLE p01.pad_good (b bigint, d bigint, f smallint, a boolean, c boolean, e boolean);
