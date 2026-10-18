-- db: lab
-- mode: check
-- reset
-- Giải thích: mỗi transaction ghi dùng một xid (32 bit, vòng quanh sau ~4 tỉ; P07). Nạp 5 000 dòng bằng 5 000 câu autocommit hoặc vòng lặp COMMIT từng dòng tiêu 5 000 xid, 5 000 lần fsync WAL và kéo age(datfrozenxid) lên nhanh;
--   một INSERT … SELECT (hoặc COPY, hoặc BEGIN … COMMIT bọc nhiều lệnh) dùng 1 xid. Đo ở README: 100 000 dòng từng câu 39–42 giây, theo lô 0.7–0.9 giây, INSERT … SELECT/COPY 0.22–0.27 giây.
-- Bẫy: sinh câu INSERT từng dòng rồi \gexec; DO … LOOP … COMMIT trong vòng lặp; dùng ORM insert từng entity.
INSERT INTO p10b.dst SELECT id, v, pad FROM p10b.src;
