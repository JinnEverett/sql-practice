# D08 · Multi-tenant SaaS

> Đề (cố ý mơ hồ): "Công cụ quản lý công việc bán cho doanh nghiệp (mỗi doanh nghiệp là một tenant). Có hàng nghìn tenant nhỏ và vài khách hàng enterprise rất lớn. Dữ liệu của tenant này tuyệt đối không được lộ cho tenant khác. Thiết kế phần database."

## Cách làm bài
1. Hỏi để chốt: số tenant và phân phối kích thước, mức cách ly yêu cầu (hợp đồng, compliance, vị trí dữ liệu), tenant lớn cần SLA riêng không, xóa/xuất dữ liệu tenant, tần suất migration schema, cách ứng dụng kết nối (pooler).
2. Trọng tâm: **chọn mô hình cách ly** (database / schema / bảng chung + RLS), **noisy neighbor**, **di chuyển và xóa tenant lớn**, **plan lệch do dữ liệu lệch**.
3. Nộp `DESIGN.md`, `schema.sql`, `queries.sql`. Bắt buộc có số đo: ảnh hưởng của một tenant lớn lên tenant nhỏ, và chi phí xóa/migrate.

**Pass:** bản thiết kế + review ≥ 22/30.
