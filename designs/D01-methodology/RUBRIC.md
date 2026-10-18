# D01 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Không hỏi, tự giả định | Hỏi phạm vi nhưng thiếu số non-functional | Chốt ai vote/đổi ý/"hot"/độ trễ chấp nhận được/retention bằng số |
| Data model | Thiếu PK tổng hợp hoặc cho phép vote đôi | Có UNIQUE (post,user) nhưng thiếu CHECK/FK | PK `(post_id,user_id)`, CHECK value, FK + ON DELETE có chủ đích, giải thích `score` denormalized |
| Index & query | Không index hoặc index thừa | Đủ index nhưng không dẫn chứng EXPLAIN | Mỗi access pattern A1–A4 có index/đường đi + đọc được plan (Index Scan vs Bitmap, Buffers) |
| Consistency & concurrency | Không nói tới race | Biết dùng transaction, chưa xử lý idempotency/hot row | Upsert idempotent, delta trong cùng transaction, nêu hot row + hướng giảm (batch/shard counter) |
| Scale & vận hành | Không ước lượng | Có QPS nhưng không có dung lượng/năm | Ước lượng có công thức, đối chiếu bytes/dòng thực đo, lộ trình x10/x100 + đối soát score |
| Trade-off | Một phương án | Nêu 2 phương án, lý do mỏng | Ít nhất 2 phương án cho `score` (tính khi đọc / denormalize / cache), so sánh có số |

**Điểm trừ nặng (−3 ở tiêu chí liên quan):** để app đọc-rồi-ghi score (`SELECT score` rồi `UPDATE score = <số tính ở app>`) → lost update.

## 3 điểm mạnh / 3 lỗ hổng (để review.md)
Review phải liệt kê đúng 3 + 3, kèm "cách hệ thống thật làm": Reddit/HN giữ điểm denormalized + xếp hạng tính theo công thức thời gian, vote ghi qua queue/cache trước khi đổ về DB.
