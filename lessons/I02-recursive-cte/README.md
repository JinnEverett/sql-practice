# I02 · Recursive CTE

Đọc khoảng 8 phút. Ví dụ chạy trên `shop_s` (cây danh mục) và `lab` (schema `i02`).

## Mục tiêu: sau buổi này bạn làm được
- Viết `WITH RECURSIVE` gồm phần **neo** và phần **đệ quy**, và hiểu nó chạy theo vòng lặp như thế nào.
- Duyệt cây **xuống** (con cháu) và **lên** (tổ tiên, breadcrumb), mang theo `depth`, `path`, `root_id`.
- Duyệt **đồ thị** có hướng với giới hạn số bước, và **chống vòng lặp vô hạn** (mảng `visited`, mệnh đề `CYCLE`).
- Tính dồn theo cây (nhân số lượng trong định mức vật tư).

---

## 1. Cấu trúc và cách chạy
```sql
WITH RECURSIVE t AS (
  SELECT id, name, 0 AS depth                 -- (1) NEO: chạy MỘT lần
  FROM categories WHERE id = 2
  UNION ALL
  SELECT c.id, c.name, t.depth + 1            -- (2) ĐỆ QUY: tham chiếu chính t
  FROM categories c JOIN t ON c.parent_id = t.id
)
SELECT * FROM t;
```
Cách Postgres thực thi:
1. Chạy phần neo, ghi kết quả vào **working table** (W) và vào kết quả cuối.
2. Chạy phần đệ quy, trong đó `t` là **chỉ W** (các dòng của vòng trước, không phải toàn bộ kết quả). Dòng mới trở thành W của vòng sau và được thêm vào kết quả.
3. Lặp lại cho tới khi một vòng **không sinh dòng nào**.

Hệ quả:
- Phải có **điều kiện dừng** tự nhiên (hết con) hoặc tường minh (`WHERE depth < 5`). Nếu không, query chạy mãi.
- Số vòng = độ sâu. Mỗi vòng là một lần JOIN với bảng gốc, nên cột dùng để JOIN (`parent_id`) cần có **index** (ex09).
- `UNION ALL` giữ mọi dòng. `UNION` bỏ dòng trùng **trên toàn bộ dòng**, chỉ chặn được vòng lặp khi dòng lặp lại giống hệt (điều không xảy ra nếu có cột `depth` hay `path`).
- Kiểu dữ liệu của phần đệ quy phải khớp phần neo. Ví dụ neo là `name` kiểu `text` thì `path || ' > ' || name` cũng là `text`. Nếu neo là `varchar(50)` thì phải ép `::text`, không thì lỗi.

## 2. Đi xuống, đi lên, mang theo thông tin
```sql
-- đi xuống: mang path và depth
SELECT id, name, depth, path FROM (
  WITH RECURSIVE t AS (
    SELECT id, name, 0 AS depth, name AS path FROM categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.name, t.depth + 1, t.path || ' > ' || c.name FROM categories c JOIN t ON c.parent_id = t.id)
  SELECT * FROM t) x
WHERE depth = 2 ORDER BY path LIMIT 3;

-- đi lên: từ một node tới gốc
WITH RECURSIVE up AS (
  SELECT id, parent_id, name FROM categories WHERE id = 38      -- Văn học
  UNION ALL
  SELECT c.id, c.parent_id, c.name FROM categories c JOIN up ON c.id = up.parent_id
)
SELECT string_agg(name, ' > ' ORDER BY id) FROM up;           -- Sách > Sách tiếng Việt > Văn học
```
- Đi xuống: `JOIN … ON con.parent_id = t.id`. Đi lên: `JOIN … ON cha.id = t.parent_id`.
- Muốn ánh xạ mọi node về **gốc** của nó: neo từ các gốc, mang theo `root_id` xuống mọi tầng.
- (Ví dụ đi lên `ORDER BY id` chỉ đúng vì ở dữ liệu này id cha luôn nhỏ hơn id con. Cách chắc chắn là ghép chuỗi ngay trong đệ quy như ex03.)

## 3. Đồ thị và vòng lặp
Cây thì không có vòng, nhưng đồ thị (tuyến bay, quan hệ bạn bè) và dữ liệu bẩn thì có. Hai cách chặn:
```sql
-- (a) tự giữ mảng các node đã qua
WITH RECURSIVE r AS (
  SELECT dst AS at, ARRAY['SGN', dst] AS visited, 1 AS legs FROM i02.flights WHERE src = 'SGN'
  UNION ALL
  SELECT f.dst, r.visited || f.dst, r.legs + 1
  FROM r JOIN i02.flights f ON f.src = r.at
  WHERE r.legs < 3                         -- giới hạn số bước
    AND NOT f.dst = ANY (r.visited)        -- không quay lại sân bay đã qua
)
SELECT array_to_string(visited, '→') FROM r WHERE at = 'HAN' LIMIT 3;

-- (b) mệnh đề CYCLE (Postgres 14+): tự thêm cột cờ và cột path
WITH RECURSIVE w (id, manager_id) AS (
  SELECT id, manager_id FROM i02.emp_import WHERE id = 21
  UNION ALL
  SELECT e.id, e.manager_id FROM i02.emp_import e JOIN w ON e.id = w.manager_id
) CYCLE id SET is_cycle USING path
SELECT id, is_cycle, path FROM w;
```
`CYCLE id SET is_cycle USING path`: khi một dòng mới có `id` đã nằm trong `path`, dòng đó được đánh `is_cycle = true` và không đi tiếp. Ngoài ra còn mệnh đề `SEARCH DEPTH FIRST BY … SET ord` để sắp kết quả theo thứ tự duyệt sâu.

## 4. Tính dồn theo cây
Ở mỗi bước, giá trị của con = giá trị của cha (đã tính dồn) × hệ số trên cạnh:
```sql
SELECT child, qty * 10 FROM i02.bom WHERE parent = 'Laptop'            -- neo
UNION ALL
SELECT b.child, need.total_qty * b.qty FROM need JOIN i02.bom b ON b.parent = need.part   -- đệ quy
```

## Bẫy hay gặp
1. Quên điều kiện dừng trên đồ thị có vòng → query chạy mãi (bấm Ctrl+C, hoặc đặt `SET statement_timeout = '5s'` trước khi thử).
2. Đi nhầm chiều: `c.id = t.parent_id` là đi **lên**, `c.parent_id = t.id` là đi **xuống**.
3. JOIN cố định một tầng cha (`categories c JOIN categories p`) để lấy "gốc": sai với node ở tầng sâu hơn.
4. Không nhân dồn hệ số khi tính theo cây (chỉ nhân với hệ số của cạnh cuối).
5. Không có index trên cột cha → mỗi vòng quét cả bảng (ex09).

## Postgres-specific
- MySQL 8 có `WITH RECURSIVE` nhưng không có `CYCLE`/`SEARCH`. SQL Server không cần chữ `RECURSIVE`.
- Với cây lớn, đọc nhiều hơn ghi, Postgres có extension `ltree` (R06).
