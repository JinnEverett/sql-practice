-- db: lab
-- mode: state
-- Giải thích: retention (giữ dữ liệu N tháng) trên bảng partition = bỏ cả partition cũ, không DELETE từng dòng. DETACH PARTITION tách partition ra khỏi bảng cha (thành bảng thường, gần như tức thì,
--   chỉ khóa catalog), DROP TABLE xóa bảng đó: không sinh dead tuple, không cần VACUUM, WAL rất nhỏ, trả lại dung lượng ngay cho hệ điều hành. DELETE cùng lượng dữ liệu phải ghi dead tuple cho từng dòng.
--   Trên production có truy vấn chạy lâu: dùng DETACH PARTITION … CONCURRENTLY (Postgres 14+, không chạy trong transaction block) để không chờ ACCESS EXCLUSIVE; muốn lưu trữ thì để partition đã tách lại làm bảng archive thay vì DROP.
-- Bẫy: DELETE FROM events_p WHERE ts < … (đúng dữ liệu nhưng partition vẫn còn, bảng phình, cần VACUUM); chỉ DETACH mà quên DROP → bảng cũ vẫn chiếm chỗ.
ALTER TABLE r12.events_p DETACH PARTITION r12.events_p_2026_01;
DROP TABLE r12.events_p_2026_01;
ALTER TABLE r12.events_p DETACH PARTITION r12.events_p_2026_02;
DROP TABLE r12.events_p_2026_02;
ALTER TABLE r12.events_p DETACH PARTITION r12.events_p_2026_03;
DROP TABLE r12.events_p_2026_03;
