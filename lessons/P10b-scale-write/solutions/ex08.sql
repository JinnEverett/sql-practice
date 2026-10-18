-- db: lab
-- mode: check
-- reset
-- Giải thích: `UPDATE big SET amount_big = amount` một câu = một transaction 100 000 dòng: giữ khóa dòng lâu, sinh WAL/phiên bản chết một khối (bảng ×2 rồi bloat; đo ở ex06: 10M dòng cần 9.4 s cho 1M và nhân đôi file),
--   và nếu lỗi giữa chừng thì làm lại từ đầu. Chia lô 10 000 dòng, COMMIT từng lô: mỗi lô nhanh, khóa dòng ngắn, VACUUM chen vào được, tiến độ bền (mất điện chỉ mất lô hiện tại). DO block cho phép COMMIT bên trong khi chạy ở chế độ autocommit.
--   Trong thực tế còn: ADD COLUMN không default (tức thì), backfill theo khoảng khóa (không OFFSET), rồi thêm NOT NULL/swap bằng NOT VALID + VALIDATE (ex07).
-- Bẫy: UPDATE một phát; vòng lặp COMMIT từng dòng (100 000 xid); lô quá lớn.
ALTER TABLE p10b.big ADD COLUMN amount_big bigint;
DO $$
DECLARE lo int := 0;
BEGIN
  WHILE lo < 100000 LOOP
    UPDATE p10b.big SET amount_big = amount WHERE id > lo AND id <= lo + 10000;
    COMMIT;
    lo := lo + 10000;
  END LOOP;
END $$;
