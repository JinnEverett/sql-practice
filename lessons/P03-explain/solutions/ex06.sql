-- db: lab
-- reset
-- expect-rows: 1
-- Giải thích: planner nhân selectivity như hai biến độc lập: 400 000 × 1% × 0.1% = 4. Thực tế pending là mọi id chia hết cho 100 và amount = (id mod 1000)·1000,
--   nên amount = 0 xảy ra trong 1/10 số đơn pending → 400 dòng (100×). Với một Seq Scan thì sai số này vô hại, nhưng nếu ghép join thì planner
--   tin node này chỉ ra 4 dòng và chọn Nested Loop, thứ sẽ lặp 400 lần chứ không phải 4. Cách sửa: extended statistics (P04).
-- Bẫy: bỏ qua cặp rows/actual rows; kết luận "cost 9334 thấp thì ổn".
SELECT 4 AS est_rows,
       (SELECT count(*) FROM p03.o WHERE status = 'pending' AND amount = 0) AS actual_rows,
       100 AS error_factor,
       round(count(*) * (count(*) FILTER (WHERE status = 'pending'))::numeric / count(*)
                      * (count(*) FILTER (WHERE amount = 0))::numeric / count(*))::int AS est_independent
FROM p03.o;
