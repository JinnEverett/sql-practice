# I09 · View, materialized view, function, trigger

Đọc khoảng 10 phút. Ví dụ chạy trên DB `lab`, schema `i09` (chạy `setup.sql` để có dữ liệu mẫu; bài nào cũng tự reset về trạng thái ban đầu).

## Mục tiêu: sau buổi này bạn làm được
- Tạo **view** để đặt tên cho truy vấn, ẩn cột, dùng lại logic; biết view *không lưu dữ liệu*.
- Dùng **WITH CHECK OPTION** để view có thể ghi mà không làm dòng "trượt ra ngoài".
- Dùng **materialized view** + `REFRESH … CONCURRENTLY` (và hiểu vì sao cần unique index).
- Viết **function** SQL và PL/pgSQL, chọn đúng `IMMUTABLE / STABLE / VOLATILE`, `STRICT`.
- Viết **trigger** (BEFORE/AFTER, ROW/STATEMENT, `WHEN`), và biết khi nào *không* nên dùng trigger.

---

## 1. View
```sql
CREATE VIEW i09.v_active_customers AS
SELECT id, name FROM i09.customers WHERE status = 'active';
```
- View là câu `SELECT` được đặt tên. Mỗi lần đọc, Postgres **thay định nghĩa vào truy vấn** (rule rewrite) rồi plan lại. Không có dữ liệu riêng, không có index riêng, và luôn thấy dữ liệu mới. Xem định nghĩa: `SELECT pg_get_viewdef('i09.v_active_customers'::regclass)`.
- Không tự nhanh hơn: view chỉ giúp **dùng lại** và **ẩn**. View lồng view nhiều tầng làm plan khó đọc; planner thường vẫn đẩy điều kiện xuống được (predicate pushdown), nhưng `DISTINCT`, window function, `LIMIT` ở giữa thì có thể chặn.
- Quyền: mặc định view chạy với quyền của **chủ view**, nên cấp `SELECT` trên view cho người dùng mà không cấp trên bảng gốc là cách ẩn cột/dòng (O01). Thêm `WITH (security_invoker = true)` để view chạy với quyền của người gọi (cần cho RLS đúng ý).
- **Updatable view**: view đơn giản (một bảng, không `DISTINCT`, `GROUP BY`, window, tập hợp) cho `INSERT/UPDATE/DELETE` thẳng. Thêm `WITH CHECK OPTION` để chặn thao tác khiến dòng không còn thỏa điều kiện của view (lỗi `44000`).
- `CREATE OR REPLACE VIEW` chỉ cho phép **thêm cột ở cuối**, giữ nguyên tên, kiểu, thứ tự cột cũ (ex08). Đổi nhiều hơn → `DROP VIEW` (có `CASCADE` thì xóa luôn view phụ thuộc).

## 2. Materialized view
```sql
CREATE MATERIALIZED VIEW i09.mv_daily_revenue AS
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, sum(total) AS revenue
FROM i09.orders GROUP BY 1;
CREATE UNIQUE INDEX ON i09.mv_daily_revenue (day);
REFRESH MATERIALIZED VIEW CONCURRENTLY i09.mv_daily_revenue;
```
- **Lưu** kết quả như một bảng (có thể đặt index riêng). Đọc nhanh, nhưng **cũ** cho tới khi `REFRESH`. Postgres không tự làm mới, bạn lên lịch (cron, pg_cron, job ứng dụng).
- `REFRESH` thường khóa `ACCESS EXCLUSIVE`: chặn cả `SELECT` trong lúc làm mới. `REFRESH … CONCURRENTLY` giữ người đọc, nhưng phải có **ít nhất một UNIQUE index** (không phải partial, không phải biểu thức) trên matview và chậm hơn do phải so sánh bản cũ/mới.
- Mỗi lần `REFRESH` **tính lại toàn bộ**, không có refresh tăng dần. Hợp khi: báo cáo, dashboard chấp nhận độ trễ vài phút, truy vấn nặng đọc nhiều. Không hợp khi cần dữ liệu tức thời.
- Số đo trên `shop_m` (1M đơn): tính 992 dòng theo ngày từ `orders` mất ~500 ms mỗi lần, đọc matview `WHERE day = …` mất ~0.02 ms (ex09).

## 3. Function
```sql
-- SQL: một câu lệnh, có thể được inline vào truy vấn gọi nó
CREATE FUNCTION i09.vat_incl(amount numeric, rate numeric DEFAULT 0.08)
RETURNS numeric LANGUAGE sql IMMUTABLE STRICT
AS $$ SELECT round(amount * (1 + rate), 0) $$;

-- PL/pgSQL: biến, rẽ nhánh, vòng lặp, ngoại lệ
CREATE FUNCTION i09.get_total(p_id int) RETURNS numeric LANGUAGE plpgsql AS $$
DECLARE v numeric;
BEGIN
  SELECT total INTO v FROM i09.orders WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'đơn % không tồn tại', p_id USING ERRCODE = 'no_data_found'; END IF;
  RETURN v;
END $$;
```
| Độ ổn định | Ý nghĩa | Hệ quả |
|---|---|---|
| `IMMUTABLE` | cùng đối số → cùng kết quả mãi mãi, không đọc bảng | dùng được trong index expression; planner tính trước khi đối số là hằng |
| `STABLE` | cùng kết quả trong một câu lệnh; được đọc bảng | dùng được trong điều kiện index scan, không dùng trong index expression |
| `VOLATILE` (mặc định) | có thể khác nhau mỗi lần gọi, có thể ghi dữ liệu | chạy từng dòng, planner không tối ưu gì |

- Khai báo sai độ ổn định là **nói dối planner**: hàm đọc bảng mà đánh dấu `IMMUTABLE` thì index trên nó sẽ sai âm thầm.
- `STRICT` (= `RETURNS NULL ON NULL INPUT`): đối số NULL → trả NULL, không chạy thân hàm.
- `UPDATE … RETURNING … INTO v` rồi kiểm tra `FOUND`; `INTO STRICT` ném lỗi nếu không đúng 1 dòng. Dùng `RAISE EXCEPTION … USING ERRCODE` để ứng dụng bắt đúng loại lỗi.
- `SECURITY DEFINER` chạy với quyền chủ hàm: **luôn** kèm `SET search_path = tên_schema, pg_temp`, nếu không người gọi có thể đánh tráo hàm/bảng trùng tên (O01).
- Hàm gọi trong `SELECT … FROM bảng_lớn` chạy **theo từng dòng**: PL/pgSQL không inline được, mỗi lần gọi có chi phí cố định. Logic dạng tập hợp thì viết bằng SQL set-based.

## 4. Trigger
```sql
CREATE FUNCTION i09.log_price_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO i09.price_history (product_id, old_price, new_price) VALUES (OLD.id, OLD.price, NEW.price);
  RETURN NULL;                              -- AFTER trigger: giá trị trả về bị bỏ qua
END $$;

CREATE TRIGGER trg_price AFTER UPDATE OF price ON i09.products
FOR EACH ROW WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION i09.log_price_change();
```
- **Thời điểm:** `BEFORE` (sửa `NEW`, hoặc `RETURN NULL` để bỏ qua dòng, hoặc ném lỗi để hủy) · `AFTER` (dòng đã ghi, thấy kết quả cuối) · `INSTEAD OF` (chỉ trên view).
- **Mức:** `FOR EACH ROW` (có `OLD`/`NEW`) · `FOR EACH STATEMENT` (chạy 1 lần; muốn thấy các dòng thì khai báo `REFERENCING NEW TABLE AS …`).
- Biến trong hàm trigger: `TG_OP` (`'INSERT'|'UPDATE'|'DELETE'`), `OLD`, `NEW`, `TG_TABLE_NAME`.
- Lọc ở mức engine: `UPDATE OF cột` (chỉ khi cột nằm trong `SET`) và `WHEN (điều kiện)` (không gọi hàm nếu điều kiện sai). Rẻ hơn nhiều so với `IF` bên trong hàm.
- Trigger chạy **trong cùng transaction** với câu lệnh gây ra nó: rollback thì mọi thứ trigger ghi cũng mất, và lỗi trong trigger hủy cả câu lệnh.
- **Chi phí:** trigger ROW chạy cho **từng dòng**. Số đo ở ex09: `UPDATE` 1M dòng 4.3 s → 11.8 s khi có trigger ghi lịch sử, trong khi `INSERT … SELECT` 1M dòng vào bảng lịch sử chỉ tốn 2.4 s.
- **Khi nên dùng:** audit/lịch sử, ràng buộc không diễn đạt được bằng `CHECK/FK`, giữ cột dẫn xuất. **Khi không:** logic nghiệp vụ chính (khó thấy, khó test, khó debug), thao tác hàng loạt (đổi sang SQL set-based), thứ có thể là `CHECK`, `DEFAULT` hay generated column (F09).

## Bẫy hay gặp
1. `created_at::date` trên `timestamptz` dùng múi giờ session (UTC), không phải giờ VN.
2. View không có `WITH CHECK OPTION`: ghi qua view chèn được dòng mà view không còn thấy.
3. Matview không có unique index → `REFRESH … CONCURRENTLY` báo lỗi `55000`.
4. Quên `IMMUTABLE`: hàm PL/pgSQL không tạo được index (`42P17`, "functions in index expression must be marked IMMUTABLE"); hàm SQL đơn giản có thể lọt vì được inline, nhưng vẫn là VOLATILE ở mọi chỗ khác.
5. Hàm PL/pgSQL `UPDATE … RETURNING INTO` không kiểm tra `FOUND`: đơn không tồn tại mà hàm im lặng trả NULL.
6. Trigger kho `AFTER` không kiểm tra, hoặc "SELECT stock rồi UPDATE" trong ứng dụng: hai session cùng đặt hàng cuối cùng → kho âm. Dùng `UPDATE … WHERE stock >= n` rồi xem `FOUND`.
7. Trigger không `WHEN` → ghi lịch sử cả khi giá không đổi.
8. `SECURITY DEFINER` thiếu `SET search_path`.

## Postgres-specific
- Matview là tính năng riêng của Postgres/Oracle; MySQL không có (phải tự làm bảng tổng hợp). `REFRESH CONCURRENTLY` là của Postgres.
- Hàm trigger tách khỏi `CREATE TRIGGER` (một hàm gắn được nhiều bảng); MySQL viết thân trigger ngay trong `CREATE TRIGGER`.
- Có hàm PL/pgSQL, ngoài ra còn procedure (`CREATE PROCEDURE … CALL`) kiểm soát được transaction bên trong; chưa cần ở mức này.
