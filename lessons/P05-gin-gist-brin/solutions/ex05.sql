-- db: lab
-- mode: check
-- reset
-- Giải thích: `&&` (chồng lấn) không thuộc quan hệ thứ tự của B-tree; GiST lưu hộp bao (khoảng bao) của từng nhánh và duyệt các nhánh chồng lên khoảng cần tìm:
--   4 buffers thay vì 2 206. B-tree trên cột range tạo được (range có thứ tự) nhưng planner không dùng cho `&&` → vẫn Seq Scan.
-- Bẫy: B-tree trên during; B-tree trên lower(during) (không khớp biểu thức).
CREATE INDEX ON p05.booking USING gist (during);
