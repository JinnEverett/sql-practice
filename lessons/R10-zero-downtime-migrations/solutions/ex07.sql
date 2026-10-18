-- db: lab
-- mode: check
-- reset
-- Giải thích: `ADD FOREIGN KEY` thường kiểm tra mọi dòng của bảng con dưới khóa SHARE ROW EXCLUSIVE trên CẢ HAI bảng: chặn ghi trong lúc quét.
--   Trình tự an toàn: (1) ADD CONSTRAINT … FOREIGN KEY … NOT VALID — chỉ cần khóa ngắn, từ giờ dòng mới/sửa phải thỏa FK;
--   (2) VALIDATE CONSTRAINT — quét dữ liệu cũ nhưng chỉ cần khóa SHARE UPDATE EXCLUSIVE trên bảng con (và ROW SHARE trên bảng cha), ghi vẫn chạy.
--   Nhớ rằng Postgres không tự tạo index cho cột FK (R01): thêm CREATE INDEX CONCURRENTLY child(parent_id) để xóa/sửa ở bảng cha không Seq Scan bảng con.
-- Bẫy: ADD FOREIGN KEY một phát (quét dưới khóa mạnh); quên VALIDATE nên FK mãi ở trạng thái NOT VALID (không đảm bảo dữ liệu cũ, planner không dùng cho tối ưu join).
ALTER TABLE r10.child ADD CONSTRAINT child_parent_fk FOREIGN KEY (parent_id) REFERENCES r10.parent (id) NOT VALID;
ALTER TABLE r10.child VALIDATE CONSTRAINT child_parent_fk;
