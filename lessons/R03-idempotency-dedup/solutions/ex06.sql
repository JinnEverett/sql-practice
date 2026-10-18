-- db: lab
-- mode: state
-- show-output
-- Giải thích: đồng bộ giá phải (1) dedupe lô trước (A1 xuất hiện hai lần; DO UPDATE gặp cùng khóa hai lần trong một lệnh sẽ báo lỗi
--   "cannot affect row a second time"), (2) chỉ ghi khi bản mới THỰC SỰ mới hơn VÀ giá khác (WHERE trong DO UPDATE), vì mỗi UPDATE tạo một
--   phiên bản dòng mới + WAL dù giá trị không đổi (bloat, P07), (3) RETURNING chỉ trả các dòng thực sự được chèn/sửa.
-- Bẫy: không WHERE → A2 (giá không đổi) bị ghi lại, A3 (bản cũ hơn) ghi đè bằng giá cũ; không dedupe → lỗi 21000.
INSERT INTO r03.price_feed AS f (sku, price, src_updated_at)
SELECT DISTINCT ON (sku) sku, price, src_updated_at
FROM r03.price_batch
ORDER BY sku, src_updated_at DESC
ON CONFLICT (sku) DO UPDATE
  SET price = EXCLUDED.price, src_updated_at = EXCLUDED.src_updated_at
  WHERE EXCLUDED.src_updated_at > f.src_updated_at AND EXCLUDED.price IS DISTINCT FROM f.price
RETURNING f.sku;
