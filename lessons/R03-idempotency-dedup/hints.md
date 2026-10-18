# R03 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Nạp lô idempotent
<details><summary>H1</summary>Hai kiểu trùng cần hai công cụ khác nhau: trùng với dữ liệu đã lưu, và trùng ngay trong lô.</details>
<details><summary>H2</summary>Trong lô: <code>DISTINCT ON (event_id) … ORDER BY event_id, received_at DESC</code>. Với dữ liệu đã lưu: <code>ON CONFLICT (event_id) DO …</code> (chọn hành động để không ghi đè).</details>
<details><summary>H3</summary><code>INSERT INTO r03.events SELECT DISTINCT ON (event_id) event_id, payload, received_at FROM r03.inbox ORDER BY event_id, received_at DESC ON CONFLICT (event_id) DO NOTHING</code>.</details>

## ex02 · Xóa trùng giữ bản mới nhất
<details><summary>H1</summary>Cần đánh số các dòng trong mỗi nhóm "cùng người" theo thứ tự ưu tiên giữ lại.</details>
<details><summary>H2</summary><code>row_number() OVER (PARTITION BY lower(btrim(email)) ORDER BY updated_at DESC, id DESC)</code>; dòng số 1 được giữ.</details>
<details><summary>H3</summary><code>DELETE FROM r03.contacts WHERE id IN (SELECT id FROM (…) t WHERE rn &gt; 1)</code>. Cách khác: <code>DELETE … USING</code> tự nối so sánh <code>(updated_at, id)</code>.</details>

## ex03 · Tài khoản trùng
<details><summary>H1</summary>Cần một biểu thức chuẩn hóa email đặt trong <code>GROUP BY</code>.</details>
<details><summary>H2</summary><code>lower(btrim(email))</code>, <code>HAVING count(*) &gt; 1</code>.</details>
<details><summary>H3</summary><code>array_agg(id ORDER BY id) AS user_ids</code>.</details>

## ex04 · Mỗi đơn một lần trừ tiền
<details><summary>H1</summary>Thứ tự việc: dọn dữ liệu cũ trước, tạo ràng buộc sau. Ràng buộc chỉ áp dụng cho một trạng thái.</details>
<details><summary>H2</summary>Dọn: <code>UPDATE … SET status = 'refunded' WHERE status = 'succeeded' AND EXISTS (cùng đơn, succeeded, id nhỏ hơn)</code>. Ràng buộc: unique index <b>partial</b>.</details>
<details><summary>H3</summary><code>CREATE UNIQUE INDEX … ON r03.payments (order_id) WHERE status = 'succeeded'</code>.</details>

## ex05 · Hàm charge idempotent
<details><summary>H1</summary>Đừng "kiểm tra có chưa rồi mới chèn". Hãy để ràng buộc unique quyết định ai là người đầu tiên.</details>
<details><summary>H2</summary><code>INSERT INTO r03.idem_keys (key) VALUES (p_key) ON CONFLICT (key) DO NOTHING;</code> rồi <code>IF FOUND THEN … ELSE …</code>.</details>
<details><summary>H3</summary>Nhánh người đầu tiên: chèn <code>pay2</code> <code>RETURNING id INTO v_id</code>, <code>UPDATE idem_keys SET payment_id = v_id</code>. Nhánh còn lại: <code>SELECT payment_id INTO v_id FROM r03.idem_keys WHERE key = p_key</code> (đọc sau khi session kia commit, nhờ lệnh INSERT ở trên đã chờ).</details>

## ex06 · Đồng bộ giá
<details><summary>H1</summary>Lô có khóa trùng và <code>DO UPDATE</code> không chấp nhận chạm một dòng hai lần.</details>
<details><summary>H2</summary>Dedupe bằng <code>DISTINCT ON (sku) … ORDER BY sku, src_updated_at DESC</code>; thêm <code>WHERE</code> trong <code>DO UPDATE</code> với hai điều kiện.</details>
<details><summary>H3</summary><code>WHERE EXCLUDED.src_updated_at &gt; f.src_updated_at AND EXCLUDED.price IS DISTINCT FROM f.price</code> (đặt alias <code>AS f</code> cho bảng đích), <code>RETURNING f.sku</code>.</details>

## ex07 · Payment cần hoàn tiền
<details><summary>H1</summary>Đánh số các payment succeeded của mỗi đơn theo thời gian; từ số 2 trở đi là bản trùng.</details>
<details><summary>H2</summary><code>row_number() OVER w</code> và <code>first_value(created_at) OVER w</code> với <code>WINDOW w AS (PARTITION BY order_id ORDER BY created_at, id)</code>; lọc <code>status = 'succeeded'</code> ở trong.</details>
<details><summary>H3</summary><code>extract(epoch FROM created_at - first_created)::int</code>.</details>

## ex08 · Câu hỏi quy mô
<details><summary>H1</summary>Cách nào chỉ cần gom và đếm, cách nào phải sắp xếp hoặc nối cả bảng?</details>
<details><summary>H2</summary>Đọc <code>Sort Method</code> và <code>Disk Usage</code> trong plan.</details>
<details><summary>H3</summary>Phát hiện trùng khi chưa có index luôn là O(N); chặn lúc ghi là O(log N) mỗi lần ghi.</details>
