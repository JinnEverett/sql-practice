# D06 · Social feed

> Đề (cố ý mơ hồ): "Mạng xã hội cho người dùng theo dõi nhau. Trang chủ hiện bài mới của những người mình theo dõi, mỗi bài có lượt thích. Có vài tài khoản rất nổi tiếng. Thiết kế phần database."

## Cách làm bài
1. Hỏi để chốt: quy mô (DAU, bài/ngày, follower trung bình **và lớn nhất**), feed xếp theo thời gian hay xếp hạng, độ tươi chấp nhận được, đăng bài cho celebrity nhận bao nhiêu follower, unfollow/xóa bài, đếm like chính xác đến mức nào.
2. Trọng tâm: **fan-out on write vs on read vs hybrid**, **write amplification**, **hot row/counter**, **keyset pagination**.
3. Nộp `DESIGN.md`, `schema.sql`, `queries.sql`. Bắt buộc có số đo: chi phí đọc feed (pull vs push) và thí nghiệm counter nóng.

**Pass:** bản thiết kế + review ≥ 22/30.
