# D07 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Chỉ "gửi/nhận" | Có quy mô + nhóm | + thứ tự toàn phần, gửi lại, xóa/sửa, retention hot/cold, kênh real-time ngoài DB |
| Data model | Tin lưu per-recipient | `messages` + `members` | Một bản tin; `seq` theo hội thoại; PK `(conversation_id, seq)`; `client_msg_id` unique; tombstone |
| Index & query | OFFSET, count(*) unread | Keyset nhưng unread đếm dòng | Keyset theo seq (đọc plan ~5 buffers), unread = `last_seq - last_read_seq`, so sánh buffers hai cách |
| Consistency & concurrency | Thứ tự bằng `created_at` | Có sequence toàn cục | `last_seq` cấp trong cùng transaction; idempotent gửi; `mark_read` đơn điệu; **có thí nghiệm** gửi đồng thời không lỗ/không trùng seq |
| Scale & vận hành | Không ước lượng | Có tin/ngày | GB/ngày + TB/năm; hash partition; nóng/lạnh; hot hội thoại có số đo; shard theo conversation_id |
| Trade-off | Một mô hình | So sánh 2 | So sánh seq theo hội thoại / id toàn cục / snowflake; unread O(1) vs đếm; per-member receipts vs watermark |

**Trừ nặng:** per-recipient storage hoặc `count(*)` cho unread (−3 Data model/Index). Không đo hot hội thoại (−2 Consistency).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: Slack/Discord lưu tin theo (channel, id thời gian) và giữ read-state là watermark; Messenger/WhatsApp dùng seq per-thread; real-time đi qua gateway riêng.
