---
name: sql-case
description: |
  Bài tình huống thực tế mô phỏng công việc thật với Postgres: query chậm trên production, deadlock, oversell tồn kho, migration không downtime, báo cáo nghiệp vụ mơ hồ, sự cố bloat/replication lag. Người học điều tra và xử lý như kỹ sư trực sự cố.
  Triggers: /sql-case, "bài thực tế", "tình huống", "case study", "debug production", "incident"
---

# SQL Case: tình huống thực tế

Khác với lesson: đề **không nói trước** cần dùng kỹ thuật gì. Người học phải tự chẩn đoán.
Chọn case theo các module người học đã ✅. Case có thể vượt tối đa 1 tier để tạo độ khó, nhưng không vượt hơn.

## Kho dạng case (chọn hoặc biến tấu)
| Nhóm | Ví dụ tình huống | Module liên quan |
|---|---|---|
| 📊 Báo cáo nghiệp vụ | Sếp muốn "doanh thu thực theo tuần": đề mơ hồ, người học phải hỏi lại để làm rõ (hoàn tiền? time zone? đơn hủy?) | F*, I*, R07 |
| 🐢 Query chậm | API `/orders` mất 4s sau khi data tăng gấp 10. Cho slow log và schema, hãy tìm và sửa | P02–P05, P09 |
| 📈 Tăng trưởng | "Ở staging (`shop_s`) chạy ngon, lên production (`shop_l`) thì sập." Tìm query, job hay migration không chịu được quy mô; đưa ra bằng chứng bằng `bench` trên nhiều mức | P10, R10, R12 |
| 🔒 Concurrency | Flash sale bị bán vượt tồn kho, hoặc 2 người đặt cùng một ghế | P06, P08, R08 |
| 💀 Deadlock / lock | Deploy ALTER TABLE làm treo cả hệ thống. Cần tái hiện bằng 2–3 session | P08, R10 |
| 🧹 Dữ liệu bẩn | Bảng users có email trùng (khác hoa thường, thừa khoảng trắng). Dọn dẹp rồi thêm ràng buộc mà không mất dữ liệu | F08, R03 |
| 🏗️ Migration | Đổi kiểu cột `int → bigint` trên bảng 50M dòng, hoặc tách một bảng làm hai, mà không downtime | R10 |
| 📈 Vận hành | Disk tăng đột biến (bloat), autovacuum không chạy kịp, replica lag, connection bị cạn | P07, O03–O06 |
| 🔐 Bảo mật | Tenant A xem được dữ liệu của tenant B. Audit lại và bịt lỗ hổng | O01, R09 |

## Cấu trúc thư mục
```
cases/<NN>-<slug>/
  BRIEF.md        # bối cảnh dạng ticket/incident: triệu chứng, số liệu, áp lực thời gian
  setup.sql       # dựng hiện trường: schema, data, bug đã cài sẵn (có thể kèm script tạo tải)
  notes.md        # người học ghi lại quá trình điều tra
  solution.sql    # cách xử lý của người học
  postmortem.md   # Claude viết sau khi xong: root cause, cách sửa, cách phòng ngừa, các cách làm khác
```

## Diễn biến
1. **Brief**: viết như ticket thật, có triệu chứng, chưa có nguyên nhân. Có thể kèm log, output `pg_stat_activity` hay EXPLAIN.
2. **Điều tra**: người học đặt câu hỏi hoặc chạy query chẩn đoán. Claude đóng vai đồng nghiệp hoặc hệ thống: trả lời trung thực về những gì quan sát được và không tiết lộ root cause.
3. **Tái hiện** (với case concurrency/lock): hướng dẫn mở 2 session psql song song (2 terminal, hoặc dùng `\! ` kết hợp `pg_sleep` để dàn kịch bản), sao cho người học thấy tận mắt.
4. **Xử lý**: người học viết `solution.sql`. Chạy lại kịch bản để xác nhận lỗi đã hết. Nếu là case hiệu năng: đo trước/sau bằng `bench` trên ít nhất 2 mức quy mô, và lưu bảng kết quả vào thư mục case.
5. **Postmortem**: viết `postmortem.md` theo khung root cause → fix → phòng ngừa (constraint, monitoring, review checklist) → các phương án khác và trade-off.
6. Cập nhật tracker (ghi vào nhật ký với tag `case`) và weaknesses.

Chấm theo 4 tiêu chí, thang 1–5 mỗi tiêu chí: quy trình chẩn đoán có hệ thống không, root cause đúng không, fix có an toàn với production không (lock, downtime, rollback), và có phòng ngừa tái diễn không.
