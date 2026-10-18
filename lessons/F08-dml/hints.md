# F08 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án đầy đủ nằm ở `solutions/exNN.sql` (đừng mở trước khi nộp).

## ex01 · Nhập hai sản phẩm mới
<details><summary>H1</summary>Một câu INSERT có thể chèn nhiều dòng. Để bảng tự sinh <code>id</code>, đừng nhắc tới cột đó.</details>
<details><summary>H2</summary><code>INSERT INTO f08.products (cột…) VALUES (…), (…) RETURNING …;</code></details>
<details><summary>H3</summary>Liệt kê đúng 4 cột <code>(sku, name, price, stock)</code>, hai bộ giá trị, rồi <code>RETURNING id, sku</code>.</details>

## ex02 · Nạp sản phẩm mới từ feed
<details><summary>H1</summary>Hai việc: chọn bản mới nhất mỗi sku, và loại các sku đã có (anti join).</details>
<details><summary>H2</summary><code>INSERT INTO … (cột) SELECT DISTINCT ON (sku) … FROM stock_feed f WHERE NOT EXISTS (…) ORDER BY …;</code></details>
<details><summary>H3</summary><code>ORDER BY f.sku, f.received_at DESC</code> để DISTINCT ON giữ bản mới nhất; <code>NOT EXISTS (SELECT 1 FROM f08.products p WHERE p.sku = f.sku)</code>.</details>

## ex03 · Tăng giá 10% cho hàng rẻ
<details><summary>H1</summary>Một câu UPDATE, WHERE có 2 vế. Làm tròn bằng <code>round(x, 0)</code>.</details>
<details><summary>H2</summary><code>UPDATE … SET price = …, updated_at = … WHERE … AND …;</code></details>
<details><summary>H3</summary><code>SET price = round(price * 1.10, 0), updated_at = now() WHERE is_active AND price &lt; 500000</code>.</details>

## ex04 · Cập nhật tồn kho và giá theo feed
<details><summary>H1</summary><code>UPDATE … FROM</code>. Feed có sku lặp, khử trùng trước khi JOIN, nếu không Postgres chọn bừa một dòng.</details>
<details><summary>H2</summary><code>UPDATE f08.products p SET … FROM (SELECT DISTINCT ON (sku) … ORDER BY sku, received_at DESC) f WHERE f.sku = p.sku;</code></details>
<details><summary>H3</summary>Giá: <code>price = COALESCE(f.price, p.price)</code>. Nhớ <code>updated_at = now()</code>.</details>

## ex05 · Dọn giỏ hàng
<details><summary>H1</summary><code>DELETE … USING</code> để nối sang <code>products</code>.</details>
<details><summary>H2</summary><code>DELETE FROM f08.cart_items c USING f08.products p WHERE p.id = c.product_id AND (…);</code></details>
<details><summary>H3</summary>Trong ngoặc: <code>NOT p.is_active OR p.stock = 0</code>. Thiếu ngoặc là xóa nhầm.</details>

## ex06 · Xóa email đăng ký trùng
<details><summary>H1</summary>Một dòng bị xóa nếu tồn tại một dòng khác cùng email chuẩn hóa mà "đứng trước" nó.</details>
<details><summary>H2</summary>Self join: <code>DELETE FROM f08.subscribers s USING f08.subscribers k WHERE &lt;cùng email chuẩn hóa&gt; AND &lt;k đứng trước s&gt;;</code></details>
<details><summary>H3</summary>"Đứng trước" = <code>(k.created_at, k.id) &lt; (s.created_at, s.id)</code>. Email chuẩn hóa: <code>lower(trim(email))</code>.</details>

## ex07 · Cộng dồn doanh thu theo ngày
<details><summary>H1</summary>Upsert: <code>INSERT … ON CONFLICT (day) DO UPDATE</code>. Gom theo ngày giờ VN trước khi chèn.</details>
<details><summary>H2</summary><code>INSERT INTO daily_stats (day, orders, revenue) SELECT &lt;ngày VN&gt;, count(*), sum(total) FROM new_orders GROUP BY 1 ON CONFLICT (day) DO UPDATE SET …;</code></details>
<details><summary>H3</summary>Ngày VN: <code>(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date</code>. Cộng dồn: <code>orders = f08.daily_stats.orders + EXCLUDED.orders</code> (tương tự với revenue).</details>

## ex08 · Thêm email vào newsletter
<details><summary>H1</summary><code>ON CONFLICT DO NOTHING</code> bỏ qua dòng vi phạm khóa, kể cả trùng trong chính danh sách.</details>
<details><summary>H2</summary><code>INSERT INTO f08.newsletter (email) VALUES (…), (…) ON CONFLICT DO NOTHING RETURNING …;</code></details>
<details><summary>H3</summary>Năm bộ giá trị như đề, <code>RETURNING email</code> chỉ trả dòng thật sự được chèn.</details>

## ex09 · Đồng bộ kho hằng đêm
<details><summary>H1</summary><code>MERGE</code> với nguồn đã khử trùng. MERGE chạy nhánh <code>WHEN</code> khớp <b>đầu tiên</b>.</details>
<details><summary>H2</summary><code>MERGE INTO products p USING (&lt;bản mới nhất mỗi sku&gt;) f ON f.sku = p.sku WHEN MATCHED AND … THEN UPDATE … WHEN MATCHED THEN UPDATE … WHEN NOT MATCHED THEN INSERT …;</code></details>
<details><summary>H3</summary>Nhánh 1: <code>WHEN MATCHED AND f.qty = 0 THEN UPDATE SET stock = 0, is_active = false, updated_at = now()</code>. Nhánh 2 dùng <code>COALESCE(f.price, p.price)</code> và <code>is_active = true</code>. Nhánh 3: <code>INSERT (sku, name, price, stock) VALUES (f.sku, f.name, f.price, f.qty)</code>.</details>

## ex10 · Job hủy đơn quá hạn
<details><summary>H1</summary>UPDATE có RETURNING. Mốc thời gian phải mang múi giờ, và "trước" là <code>&lt;</code>.</details>
<details><summary>H2</summary><code>UPDATE f08.orders SET status = …, cancelled_at = … WHERE status = 'pending' AND created_at &lt; '…+07' RETURNING …;</code></details>
<details><summary>H3</summary>Literal: <code>'2026-10-10 00:00:00+07'</code>. Câu hỏi phụ: nghĩ xem điều kiện nào khiến lần chạy thứ 2 không còn dòng nào khớp.</details>
