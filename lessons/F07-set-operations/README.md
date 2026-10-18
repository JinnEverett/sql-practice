# F07 · Set operations

Đọc khoảng 8 phút. Ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Chọn đúng giữa **`UNION`** và **`UNION ALL`**, và biết `UNION` ngầm làm thêm việc gì.
- Dùng **`INTERSECT`** ("có ở cả hai") và **`EXCEPT`** ("có ở A mà không có ở B") thay cho `JOIN`/`NOT EXISTS` khi so sánh hai tập.
- Biết thứ tự ưu tiên giữa các phép: `INTERSECT` chạy **trước** `UNION`/`EXCEPT`.
- Biết các phép tập hợp coi **NULL = NULL**, khác với `=`.
- Phân biệt bản "set" và bản **`ALL`** (multiset) khi so sánh hai bảng có dòng trùng.

---

## 1. Ý tưởng: ghép các **kết quả**, không phải các bảng
`JOIN` ghép **theo chiều ngang** (thêm cột). Set operation ghép **theo chiều dọc** (chồng dòng). Hai vế phải thỏa:
- **Cùng số cột.**
- Các cột **cùng vị trí** phải có kiểu tương thích. Ghép theo **vị trí**, không theo tên.
- **Tên cột** của kết quả lấy từ vế **đầu tiên**.

```sql
SELECT id AS a, full_name AS b FROM users WHERE id = 1
UNION ALL
SELECT id, email FROM users WHERE id = 2;
--  a |         b
--  1 | Huỳnh Đức Ngọc
--  2 | ngoc.vu2@yahoo.com        ← cột b chứa tên ở dòng 1, email ở dòng 2: SQL không phàn nàn
```
Sai số cột thì báo lỗi `each UNION query must have the same number of columns`. Sai kiểu thì báo lỗi lúc chạy, ví dụ `SELECT 1 UNION SELECT 'a'` → `invalid input syntax for type integer: "a"`.

## 2. Bốn phép và hai biến thể
Giả sử `A = {1,1,2}` và `B = {1,3}`:

| Phép | Ý nghĩa | Kết quả với A, B |
|---|---|---|
| `A UNION B` | gộp, **bỏ trùng** | `1, 2, 3` |
| `A UNION ALL B` | gộp, **giữ trùng** | `1, 1, 1, 2, 3` |
| `A INTERSECT B` | có ở **cả hai** | `1` |
| `A EXCEPT B` | có ở A **mà không có ở B** | `2` |
| `A EXCEPT ALL B` | trừ theo **số lần** xuất hiện | `1, 2` |
| `A INTERSECT ALL B` | lấy **số lần nhỏ hơn** | `1` |

- `UNION`, `INTERSECT`, `EXCEPT` (không `ALL`) **luôn bỏ trùng cả kết quả**, kể cả trùng trong nội bộ một vế.
- `EXCEPT` **không đối xứng**: `A EXCEPT B` ≠ `B EXCEPT A`.
- Muốn biết hai tập khác nhau thế nào ở cả hai phía, ghép hai chiều: `(A EXCEPT B) UNION ALL (B EXCEPT A)`. Đây chính là cách file `checks` chấm bài của bạn.

## 3. `UNION` vs `UNION ALL`: đúng và nhanh
```sql
SELECT kind, count(*) FROM (
  SELECT user_id, created_at::date, 'order' AS kind FROM orders
  UNION                         -- bỏ trùng (user, ngày, kind)
  SELECT user_id, created_at::date, 'event' FROM events WHERE user_id IS NOT NULL
) t GROUP BY kind;
-- event 6866 · order 9250     ← thiếu hàng chục nghìn dòng
-- đổi thành UNION ALL: event 22597 · order 10000
```
- `UNION` phải **sort hoặc hash toàn bộ kết quả** để bỏ trùng. Tốn thời gian và bộ nhớ, và có thể tràn ra đĩa khi dữ liệu lớn (nhớ `work_mem`).
- **Quy tắc:** nếu bạn *biết* hai vế không trùng nhau (hoặc *muốn* giữ trùng, ví dụ để đếm), dùng `UNION ALL`. Chỉ dùng `UNION` khi thật sự cần bỏ trùng.
- Dùng `UNION` "cho chắc" là lỗi hay gặp: nó vừa **sai** khi cần đếm, vừa **chậm** khi dữ liệu lớn.

## 4. `ORDER BY` và `LIMIT`: viết ở đâu?
- `ORDER BY` / `LIMIT` ở **cuối cùng** áp dụng cho **toàn bộ kết quả** đã ghép. Cột sắp xếp phải là tên cột của kết quả (tức tên từ vế đầu).
- Muốn `ORDER BY`/`LIMIT` cho **từng vế**, phải bọc vế đó trong **ngoặc**:
```sql
select id from users order by id desc limit 2 union all select id from users order by id limit 2;
-- ERROR: syntax error at or near "union"

(select id from users order by id desc limit 2)
union all
(select id from users order by id limit 2);          -- 1000, 999, 1, 2
```

## 5. Thứ tự ưu tiên
`INTERSECT` ưu tiên cao hơn `UNION` và `EXCEPT`. `UNION` và `EXCEPT` cùng cấp, tính từ trái sang phải.
```sql
select 1 union select 2 intersect select 2;        -- {1, 2}   vì chạy 2 INTERSECT 2 = {2} trước, rồi UNION với 1
(select 1 union select 2) intersect select 2;       -- {2}      khác hẳn
```
Khi trộn nhiều phép, **luôn thêm ngoặc** cho rõ, dù không bắt buộc.

## 6. NULL trong set operation
Các phép tập hợp so sánh dòng bằng kiểu **"không phân biệt" (not distinct)**: `NULL` được coi là **bằng** `NULL`.
```sql
select x from (values (null),(null),(1)) v(x) union select null;   -- 2 dòng: 1 và NULL (các NULL gộp làm một)
select count(*) from (values (null),(null)) a(x) join (values (null)) b(x) on a.x = b.x;   -- 0: JOIN dùng =, NULL = NULL ra NULL
select count(*) from (select x from (values (null::int),(null)) a(x)
                      intersect select x from (values (null::int)) b(x)) t;                 -- 1: INTERSECT coi NULL bằng NULL
```
- Đây là điểm **khác** `JOIN`/`IN`/`=`. Rất hữu ích khi so sánh hai bảng có cột NULL: `EXCEPT` không báo nhầm dòng NULL là "khác".
- Nhưng cũng nghĩa là `UNION` **gộp mọi NULL thành một dòng**. Khi đếm, nhớ `count(*)` đếm dòng NULL còn `count(col)` thì không (F03).

## 7. Khi nào dùng cái nào?
| Câu hỏi | Dùng | Vì sao |
|---|---|---|
| Ghép danh sách từ 2 nguồn | `UNION ALL` (hoặc `UNION` nếu cần bỏ trùng) | |
| "Có ở **cả hai** tập" | `INTERSECT` | Gọn hơn `JOIN` + `DISTINCT` hay `IN` khi chỉ cần **khóa** |
| "Có ở A mà **không có** ở B" | `EXCEPT` hoặc `NOT EXISTS` | `EXCEPT` gọn, nhưng chỉ trả về **các cột đã chọn**, không kèm cột khác |
| So hai bản dữ liệu (snapshot, export) | `EXCEPT ALL` hai chiều | Phát hiện cả dòng **bị nhân đôi**, và NULL không gây nhiễu |
| Cần thêm **cột** từ bảng kia | `JOIN` | Set operation không đưa cột ra ngoài được |

## Bẫy hay gặp

| # | Sai | Đúng | Vì sao |
|---|---|---|---|
| 1 | `UNION` khi muốn đếm hoặc cộng dồn | `UNION ALL` | `UNION` bỏ trùng nên số đếm hụt |
| 2 | Hai vế khác thứ tự cột: `SELECT id, name … UNION SELECT name, id …` | Cùng thứ tự cột | Ghép theo vị trí, không theo tên |
| 3 | `… ORDER BY x LIMIT 5 UNION ALL …` | Bọc từng vế trong ngoặc | `ORDER BY`/`LIMIT` chỉ hợp lệ ở cuối trừ khi có ngoặc |
| 4 | `A UNION B INTERSECT C` rồi hiểu từ trái sang phải | Thêm ngoặc | `INTERSECT` chạy trước |
| 5 | Nghĩ `A EXCEPT B` đối xứng | Ghép hai chiều | Chỉ lấy dòng có ở A |
| 6 | So hai bảng bằng `EXCEPT` (không `ALL`) khi có dòng trùng | `EXCEPT ALL` | Bản set bỏ qua khác biệt về **số lần** xuất hiện |

## Postgres-specific
- Postgres hỗ trợ đầy đủ `INTERSECT ALL` và `EXCEPT ALL`. MySQL mới có từ 8.0.31, SQL Server không có bản `ALL`.
- `UNION` (bỏ trùng) trong `EXPLAIN` thường là `HashAggregate` hoặc `Unique` trên `Sort`, còn `UNION ALL` là `Append`. Ở Tier P bạn sẽ đo chênh lệch này.
