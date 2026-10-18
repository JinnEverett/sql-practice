---
name: sql-drill
description: |
  Luyện nhanh 10–15 phút: câu hỏi ngắn kiểu flashcard và viết query nhỏ, ưu tiên điểm yếu trong weaknesses.md và các module đến hạn ôn. Có chế độ phỏng vấn.
  Triggers: /sql-drill, "ôn nhanh", "drill", "kiểm tra nhanh", "luyện phỏng vấn sql", "quiz sql"
---

# SQL Drill: luyện nhanh và ôn tập

## Chế độ (theo args, mặc định `review`)
| Mode | Nội dung |
|---|---|
| `review` | Ôn điểm yếu và module đến hạn. Đây là chế độ mặc định |
| `topic <ID/chủ đề>` | Drill riêng một chủ đề |
| `interview` | Mô phỏng phỏng vấn: 5–6 câu, xen lý thuyết với live query, có chấm điểm |
| `predict` | Cho trước query và dữ liệu, người học đoán output hoặc đoán plan EXPLAIN mà không chạy |
| `scale` | Cho trước query và bảng bench ở `s`, người học đoán số đo ở `m` và `l` (thời gian, plan, có spill không), sau đó chạy `bench` để chấm. Chấm đúng/sai theo xu hướng và điểm gãy, không đòi đúng con số |

## Chọn câu hỏi (mode review)
1. Đọc `progress/weaknesses.md`, ưu tiên dòng có `count` cao và lâu chưa ôn.
2. Đọc `progress/tracker.md`, lấy các module ✅ có "Ôn lại lúc" ≤ hôm nay.
3. Ra tổng cộng 8–10 câu, trộn 4 dạng:
   - **Đoán output**: 3–5 dòng dữ liệu kèm 1 query. Kết quả là gì?
   - **Tìm lỗi**: một query có bug. Chỉ ra bug.
   - **Viết nhanh**: một yêu cầu nhỏ, viết query ≤ 5 dòng.
   - **Khái niệm**: một câu hỏi ngắn kiểu "khi nào dùng BRIN?", "READ COMMITTED có ngăn được lost update không?"

## Luật chơi
- Mỗi lượt 1 câu. Chờ người học trả lời rồi mới chấm, sau đó mới ra câu tiếp.
- Chấm ngay: ✅ hoặc ❌ kèm giải thích 1–2 câu. Với câu viết query, chạy thật để kiểm chứng.
- Không dùng hint trong drill. Trả lời sai thì giải thích luôn, vì mục tiêu của drill là ôn lại.
- Lưu bản ghi buổi vào `drills/<YYYY-MM-DD>.md` (nếu trong ngày có nhiều buổi thì thêm hậu tố `-2`, `-3`…), gồm câu hỏi, câu trả lời của người học và kết quả.

## Cập nhật sau drill
- `weaknesses.md`: trả lời đúng thì tăng "Streak đúng", sai thì reset về 0 và tăng `count`. Dòng nào đạt streak 3 thì chuyển xuống mục "Đã khắc phục".
- `tracker.md`: module được ôn đạt (≥ 80%) thì nhảy sang mốc ôn tiếp theo. Không đạt thì đổi sang 🔁.
- Tóm tắt 2 dòng: điểm số và câu cần nhớ nhất.
