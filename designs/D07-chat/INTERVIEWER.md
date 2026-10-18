# D07 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Quy mô | 2M user, 500k DAU; 50M tin/ngày (≈ 580/s TB, ~5k/s đỉnh); trung bình 30 hội thoại/user, power user 800+ |
| Nhóm | Tối đa 1000 thành viên; 99% nhóm < 20 người |
| Thứ tự | Trong một hội thoại, mọi người thấy cùng một thứ tự |
| Real-time | Đẩy qua WebSocket gateway; Postgres là nguồn sự thật, không phải kênh đẩy |
| Gửi lại | Mạng di động hay rớt: client gửi lại cùng tin nhiều lần |
| Xóa/sửa | Xóa tin của mình (hiện "tin đã bị xóa"); sửa tin trong 15 phút |
| Retention | Giữ vĩnh viễn; 95% truy vấn lịch sử chỉ động đến 30 ngày gần nhất |
| Tìm kiếm | Tìm trong hội thoại (giai đoạn 2) |

## Yêu cầu ngầm
1. **Một bản tin** cho cả nhóm. Mỗi người một bản (fan-out) là sai với nhóm 1000 người.
2. **Unread không đếm dòng**: `count(*)` messages lớn dần theo lịch sử.
3. **Thứ tự toàn phần trong hội thoại** (đồng hồ client/`created_at` không đủ): cần số thứ tự do server cấp.
4. **Idempotent gửi** (client_msg_id) và **mark_read đơn điệu**.
5. **Hot row theo hội thoại**: cái giá của số thứ tự liên tục.
6. **Tombstone** giữ chuỗi seq liên tục.
7. **Hash partition theo conversation_id** (hay theo thời gian?): truy vấn nóng luôn có `conversation_id`.

## Câu hỏi phản biện
**B1** "Hai người gửi cùng lúc: ai trước? Hai thiết bị của cùng một người?" · "Thế nào là 'đã đọc' với nhóm 1000 người: theo từng người hay đủ rồi?"
**B2** "Liệt kê: gửi tin, mở hội thoại, cuộn lên, danh sách hội thoại + badge, đánh dấu đã đọc. Cái nào nhiều nhất?"
**B3** "50M tin/ngày × bytes/dòng = ? GB/ngày, ? TB/năm. 5k/s đỉnh có vào được một primary không?" (≈ 177 B/tin đo ⇒ ~8.8 GB/ngày ⇒ ~3.2 TB/năm; 5k/s là khả thi nếu rải đều hội thoại)
**B4** "Khóa chính `messages`? Vì sao `(conversation_id, seq)` mà không `id` toàn cục?" · "Unread count lưu ở đâu để không phải đếm? Ghi gì khi 1 tin vào nhóm 1000 người?" (không ghi per-member)
**B5** "Phân trang cuộn lên: OFFSET? Keyset theo gì?" · "Badge tổng cho power user 800 hội thoại: query nào, bao nhiêu buffers?" · "Danh sách hội thoại sắp theo tin mới nhất thế nào?"
**B6** "Ai đẩy tin real-time? Nếu client chỉ dựa vào polling thì sao? Gateway nhận thông báo từ đâu (LISTEN/NOTIFY, queue)?" · "Partition thế nào cho 3 TB/năm, tin cũ để đâu?"
**B7** "Nhóm 1000 người ồn ào: hot row `last_seq` chịu bao nhiêu tin/s?" · "Mất thứ tự khi chuyển sang nhiều shard? (shard theo conversation_id: thứ tự giữ nguyên)" · "Tin bị xóa nhưng còn trong backup/log?"

## Dấu hiệu đỏ
Mỗi người một bản tin · `count(*)` để tính unread · thứ tự dựa trên `created_at` · `OFFSET` · không idempotent gửi · `mark_read` có thể lùi · dùng DB làm kênh push bằng polling dày.
