# R06 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Cây con
<details><summary>H1</summary>Neo của recursive CTE là các con trực tiếp; phần đệ quy tìm con của những nút đã tìm thấy.</details>
<details><summary>H2</summary>Neo: <code>WHERE parent_id = 2</code> với <code>depth = 1</code>. Đệ quy: <code>JOIN sub s ON c.parent_id = s.id</code>, <code>depth + 1</code>.</details>
<details><summary>H3</summary><code>UNION ALL</code> (cây sạch, không cần khử trùng). <code>ORDER BY depth, id</code> ở truy vấn ngoài.</details>

## ex02 · Breadcrumb
<details><summary>H1</summary>Đi từ gốc xuống; mỗi bước nối thêm tên nút con vào đường dẫn của cha.</details>
<details><summary>H2</summary>Neo: <code>WHERE parent_id IS NULL</code>, <code>name::text AS breadcrumb</code>. Đệ quy: <code>t.breadcrumb || ' &gt; ' || c.name</code>.</details>
<details><summary>H3</summary>Ép <code>name::text</code> ở neo để kiểu cột của hai vế khớp nhau.</details>

## ex03 · Dựng path ltree
<details><summary>H1</summary>path của con = path của cha nối thêm nhãn của chính nó.</details>
<details><summary>H2</summary>Recursive CTE trả <code>(id, p)</code>, rồi <code>UPDATE r06.cat c SET path = t.p FROM t WHERE t.id = c.id</code>.</details>
<details><summary>H3</summary>Nhãn: <code>id::text</code>; gốc: <code>id::text::ltree</code>; nối: <code>t.p || c.id::text</code>.</details>

## ex04 · Closure table
<details><summary>H1</summary>Mỗi nút là tổ tiên của chính nó với depth 0; sau đó mỗi bước đệ quy đi xuống một tầng.</details>
<details><summary>H2</summary>Neo: <code>SELECT id, id, 0 FROM r06.cat</code>. Đệ quy: <code>JOIN r06.cat k ON k.parent_id = c.descendant</code>, giữ <code>c.ancestor</code>, <code>depth + 1</code>.</details>
<details><summary>H3</summary>Kết quả có <code>(ancestor, descendant, depth)</code>; chèn vào <code>r06.cat_closure</code> bằng <code>INSERT … SELECT</code> từ CTE.</details>

## ex05 · Thống kê theo gốc
<details><summary>H1</summary>Closure có cặp tự thân nên "cây con của gốc g" = các <code>descendant</code> với <code>ancestor = g</code>.</details>
<details><summary>H2</summary><code>cat r JOIN closure k ON k.ancestor = r.id LEFT JOIN prod p ON p.category_id = k.descendant</code>, lọc gốc bằng <code>r.parent_id IS NULL</code>.</details>
<details><summary>H3</summary><code>count(DISTINCT k.descendant)</code> cho số danh mục (nếu không, JOIN với <code>prod</code> làm nhân dòng); <code>count(p.id)</code> cho số sản phẩm.</details>

## ex06 · Chuyển cây con
<details><summary>H1</summary>Mọi nút có path bắt đầu bằng <code>2.16</code> phải đổi tiền tố thành <code>3.16</code>; và <code>parent_id</code> của 16 đổi từ 2 sang 3.</details>
<details><summary>H2</summary>Chọn cây con bằng <code>path &lt;@ (path của 16)</code>. Path mới = path của 3 <code>||</code> <code>subpath(path, nlevel(path cũ của 16) - 1)</code>.</details>
<details><summary>H3</summary>Hai câu UPDATE: một cho path của cả cây con, một cho <code>parent_id</code> của nút 16. Lấy path cũ trong subquery <b>trước</b> khi nó bị sửa (một câu UPDATE thấy dữ liệu cũ nhất quán).</details>

## ex07 · Nested set
<details><summary>H1</summary>Tổ tiên của n có khoảng [lft, rgt] bao trọn khoảng của n.</details>
<details><summary>H2</summary><code>a.lft &lt; n.lft AND a.rgt &gt; n.rgt</code> (không dấu bằng, để loại chính n).</details>
<details><summary>H3</summary>Hậu duệ của a (không tính a) = <code>(a.rgt - a.lft - 1) / 2</code>, vì mỗi hậu duệ chiếm 2 vị trí trong khoảng.</details>

## ex08 · Chặn chu trình
<details><summary>H1</summary>Từ cha mới đi lên: nếu gặp lại chính nút đang sửa thì sẽ tạo chu trình.</details>
<details><summary>H2</summary>Trigger <code>BEFORE</code> với recursive CTE đi lên từ <code>NEW.parent_id</code>; kiểm riêng trường hợp <code>NEW.parent_id = NEW.id</code>.</details>
<details><summary>H3</summary><code>RAISE EXCEPTION … USING ERRCODE = 'check_violation'</code>; <code>RETURN NEW</code> ở cuối. Trigger khai báo <code>BEFORE INSERT OR UPDATE OF parent_id ON r06.cat FOR EACH ROW</code>.</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Cách nào phải ghi lại nhiều dòng khi một nút đổi cha?</details>
<details><summary>H2</summary>Với nested set, tổ tiên cần hai bất đẳng thức trên hai cột; một index B-tree một cột có giúp được không?</details>
<details><summary>H3</summary>Danh mục sản phẩm: adjacency hoặc ltree. Cây bình luận: adjacency hoặc closure. Org chart di chuyển nhiều: adjacency (1 dòng) hoặc ltree.</details>
