-- db: lab
-- mode: state
-- Giải thích: chuyển danh mục 16 (Âm thanh) sang cha mới 3 (Nhà cửa & Đời sống). Với ltree, path của MỌI hậu duệ chứa tiền tố cũ '2.16' phải đổi thành '3.16':
--   path_mới = path_cha_mới || subpath(path, nlevel(path_cũ_của_16) - 1) giữ nguyên phần từ nút 16 trở xuống. Toán tử <@ ("là hậu duệ của", dùng GiST) chọn cả cây con.
--   Phải làm trong cùng một transaction với việc đổi parent_id để hai biểu diễn không lệch nhau.
-- Bẫy: chỉ sửa path của nút 16 (hậu duệ 34, 35 vẫn trỏ '2.16.…'); sửa parent_id nhưng quên path; dùng replace() trên text cho path dễ trúng nhãn trùng ('2.16' cũng nằm trong '12.162…').
UPDATE r06.cat_lt
SET path = (SELECT path FROM r06.cat_lt WHERE id = 3) || subpath(path, nlevel((SELECT path FROM r06.cat_lt WHERE id = 16)) - 1)
WHERE path <@ (SELECT path FROM r06.cat_lt WHERE id = 16);
UPDATE r06.cat_lt SET parent_id = 3 WHERE id = 16;
