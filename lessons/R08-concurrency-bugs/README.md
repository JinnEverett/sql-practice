# R08 · Concurrency bugs

Đọc khoảng 10 phút. Mọi bài chạy trên DB `lab`, schema `r08`. Cần P06 (transaction, isolation), P08 (lock, deadlock); nếu chưa học thì phần 1–2 dưới đây đủ để bắt đầu.

## Mục tiêu: sau buổi này bạn làm được
- Tái hiện được **lost update**, **oversell**, **double booking**, **write skew**, **deadlock** bằng hai (hoặc nhiều) session.
- Sửa từng lỗi bằng đúng công cụ: UPDATE nguyên tử, `SELECT … FOR UPDATE`, optimistic locking, exclusion constraint, khóa theo thứ tự, `SERIALIZABLE` + retry.
- Nhận ra mẫu code nguy hiểm "đọc → quyết định ở ứng dụng → ghi" (check-then-act).
- Đo tác hại của tranh chấp trên một dòng nóng.

---

## 1. Mặc định của Postgres: `READ COMMITTED`
Mỗi **câu lệnh** thấy snapshot của các giao dịch đã commit *tại lúc câu lệnh bắt đầu*. Khoảng hở nằm giữa hai câu: đọc ở câu 1, ghi ở câu 2, và ở giữa người khác có thể đã đổi dữ liệu mà bạn dùng để quyết định. Khi một `UPDATE`/`DELETE`/`SELECT FOR UPDATE` gặp dòng đang bị giao dịch khác khóa, nó **chờ**, rồi sau khi bên kia commit nó đọc lại phiên bản dòng mới nhất và kiểm tra lại điều kiện `WHERE` (EvalPlanQual). Đây là nền tảng của các cách sửa an toàn bên dưới.

## 2. Bộ công cụ sửa lỗi
| Lỗi | Hiện tượng | Cách sửa chính | Cách khác |
|---|---|---|---|
| **Lost update** | hai người đọc cùng giá trị, cùng ghi đè | UPDATE nguyên tử `SET n = n + 1` (ex01) | `FOR UPDATE`; optimistic locking (ex03) |
| **Oversell** | hai request cùng thấy còn hàng | `UPDATE … WHERE stock >= qty` rồi kiểm `FOUND` (ex02) | `SELECT … FOR UPDATE` rồi trừ |
| **Double booking** | hai đặt chỗ chồng giờ | `EXCLUDE USING gist` (ex04) | advisory lock (kém gọn) |
| **Write skew** | hai người sửa dòng KHÁC nhau dựa trên một điều kiện đọc chung | khóa cả tập đã đọc (`FOR UPDATE` mọi dòng liên quan, advisory lock) (ex05) | `SERIALIZABLE` + retry 40001 (ex07) |
| **Deadlock** | vòng chờ khóa | khóa theo **thứ tự cố định** (ex06) | `lock_timeout`, retry khi gặp 40P01 |
| **Hot row** | mọi giao dịch xếp hàng trên một dòng | phân mảnh, append-only + cộng nền (ex08) | giảm thời gian giữ khóa |

## 3. Optimistic và pessimistic
- **Pessimistic:** khóa trước (`SELECT … FOR UPDATE`), làm việc, commit. Đúng khi xung đột thường xuyên và giao dịch ngắn. Giữ khóa trong lúc chờ người dùng (form) là sai: khóa nằm theo transaction.
- **Optimistic:** không khóa, mỗi dòng có `version`; ghi bằng `UPDATE … WHERE id = ? AND version = ?` rồi kiểm số dòng bị sửa. 0 dòng = có người sửa trước, đọc lại và thử lại/hỏi người dùng. Đúng khi xung đột hiếm hoặc "đọc → người dùng sửa → ghi" kéo dài (ex03).

## 4. Chi tiết quan trọng
- **Mô phỏng 2 session:** các bài chấm dùng `dblink` (một session chính + một hay nhiều session nền, đều kết nối `postgres`). Kỹ thuật chung: session A mở `BEGIN`, gọi hàm của bạn, rồi giữ transaction mở (`pg_sleep`) trước khi `COMMIT`; session B chạy cùng hàm trong lúc đó. Nếu code của bạn "đọc rồi ghi" thì B thấy dữ liệu cũ và lỗi lộ ra.
- **`FOUND`** (plpgsql) là true nếu câu lệnh vừa chạy tác động ≥ 1 dòng: cách ngắn nhất để biết UPDATE điều kiện có thành công không. `GET DIAGNOSTICS n = ROW_COUNT` cho số dòng.
- **Ràng buộc là lớp phòng thủ cuối:** `CHECK (stock >= 0)` chặn tồn kho âm dù code sai, nhưng đừng dùng nó làm logic bình thường (đổi lỗi thành exception, mất giao dịch). Dùng điều kiện trong `WHERE` để từ chối nhẹ nhàng.
- **Deadlock:** Postgres phát hiện sau `deadlock_timeout` (mặc định 1 giây) và hủy một giao dịch với `40P01`; luôn có thể xảy ra ở mức nhỏ, nên ứng dụng vẫn cần retry cho `40P01` và `40001`.
- **Retry:** chỉ retry **cả giao dịch** từ đầu, giới hạn số lần, kèm backoff ngẫu nhiên; thao tác phải idempotent (R03).

## Bẫy hay gặp
1. `SELECT` kiểm tra rồi `UPDATE` ở hai câu lệnh (check-then-act).
2. Tính toán giá trị mới ở ứng dụng rồi ghi `SET n = <số>` thay vì `SET n = n + 1`.
3. Khóa không đủ rộng: chỉ khóa dòng của mình trong khi điều kiện liên quan cả tập.
4. Hai đường code khóa các tài nguyên theo thứ tự khác nhau.
5. Giữ giao dịch mở lâu (chờ người dùng, gọi API ngoài).
6. Kiểm thử một session duy nhất: lỗi đồng thời không bao giờ xuất hiện.

## Postgres-specific
- `EXCLUDE` constraint + range type + `btree_gist`: giải bài đặt chỗ ở tầng database, không cần khóa thủ công.
- `SELECT … FOR UPDATE SKIP LOCKED / NOWAIT` (R04), advisory lock (`pg_advisory_xact_lock`), `SERIALIZABLE` dùng SSI (không chặn người đọc).
