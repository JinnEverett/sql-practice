# D01 · Interviewer (⚠️ spoiler: người học không đọc trước khi làm)

Vai trò: hỏi ngược, không đưa thiết kế. Mỗi bước hỏi 1–3 câu rồi mới cho đi tiếp.

## Thông tin chỉ đưa khi được hỏi
| Người học hỏi | Trả lời |
|---|---|
| Quy mô | 50k user, 5k bài mới/ngày, trung bình 40 vote/bài trong 24h đầu, đỉnh gấp 10 lần trung bình |
| Vote là gì | Up/down, mỗi người một phiếu/bài, được đổi ý hoặc rút phiếu |
| "Hot" | Điểm = up − down, chỉ xét bài 24h gần nhất, hiển thị 20 bài/trang |
| Consistency | Điểm trễ vài giây được; nhưng **không** được đếm thừa phiếu |
| Retention | Giữ vote vĩnh viễn (dùng cho gợi ý sau này) |
| Có xóa bài/user không | Xóa bài: xóa luôn vote. Xóa user: giữ vote ẩn danh (quyết định có kèm lý do là đạt) |

## Yêu cầu ngầm (người học đạt điểm cao nếu tự phát hiện)
1. **Idempotency**: client retry / double-click không được cộng điểm hai lần.
2. **Một người một phiếu** phải do DB bảo vệ (PK/UNIQUE), không phải app.
3. **Hot row**: bài viral nhận nhiều vote đồng thời → mọi vote cùng UPDATE một dòng `posts`.
4. **Denormalized `score`** có thể lệch → cần đường đối soát.

## Câu hỏi phản biện theo bước
**B1 Requirements**
- "Một người vote rồi gỡ vote thì dữ liệu còn không? Lịch sử có cần?"
- "'Hot' tính theo thời gian thế nào, bài cũ có lên được không?"
- "Nếu hệ thống chậm 5 giây, người dùng thấy gì chấp nhận được?"

**B2 Access patterns**
- "Liệt kê top 4 query theo tần suất. Cái nào đọc, cái nào ghi? Tỉ lệ đọc/ghi?"
- "Trang bài có cần biết *tôi* đã vote gì không? Query đó trông ra sao?"

**B3 Ước lượng**
- "5k bài × 40 vote = bao nhiêu vote/ngày? QPS trung bình và đỉnh? Một năm bảng `votes` bao nhiêu dòng, bao nhiêu GB?" (kỳ vọng: ~200k vote/ngày ≈ 2.3 QPS trung bình, đỉnh ~25 QPS; ~73M dòng/năm)
- "Con số đó có làm Postgres đơn lẻ toát mồ hôi không?"

**B4 Data model**
- "Khóa chính `votes` là gì? Vì sao không dùng `id` serial?"
- "`value` lưu thế nào, chặn giá trị 5 ở đâu?"
- "Có lưu `score` trong `posts` không? Nếu có, ai giữ cho nó đúng?"

**B5 Index & query**
- "Query top 24h chạy ra sao khi `posts` có 2 triệu dòng? Đọc bao nhiêu dòng để lấy 20?"
- "Hai vote cùng lúc cho cùng bài thì chuyện gì xảy ra ở mức dòng?"

**B6 Kiến trúc**
- "Có cần cache trang chủ không? Hết hạn thế nào?"
- "Vote đi qua queue hay ghi thẳng? Mất gì, được gì?"

**B7 Bottleneck**
- "Bài viral nhận 2k vote/giây: hot row nằm ở đâu? Cách giảm?"
- "x10 người dùng thì thứ gì gãy đầu tiên?"
- "`score` lệch thì phát hiện bằng cách nào?"

## Dấu hiệu đỏ
- Vẽ bảng trước khi hỏi gì. Tính `score` bằng `count(*)` mỗi lần load trang mà không bàn tới chi phí. Không nhắc idempotency.
