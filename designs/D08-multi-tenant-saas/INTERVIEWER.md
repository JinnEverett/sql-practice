# D08 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Quy mô | 20k tenant; 95% < 1 000 task; 10 tenant enterprise mỗi tenant 50–200M task; tổng ~1 tỉ task |
| Cách ly | Hợp đồng cấm lộ dữ liệu giữa tenant; một vài tenant enterprise yêu cầu "dữ liệu tách riêng" (có thể trả thêm tiền) |
| SLA | Tenant nhỏ: p99 < 200 ms. Enterprise: SLA riêng, báo cáo nặng chạy nền |
| Xóa | Khách hủy hợp đồng: xóa toàn bộ dữ liệu trong 30 ngày; có thể xuất toàn bộ dữ liệu trước đó |
| Migration | Đổi schema mỗi 2 tuần, không downtime |
| Kết nối | App có pooler (transaction pooling); ~2000 connection ứng dụng |
| Truy cập | Chỉ qua API của ta; một số enterprise muốn kết nối BI trực tiếp (read-only) |

## Yêu cầu ngầm
1. **Cách ly ở DB** (RLS + FK ghép), không phó mặc cho `WHERE tenant_id` của lập trình viên.
2. **Fail closed**: quên đặt tenant ⇒ không thấy gì chứ không thấy tất cả.
3. **Rò tenant qua connection pooling**: biến phiên `SET` không `LOCAL` nằm lại connection.
4. **Role của app không được là owner/superuser/BYPASSRLS**; FORCE RLS.
5. **Noisy neighbor**: CPU/IO bị một tenant lớn chiếm; statement_timeout, pool riêng, replica báo cáo.
6. **Dữ liệu lệch** làm kế hoạch lệch (tenant nhỏ vs lớn cùng câu lệnh).
7. **Xóa/di chuyển** tenant lớn không bằng DELETE hàng trăm triệu dòng.
8. **Ràng buộc tham chiếu chéo tenant**: FK ghép `(tenant_id, parent_id)`.

## Câu hỏi phản biện
**B1** "Database riêng, schema riêng, hay bảng chung? Mỗi lựa chọn gãy ở 20k tenant ở đâu?" · "Khách enterprise yêu cầu dữ liệu tách riêng: phục vụ thế nào mà không viết lại ứng dụng?"
**B2** "Query nào của tenant nhỏ nóng nhất? Query nào của tenant lớn nguy hiểm nhất cho người khác?"
**B3** "1 tỉ dòng × bytes/dòng = ? 20k schema × số bảng × số index = bao nhiêu relation trong catalog? Migration 'thêm cột' chạy bao nhiêu lệnh?" (≈ 170 B/dòng đo ⇒ ~170 GB; 20k × 8 relation = 160k relation)
**B4** "Khóa chính và khóa ngoại có `tenant_id` không? Task có thể trỏ vào project của tenant khác không, và ai chặn?" · "Cột `tenant_id` đứng đâu trong index và vì sao?"
**B5** "Truy vấn `WHERE tenant_id = $1` cho tenant nhỏ và tenant 200M dòng dùng cùng plan được không? Prepared statement/generic plan thì sao?" · "RLS có làm index mất tác dụng không? Đọc plan."
**B6** "Dev quên `SET app.tenant_id` thì sao? Transaction pooling thì `SET` ở đâu?" · "Báo cáo nặng của tenant lớn chạy ở đâu? Làm sao chúng không giết tenant nhỏ?" · "Một tenant lớn đòi máy riêng: chuyển thế nào, downtime bao nhiêu?"
**B7** "Xóa tenant 200M dòng: DELETE chạy bao lâu, bloat bao nhiêu, vacuum? Phương án khác?" · "Migration 20k schema: bao lâu? Fail giữa chừng thì sao?" · "x10 tenant thì thứ gì gãy trước?"

## Dấu hiệu đỏ
Chỉ dựa vào `WHERE tenant_id = ?` trong ORM · app kết nối bằng superuser/owner (bỏ qua RLS) · `SET app.tenant_id` cấp phiên sau pooler · FK không có tenant_id · schema-per-tenant cho 20k tenant mà không nói catalog/migration · DELETE tenant bằng một câu lệnh không bàn bloat.
