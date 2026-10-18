# D06 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Chỉ "feed + like" | Có quy mô trung bình | + phân phối follower (celebrity), độ tươi, unfollow/xóa, độ chính xác counter, retention hộp thư |
| Data model | `follows` không PK/index một chiều | PK + index hai chiều | + `feed_items` không FK có chủ đích, `is_celebrity`, `likes` PK (post,user), counter chia mảnh |
| Index & query | Pull `IN (…)` không đọc plan | Có cả push và pull | Đọc plan, so buffers pull vs push theo số followings, keyset pagination (post id < cursor) |
| Consistency & concurrency | Không bàn race | Idempotent like | Fan-out idempotent (ON CONFLICT), like idempotent, counter chia mảnh + đối soát; **có thí nghiệm** hot row |
| Scale & vận hành | Không bàn write amplification | Có số dòng/ngày | Write amp theo celebrity, hộp thư chỉ cho user hoạt động + giữ 7 ngày, fan-out qua queue, shard theo user_id |
| Trade-off | Chọn 1 mô hình | So sánh push/pull | So sánh push / pull / hybrid với số liệu, nêu ngưỡng và chi phí chuyển đổi |

**Trừ nặng:** fan-out đồng bộ cho mọi tác giả không ngưỡng (−3 Scale); `OFFSET` (−1 Index & query).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: Twitter timeline = hybrid (push cho đa số, pull cho celebrity), hộp thư giữ ~800 bài trong Redis; Instagram/Facebook xếp hạng bằng ML trên tập ứng viên.
