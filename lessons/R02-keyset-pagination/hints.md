# R02 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Trang 5 bằng OFFSET
<details><summary>H1</summary>OFFSET bỏ qua các dòng của những trang trước.</details>
<details><summary>H2</summary>Trang 5, mỗi trang 10: bỏ qua 4 trang.</details>
<details><summary>H3</summary><code>ORDER BY created_at DESC, id DESC LIMIT 10 OFFSET 40</code>.</details>

## ex02 · Keyset
<details><summary>H1</summary>Thay "bỏ qua k dòng" bằng điều kiện "đứng sau dòng cursor".</details>
<details><summary>H2</summary>So sánh row-value <code>(created_at, id) &lt; (…, …)</code>.</details>
<details><summary>H3</summary><code>WHERE (created_at, id) &lt; ('2026-09-30 09:45:28.287597+00', 9991) ORDER BY created_at DESC, id DESC LIMIT 10</code>.</details>

## ex03 · Cursor giữa nhóm trùng giờ
<details><summary>H1</summary>Chỉ so <code>created_at</code> thì mất hoặc lặp các bài cùng giờ.</details>
<details><summary>H2</summary>Cursor là cặp <code>(created_at, id)</code>.</details>
<details><summary>H3</summary><code>WHERE (created_at, id) &lt; ('2026-01-01 00:20+00', 103)</code>.</details>

## ex04 · NULL
<details><summary>H1</summary>So sánh với NULL không cho true/false. Sắp xếp NULLS LAST: NULL "lớn hơn" mọi ngày sinh.</details>
<details><summary>H2</summary>Cursor có giá trị: lấy <code>birth_date &lt; c</code>, hoặc bằng và <code>id &gt; c_id</code>, hoặc <code>birth_date IS NULL</code>. Cursor NULL: <code>birth_date IS NULL AND id &gt; c_id</code>.</details>
<details><summary>H3</summary>Mỗi case một subquery có <code>ORDER BY birth_date DESC NULLS LAST, id LIMIT 8</code>, gộp bằng <code>UNION ALL</code> rồi <code>ORDER BY</code> ngoài cùng.</details>

## ex05 · Hướng hỗn hợp
<details><summary>H1</summary>Row-value không dùng được khi các cột có hướng khác nhau.</details>
<details><summary>H2</summary>Viết từng nhánh: status lớn hơn; hoặc status bằng và created_at nhỏ hơn; hoặc hai cột bằng và id nhỏ hơn.</details>
<details><summary>H3</summary><code>WHERE status &gt; 'open' OR (status = 'open' AND created_at &lt; ts) OR (status = 'open' AND created_at = ts AND id &lt; 12)</code>.</details>

## ex06 · Hàm phân trang
<details><summary>H1</summary>Hàm SQL trả về bảng (<code>RETURNS TABLE</code>); cursor NULL xử lý trong <code>WHERE</code>.</details>
<details><summary>H2</summary><code>WHERE p_ts IS NULL OR (f.created_at, f.id) &lt; (p_ts, p_id)</code>, <code>LIMIT p_size</code>.</details>
<details><summary>H3</summary>Đặt tên cột bảng có alias (<code>f.id</code>) để không đụng tên cột output của <code>RETURNS TABLE</code>.</details>

## ex07 · Trang trước
<details><summary>H1</summary>Đi ngược lên từ cursor rồi đảo lại thứ tự để hiển thị.</details>
<details><summary>H2</summary>Subquery: <code>WHERE (created_at, id) &gt; cursor ORDER BY created_at, id LIMIT 7</code>; ngoài: <code>ORDER BY created_at DESC, id DESC</code>.</details>
<details><summary>H3</summary>Nếu không đảo ORDER BY trong subquery, <code>LIMIT 7</code> lấy 7 bài mới nhất của cả feed.</details>

## ex08 · Index cho trang của một khách
<details><summary>H1</summary>Cột lọc bằng đứng trước, rồi các cột sắp xếp.</details>
<details><summary>H2</summary>Cần ba cột: khách, thời gian, id, với hướng DESC khớp với ORDER BY.</details>
<details><summary>H3</summary><code>CREATE INDEX … ON orders (user_id, created_at DESC, id DESC)</code>. Sau đó <code>-- query</code> và câu SELECT.</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Postgres có "nhảy" tới dòng thứ k không, hay phải sinh ra k dòng rồi bỏ?</details>
<details><summary>H2</summary>Đếm <code>Buffers</code> trong plan của OFFSET lớn so với keyset.</details>
<details><summary>H3</summary>Không index: cả hai đọc cả bảng; có index: OFFSET đi qua k entry của index, keyset dò thẳng tới cursor.</details>
