-- db: shop_s
-- ordered
-- expect-rows: 5
-- Giải thích: ctid là kiểu tid in ra "(page,slot)"; cast qua text rồi point để lấy hai thành phần. Slot đánh số từ 1.
--   Các dòng nạp liền nhau nằm liền nhau (0,1), (0,2)… Sau UPDATE ctid sẽ đổi (P07).
-- Bẫy: tưởng slot từ 0; tưởng ctid là khóa ổn định.
SELECT id, (ctid::text::point)[0]::int AS page_no, (ctid::text::point)[1]::int AS slot_no
FROM orders WHERE id <= 5 ORDER BY id;
