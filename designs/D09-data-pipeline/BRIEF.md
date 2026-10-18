# D09 · Data pipeline: OLTP → phân tích

> Đề (cố ý mơ hồ): "Hệ thống bán hàng đang chạy trên Postgres. Bộ phận kinh doanh muốn dashboard doanh thu gần-real-time theo ngày và ngành hàng, và các đội khác (kho, email) muốn phản ứng khi có đơn mới. Đừng làm chậm việc đặt hàng. Thiết kế đường dữ liệu."

## Cách làm bài
1. Hỏi để chốt: độ tươi dashboard (giây? phút? giờ?), khối lượng sự kiện, ai tiêu thụ sự kiện và họ chịu được trùng/trễ/sai thứ tự đến mức nào, giữ lịch sử bao lâu, múi giờ báo cáo, sửa/hủy đơn có đảo ngược số liệu không.
2. Trọng tâm: **tách OLTP khỏi OLAP**, **outbox** (tránh dual write), **CDC** (logical decoding) và chi phí vận hành của nó, **consumer idempotent**, **tổng hợp tăng dần vs làm mới toàn bộ**, **ngày nghiệp vụ & múi giờ**.
3. Nộp `DESIGN.md`, `schema.sql`, `queries.sql`. Bắt buộc có số đo: chi phí truy vấn phân tích trên bảng gốc vs bảng tổng hợp, và một thí nghiệm về sự kiện bị mất/trùng.

**Pass:** bản thiết kế + review ≥ 22/30.
