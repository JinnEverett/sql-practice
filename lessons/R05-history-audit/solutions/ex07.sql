-- db: lab
-- mode: check
-- reset
-- Giải thích: "không có hai khoảng giá chồng nhau cho cùng sản phẩm" là bài toán của EXCLUSION constraint:
--   EXCLUDE USING gist (product_id WITH =, tstzrange(valid_from, valid_to) WITH &&). Cần extension btree_gist để dùng `=` trong GiST.
--   tstzrange(a, NULL) là khoảng mở phía trên (đang hiệu lực), mặc định nửa mở [a, b) nên hai khoảng liền kề [1/1,2/1) và [2/1,3/1) KHÔNG chồng nhau.
--   Dữ liệu cũ đang chồng (sản phẩm 1) phải sửa trước: quy tắc "bản bắt đầu muộn hơn thắng" → cắt valid_to của bản trước về valid_from của bản sau.
--   lead(valid_from) OVER (PARTITION BY product_id ORDER BY valid_from) cho valid_from của dòng kế tiếp; chỉ cắt khi nó nhỏ hơn valid_to hiện tại.
-- Bẫy: thêm constraint trước khi sửa dữ liệu → lỗi 23P01; dùng `&&` với cặp đóng hai đầu '[]' → khoảng liền kề bị coi là chồng; quên NULL (khoảng mở).
UPDATE r05.price_history_bad p
SET valid_to = n.next_from
FROM (SELECT product_id, valid_from, lead(valid_from) OVER (PARTITION BY product_id ORDER BY valid_from) AS next_from
      FROM r05.price_history_bad) n
WHERE p.product_id = n.product_id AND p.valid_from = n.valid_from
  AND n.next_from < coalesce(p.valid_to, 'infinity');

ALTER TABLE r05.price_history_bad
  ADD CONSTRAINT price_no_overlap EXCLUDE USING gist (product_id WITH =, tstzrange(valid_from, valid_to) WITH &&);
