# D08 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Không hỏi phân phối tenant | Biết có tenant lớn | Có phân phối (95% nhỏ, top 10 khổng lồ), SLA khác nhau, xóa/xuất, migration tần suất, compliance |
| Data model | Thiếu `tenant_id` ở bảng con | `tenant_id` mọi bảng | `tenant_id` đứng đầu PK/index, FK ghép chặn chéo tenant, partition riêng cho tenant lớn |
| Index & query | Index không có `tenant_id` | Có nhưng không đọc plan | Đọc plan RLS (initplan, runtime pruning), nêu plan lệch tenant nhỏ/lớn, cách xử lý generic plan |
| Consistency & concurrency | Chỉ lọc ở app | Có RLS nhưng dùng owner/superuser | RLS + FORCE + role không bypass, fail closed, `SET LOCAL` với pooling, WITH CHECK; **có thí nghiệm** cách ly |
| Scale & vận hành | Không bàn noisy neighbor | statement_timeout hoặc replica | statement_timeout theo role, pool riêng, replica báo cáo, số đo ảnh hưởng; xóa/di chuyển tenant bằng partition, đo DELETE vs DROP; migration |
| Trade-off | Một mô hình | So sánh 2 | So sánh DB/schema/RLS bảng chung với số liệu (catalog, migration, lock table) và lộ trình lai: tenant lớn tách ra khi vượt ngưỡng |

**Trừ nặng:** app kết nối bằng role bỏ qua RLS mà vẫn tuyên bố cách ly (−3 Consistency); `SET` cấp phiên sau transaction pooling (−2).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: bảng chung + RLS cho đuôi dài tenant nhỏ, tenant lớn chuyển sang cluster/database riêng (lai); Citus/Postgres sharding theo tenant_id cho scale ngang.
