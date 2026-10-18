-- db: lab
-- reset
-- ordered
-- expect-rows: 6
-- Giải thích: mỗi UPDATE tạo một phiên bản mới và đặt xmax lên phiên bản cũ; DELETE chỉ đặt xmax. Dòng id=1: lp1 → lp4 → lp5 → lp6 (t_ctid trỏ phiên bản kế); chỉ lp6 (t_ctid trỏ về chính nó, không xmax) còn sống.
--   lp4–6 có HEAP_ONLY vì UPDATE n (không index) là HOT: phiên bản mới nằm cùng page, không có entry index riêng. lp1 có HOT_UPDATED (đã sinh HOT con).
--   lp3 là id=3 đã DELETE (xmax đã đặt, ctid trỏ chính nó). Tổng 6 tuple cho 2 dòng sống.
-- Bẫy: đếm dòng bằng count(*) trên bảng chỉ thấy 2; nhầm lp3 còn sống vì t_ctid trỏ chính nó (phải xét xmax).
SELECT lp, t_ctid, t_xmax <> 0 AS has_xmax,
       (t_infomask2 & 16384) <> 0 AS hot_updated,
       (t_infomask2 & 32768) <> 0 AS heap_only
FROM heap_page_items(get_raw_page('p07.ver', 0))
ORDER BY lp;
