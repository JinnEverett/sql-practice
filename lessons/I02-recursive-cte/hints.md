# I02 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Lịch đơn hàng
<details><summary>H1</summary>Neo là ngày đầu, phần đệ quy cộng thêm 1 ngày. Số đơn theo ngày gom riêng rồi LEFT JOIN.</details>
<details><summary>H2</summary><code>WITH RECURSIVE days AS (SELECT date '2026-09-01' AS d UNION ALL SELECT d + 1 FROM days WHERE d &lt; date '2026-09-30')</code></details>
<details><summary>H3</summary>Gom theo <code>(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date</code>; <code>coalesce(daily.n, 0)</code>.</details>

## ex02 · Cây danh mục Điện tử
<details><summary>H1</summary>Neo chính là dòng 'Điện tử' (depth 0). Phần đệ quy tìm các danh mục có cha nằm trong vòng trước.</details>
<details><summary>H2</summary><code>SELECT c.id, c.name, t.depth + 1, t.path || ' &gt; ' || c.name FROM categories c JOIN t ON c.parent_id = t.id</code></details>
<details><summary>H3</summary>Neo: <code>SELECT id, name, 0 AS depth, name AS path FROM categories WHERE name = 'Điện tử'</code>; cuối: <code>ORDER BY path</code>.</details>

## ex03 · Breadcrumb
<details><summary>H1</summary>Đi LÊN cây: bắt đầu từ danh mục của sản phẩm, mỗi bước sang cha, ghép tên cha vào <b>đầu</b> chuỗi.</details>
<details><summary>H2</summary>Mang theo <code>product_id</code>, <code>parent_id</code>, <code>breadcrumb</code>. Lấy dòng đã tới gốc: <code>WHERE parent_id IS NULL</code>.</details>
<details><summary>H3</summary>Đệ quy: <code>SELECT up.product_id, c.parent_id, c.name || ' &gt; ' || up.breadcrumb FROM up JOIN categories c ON c.id = up.parent_id</code>; neo nhớ ép <code>c.name::text</code>.</details>

## ex04 · Doanh thu theo gốc
<details><summary>H1</summary>Dựng bảng ánh xạ "danh mục → gốc" bằng đệ quy đi xuống từ các gốc, mang theo tên gốc.</details>
<details><summary>H2</summary>Neo: <code>SELECT id, id AS root_id, name AS root_name FROM categories WHERE parent_id IS NULL</code>; đệ quy giữ nguyên root_id/root_name.</details>
<details><summary>H3</summary>Câu chính: <code>order_items JOIN orders (delivered) JOIN products JOIN tree ON tree.id = p.category_id GROUP BY root_name</code>.</details>

## ex05 · Quy mô từng team
<details><summary>H1</summary>Sinh mọi cặp (sếp, người dưới quyền) ở mọi tầng, rồi đếm theo sếp.</details>
<details><summary>H2</summary>Neo: các cặp trực tiếp <code>(manager_id AS boss_id, id AS emp_id)</code>. Đệ quy: cấp dưới của <code>emp_id</code> vẫn thuộc <code>boss_id</code>.</details>
<details><summary>H3</summary>Đệ quy: <code>SELECT sub.boss_id, e.id FROM sub JOIN i02.employees e ON e.manager_id = sub.emp_id</code>; <code>n_direct</code> đếm bằng scalar subquery hoặc <code>count(*) FILTER</code> trên neo.</details>

## ex06 · Vòng lặp
<details><summary>H1</summary>Đi lên từ <b>mỗi</b> người, nhớ mình xuất phát từ đâu (start_id) và đã đi qua những ai.</details>
<details><summary>H2</summary>Mảng <code>path</code> + điều kiện <code>NOT e.id = ANY (w.path)</code> để dừng. Hoặc dùng mệnh đề <code>CYCLE id SET is_cycle USING path</code>.</details>
<details><summary>H3</summary>Người thuộc vòng ⇔ trên đường đi lên gặp lại chính mình: <code>WHERE next_id = start_id</code> (hoặc <code>is_cycle AND id = start_id</code>), nhớ <code>DISTINCT</code>.</details>

## ex07 · Vé máy bay
<details><summary>H1</summary>Neo: mọi chuyến từ SGN. Đệ quy: nối thêm chuyến từ điểm đang đứng. Cần hai điều kiện dừng.</details>
<details><summary>H2</summary>Mang theo <code>at</code>, <code>visited text[]</code>, <code>legs</code>, <code>total_price</code>. Điều kiện: <code>r.legs &lt; 3 AND NOT f.dst = ANY (r.visited)</code>.</details>
<details><summary>H3</summary><code>array_to_string(visited, '→')</code>; <code>WHERE at = 'HAN' ORDER BY total_price, route LIMIT 3</code>. Neo: <code>ARRAY['SGN', dst]</code>.</details>

## ex08 · Linh kiện cho 10 laptop
<details><summary>H1</summary>Số lượng ở mỗi tầng = số lượng của cha (đã nhân dồn) × qty.</details>
<details><summary>H2</summary>Neo: <code>SELECT child AS part, qty * 10 AS total_qty FROM i02.bom WHERE parent = 'Laptop'</code>. Đệ quy: <code>need.total_qty * b.qty</code>.</details>
<details><summary>H3</summary>Giữ lá: <code>WHERE NOT EXISTS (SELECT 1 FROM i02.bom b WHERE b.parent = need.part)</code>, rồi <code>GROUP BY part</code> + <code>sum</code>.</details>
