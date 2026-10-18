-- db: lab
-- reset
-- ordered
-- expect-rows: 2
-- Giải thích: nested set gán cho mỗi nút khoảng [lft, rgt] bao trọn khoảng của hậu duệ. Tổ tiên của n = các nút a có a.lft < n.lft AND a.rgt > n.rgt (không cần đệ quy).
--   Số hậu duệ của a = (a.rgt - a.lft - 1) / 2, tính thẳng từ hai số, không cần đếm.
--   Sắp xếp theo lft cho thứ tự từ gốc xuống.
-- Bẫy: dùng >= / <= làm cả chính nút lọt vào tập tổ tiên; số hậu duệ = (rgt - lft) / 2 sai một (đã tính cả chính nút); quên rằng chèn/di chuyển nút phải dịch lft/rgt của mọi nút phía sau (O(N), xem ex09).
SELECT a.id, a.name, (a.rgt - a.lft - 1) / 2 AS n_descendants
FROM r06.cat_ns a
JOIN r06.cat_ns n ON n.id = 34 AND a.lft < n.lft AND a.rgt > n.rgt
ORDER BY a.lft;
