# F10 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Phân khúc giá
<details><summary>H1</summary><code>CASE WHEN … THEN … END</code> trong SELECT, rồi GROUP BY theo chính biểu thức đó.</details>
<details><summary>H2</summary>Nhánh đúng đầu tiên thắng, nên chỉ cần viết cận trên. Để sắp theo giá thì sắp theo một giá trị số của nhóm, đừng sắp theo nhãn.</details>
<details><summary>H3</summary><code>GROUP BY 1 ORDER BY min(price)</code>, nhớ <code>WHERE is_active</code>.</details>

## ex02 · Chuẩn hóa tên thành phố
<details><summary>H1</summary>Một CASE xử lý cả ba việc: gộp HCM, giữ tên khác, đặt nhãn cho NULL.</details>
<details><summary>H2</summary><code>CASE WHEN city IN (…) THEN 'TP. Hồ Chí Minh' ELSE … END</code></details>
<details><summary>H3</summary><code>ELSE coalesce(city, '(không rõ)')</code>; <code>WHERE country = 'VN' GROUP BY 1 ORDER BY n_users DESC, city_norm</code>.</details>

## ex03 · Hiển thị sản phẩm
<details><summary>H1</summary>Lấy phần số của sku bằng <code>substr</code>. Ép sang số thì các số 0 đầu tự mất.</details>
<details><summary>H2</summary><code>'P' || substr(sku, 5)::int</code>; tên sạch: <code>trim(name)</code>; số khoảng trắng thừa = hiệu hai độ dài.</details>
<details><summary>H3</summary><code>upper(brand) || ' · ' || trim(name)</code>, <code>length(name) - length(trim(name))</code>, <code>WHERE id &lt;= 10 OR name &lt;&gt; trim(name)</code>.</details>

## ex04 · Tên miền email
<details><summary>H1</summary>Chuẩn hóa email trước khi tách tên miền.</details>
<details><summary>H2</summary><code>split_part(lower(trim(email)), '@', 2)</code>. Tổng số khách lấy bằng scalar subquery.</details>
<details><summary>H3</summary><code>round(100.0 * count(*) / (SELECT count(*) FROM users), 1)</code>.</details>

## ex05 · Nhóm tuổi
<details><summary>H1</summary>Dùng <code>age(mốc, birth_date)</code> chứ đừng trừ năm cho năm.</details>
<details><summary>H2</summary>Tính tuổi trong một subquery ở FROM, ngoài là CASE + GROUP BY. NULL phải được xét ở nhánh đầu tiên.</details>
<details><summary>H3</summary><code>extract(year FROM age(date '2026-10-01', birth_date))::int</code>; sắp xếp <code>ORDER BY min(age)</code> (nhóm NULL tự xuống cuối).</details>

## ex06 · Báo cáo tháng
<details><summary>H1</summary>Lọc bằng literal +07 (nửa mở), cắt tháng sau khi đổi sang giờ VN.</details>
<details><summary>H2</summary><code>date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')</code> dùng cho GROUP BY và ORDER BY; <code>to_char(…, 'MM/YYYY')</code> để hiển thị.</details>
<details><summary>H3</summary>Doanh thu: <code>replace(to_char(sum(total_amount), 'FM999,999,999,999'), ',', '.') || ' ₫'</code>. Loại <code>status NOT IN ('cancelled', 'refunded')</code>.</details>

## ex07 · Thứ trong tuần
<details><summary>H1</summary><code>extract(isodow …)</code> theo giờ VN, rồi đổi số thành nhãn bằng CASE dạng simple.</details>
<details><summary>H2</summary>GROUP BY và ORDER BY theo số isodow. Tổng số đơn của quý lấy bằng scalar subquery có cùng điều kiện lọc.</details>
<details><summary>H3</summary><code>CASE extract(isodow FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') WHEN 1 THEN 'Thứ 2' … WHEN 7 THEN 'Chủ nhật' END</code>.</details>

## ex08 · Sinh nhật tuần tới
<details><summary>H1</summary>Đừng dựng ngày sinh nhật năm 2026 bằng <code>make_date</code>: có người sinh 29/02. Hãy so phần "tháng-ngày".</details>
<details><summary>H2</summary><code>to_char(birth_date, 'MM-DD')</code> ra chuỗi độ dài cố định, so sánh chuỗi được.</details>
<details><summary>H3</summary><code>WHERE deleted_at IS NULL AND to_char(birth_date, 'MM-DD') BETWEEN '10-19' AND '10-25'</code>, <code>tuoi_moi = 2026 - extract(year FROM birth_date)::int</code>.</details>

## ex09 · Phân hạng khách
<details><summary>H1</summary>Ba tầng: gom theo khách → gán nhãn bằng CASE → đếm theo nhãn.</details>
<details><summary>H2</summary>recency: <code>date '2026-10-01' - max((created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)</code>. Thứ tự các nhánh CASE phải đúng thứ tự ưu tiên của đề.</details>
<details><summary>H3</summary>Sắp xếp: <code>ORDER BY array_position(ARRAY['VIP', 'Trung thành', 'Ngủ đông', 'Thường'], segment)</code>. Tầng trong cùng JOIN <code>users</code> để lọc <code>deleted_at IS NULL</code>.</details>

## ex10 · Phiếu đơn hàng
<details><summary>H1</summary>Từng cột là một biểu thức chuỗi. Xử lý định dạng <code>+84</code> trước khi cắt 3 số đầu.</details>
<details><summary>H2</summary><code>lpad(o.id::text, 6, '0')</code>; <code>regexp_replace(phone, '^\+84\s*', '0')</code>; nối chuỗi có vế NULL thì ra NULL, tận dụng điều đó rồi bọc <code>coalesce</code>.</details>
<details><summary>H3</summary><code>coalesce(left(regexp_replace(u.phone, '^\+84\s*', '0'), 3) || '****' || right(u.phone, 3), '(không có)')</code>; email: <code>left(e, 1) || '***@' || split_part(e, '@', 2)</code> với <code>e = lower(trim(u.email))</code>.</details>
