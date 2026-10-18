# D07 · Chat

> Đề (cố ý mơ hồ): "App nhắn tin cho doanh nghiệp: chat 1-1 và nhóm. Người dùng thấy số tin chưa đọc, cuộn lên xem lịch sử vô hạn, và tin không bao giờ bị mất hay đảo thứ tự. Thiết kế phần database."

## Cách làm bài
1. Hỏi để chốt: quy mô (người dùng, tin/ngày, nhóm lớn nhất), thứ tự tin có cần toàn phần trong hội thoại không, online/real-time đi đường nào (DB có phải kênh đẩy?), xóa/sửa tin, retention, tìm kiếm.
2. Trọng tâm: **mô hình lưu tin nhắn** (một bản hay mỗi người một bản), **unread count**, **thứ tự & idempotency khi gửi**, **phân trang lịch sử**.
3. Nộp `DESIGN.md`, `schema.sql`, `queries.sql`. Bắt buộc có số đo: chi phí tính unread và thông lượng gửi vào một hội thoại.

**Pass:** bản thiết kế + review ≥ 22/30.
