-- db: lab
-- mode: check
-- reset
-- Giải thích: planner không biết các dòng `gen < 5000` đều là dòng CŨ nhất. Nó ước lượng 5% dòng khớp rải đều theo ts nên đọc ngược t_m_ts_idx sẽ gặp 20 dòng khớp sau ~400 dòng; thực tế phải đi qua 950 001 dòng mới tới vùng khớp
--   (13 396 buffers ở 1M, 133 915 ở 10M, tuyến tính theo N). Thống kê một cột không mô tả được tương quan giữa gen và ts (extended statistics của P04 cũng không thấy vị trí).
--   Sửa: index trên gen để lọc nhanh 50 000 dòng rồi sắp xếp trong bộ nhớ, và BUỘC thứ tự đó bằng CTE MATERIALIZED (CTE thường được inline từ Postgres 12 nên không đủ). Chỉ thêm index (gen, ts) mà giữ query: planner vẫn chọn ts index.
-- Bẫy: chỉ thêm index (gen, ts DESC); CTE không MATERIALIZED; viết lại mà không có index trên gen (Seq Scan 1M dòng ~ 11 000 page).
CREATE INDEX ON p10.t_m (gen);
-- query
WITH f AS MATERIALIZED (SELECT id, ts FROM p10.t_m WHERE gen < 5000)
SELECT id, ts FROM f ORDER BY ts DESC LIMIT 20;
