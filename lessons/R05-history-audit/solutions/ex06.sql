-- db: lab
-- mode: state
-- Giải thích: đổi giá trong SCD2 = ĐÓNG dòng hiện tại (valid_to = now()) và MỞ dòng mới (valid_from = now(), valid_to NULL), phải nguyên tử.
--   Viết bằng một câu: CTE data-modifying `closed` UPDATE dòng đang hiệu lực và RETURNING product_id; INSERT lấy từ `closed`.
--   Dùng cùng một now() cho cả hai vế (trong một câu lệnh now() là hằng) nên không có khoảng trống hay chồng lấn.
--   Nếu sản phẩm chưa có dòng nào (sản phẩm mới) thì `closed` rỗng và INSERT không chạy: sản phẩm mới cần nhánh INSERT riêng.
-- Bẫy: INSERT trước UPDATE (hai dòng cùng "hiện tại"); đóng bằng valid_to = valid_from của dòng mới tính bằng clock_timestamp() khác nhau ở hai câu → lệch mili giây.
WITH closed AS (
  UPDATE r05.price_history SET valid_to = now()
  WHERE product_id = 1 AND valid_to IS NULL
  RETURNING product_id
)
INSERT INTO r05.price_history (product_id, price, valid_from, valid_to)
SELECT product_id, 160, now(), NULL FROM closed;
