# I03 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Top 3 mỗi danh mục
<details><summary>H1</summary><code>row_number()</code> với <code>PARTITION BY category_id</code>. Window không lọc được trong WHERE.</details>
<details><summary>H2</summary><code>SELECT … FROM (SELECT …, row_number() OVER (PARTITION BY … ORDER BY …) AS rn FROM products WHERE is_active) t WHERE rn &lt;= 3</code></details>
<details><summary>H3</summary><code>ORDER BY price DESC, id</code> trong OVER; cuối câu <code>ORDER BY category_id, rn</code>.</details>

## ex02 · rank, dense_rank, row_number
<details><summary>H1</summary>GROUP BY khách trước, window đặt trên <code>count(*)</code> ngay cùng tầng.</details>
<details><summary>H2</summary><code>rank() OVER (ORDER BY count(*) DESC)</code>, tương tự cho dense_rank; row_number thêm <code>o.user_id</code> vào ORDER BY.</details>
<details><summary>H3</summary>Bọc ngoài và lọc <code>WHERE drnk &lt;= 5 ORDER BY rn</code>.</details>

## ex03 · Chia 4 nhóm
<details><summary>H1</summary><code>ntile(4) OVER (ORDER BY tổng chi tiêu DESC, user_id)</code>.</details>
<details><summary>H2</summary>Tầng trong: GROUP BY user_id, tính <code>sum(total_amount)</code> và ntile cùng lúc. Tầng ngoài: GROUP BY quartile.</details>
<details><summary>H3</summary><code>ntile(4) OVER (ORDER BY sum(total_amount) DESC, user_id) AS quartile</code>; ngoài: <code>count(*), min(total_spent), max(total_spent)</code>.</details>

## ex04 · Top 3 khách mỗi thành phố
<details><summary>H1</summary>Ba bước: tổng chi tiêu theo khách (kèm city chuẩn hóa) → xếp hạng trong mỗi thành phố → lọc.</details>
<details><summary>H2</summary>City chuẩn hóa bằng CASE như F10 ex02. <code>PARTITION BY city_norm</code>.</details>
<details><summary>H3</summary><code>row_number() OVER (PARTITION BY city_norm ORDER BY total_spent DESC, user_id)</code>; lọc <code>u.country = 'VN' AND u.city IS NOT NULL</code>.</details>

## ex05 · Tài khoản trùng email
<details><summary>H1</summary>Đánh số trong từng nhóm email chuẩn hóa. rn = 1 là bản giữ.</details>
<details><summary>H2</summary><code>row_number() OVER (PARTITION BY lower(trim(email)) ORDER BY created_at, id)</code>. Lấy keep_id bằng cách JOIN tập đã đánh số với chính nó tại rn = 1.</details>
<details><summary>H3</summary><code>FROM n d JOIN n k ON k.email_norm = d.email_norm AND k.rn = 1 WHERE d.rn &gt; 1</code>.</details>

## ex06 · Đơn đầu và đơn mua lại
<details><summary>H1</summary>WHERE chạy trước window. Lọc năm 2026 ở đâu?</details>
<details><summary>H2</summary>Tầng trong: đánh số mọi đơn không cancelled theo khách (<code>PARTITION BY user_id ORDER BY created_at, id</code>), <b>không</b> lọc thời gian. Tầng ngoài: lọc 2026 rồi gom theo tháng.</details>
<details><summary>H3</summary><code>sum(total_amount) FILTER (WHERE nth = 1)</code> và <code>FILTER (WHERE nth &gt; 1)</code>.</details>

## ex07 · Bán chạy nhất mỗi tháng
<details><summary>H1</summary>Đồng hạng nhất phải giữ tất cả: hàm nào?</details>
<details><summary>H2</summary>Gom <code>sum(quantity)</code> theo (tháng VN, product_id), rồi <code>rank() OVER (PARTITION BY m ORDER BY units DESC)</code>.</details>
<details><summary>H3</summary>Lọc <code>rnk = 1</code>, JOIN products lấy tên, <code>to_char(m, 'YYYY-MM')</code>.</details>

## ex08 · Top 1%
<details><summary>H1</summary><code>ntile(100)</code> theo chi tiêu giảm dần; phần 1 là top 1%.</details>
<details><summary>H2</summary>CASE gán nhóm từ số ntile, GROUP BY nhóm. Tổng doanh thu toàn bộ: <code>sum(sum(total_spent)) OVER ()</code>.</details>
<details><summary>H3</summary><code>round(100.0 * sum(total_spent) / sum(sum(total_spent)) OVER (), 1)</code>; sắp <code>ORDER BY min(pct_bucket)</code>.</details>

## ex09 · Thay đổi thứ hạng
<details><summary>H1</summary>Xếp hạng tháng 8 phải tính trên MỌI sản phẩm tháng 8, rồi mới ghép với top 10 tháng 9.</details>
<details><summary>H2</summary>Một CTE doanh thu theo (tháng, sản phẩm) cho cả 2 tháng; <code>rank() OVER (PARTITION BY m ORDER BY revenue DESC)</code>; self join tháng 9 với tháng 8.</details>
<details><summary>H3</summary><code>LEFT JOIN ranked a ON a.product_id = s.product_id AND a.m = '2026-08-01'</code>; <code>WHERE s.m = '2026-09-01' AND s.rnk &lt;= 10</code>.</details>
