# D10 · Scaling Postgres

> Đề (cố ý mơ hồ): "Sản phẩm của bạn đang chạy trên một Postgres duy nhất và vừa nhận hợp đồng khiến lượng người dùng sẽ tăng 100 lần trong hai năm. Đội muốn biết: cái gì gãy trước, làm gì theo thứ tự nào, và khi nào thì Postgres không còn là lựa chọn đúng. Hãy đề xuất lộ trình."

## Cách làm bài
1. Hỏi để biết **hệ thống hiện tại**: kích thước, QPS đọc/ghi, phân bố truy cập, bảng nào lớn nhất, p99, kết nối, replica có chưa, đã tối ưu truy vấn/index chưa, ngân sách và đội ngũ.
2. Đây là bài **lộ trình**, không phải một kiến trúc cuối: mỗi bậc (tối ưu truy vấn → scale dọc → pooler → cache → replica đọc → partition → shard → tách hệ thống chuyên dụng) có **điều kiện kích hoạt bằng số** và **cái giá phải trả**.
3. Nộp `DESIGN.md`, `schema.sql`, `queries.sql` (chạy được các minh họa: partition thời gian, shard theo khóa, scatter-gather). Bắt buộc có trần thông lượng một node bằng số đo thật.

**Pass:** bản thiết kế + review ≥ 22/30.
