# Kế hoạch soạn nội dung SQL

Bảng trạng thái soạn bài (không phải tiến độ học — tiến độ học ở `progress/tracker.md`). Quy ước soạn xem `tools/AUTHORING.md`, brief cho cloud agent xem `tools/CLOUD_BRIEF.md`.
Trạng thái: ⬜ chưa soạn · 🟡 đang soạn · ✅ soạn xong (đủ README, exercises, hints, solutions) · 🧪 soạn xong và `bash tools/verify.sh` xanh.

| Tier | Module | Trạng thái | Ghi chú |
|---|---|---|---|
| S | S00 | ✅ | không có bài code |
| F | F01–F07 | ✅ | định dạng cũ (`checks/`), người học đã làm; không có `solutions/`/`hints.md` |
| F | F08–F10 | 🧪 | có từ trước |
| I | I01–I07 | 🧪 | có từ trước |
| I | I08 | 🟡 | có `solutions/` + `setup.sql`, **thiếu README, exercises, hints** → nhóm `o` |
| I | I09 | ⬜ | nhóm `o` |
| P | P01–P10 | ⬜ | nhóm `p` |
| R | R01–R12 | 🧪 | nhóm `r` (branch `content/r`): `verify.sh` xanh trên Postgres 18.6 (86 đạt, 17 tự đối chiếu, 0 lỗi); chưa chạy ở `shop_l`. Chi tiết: `tools/reports/r.md` |
| O | O01–O06 | ⬜ | nhóm `o` |
| D | D01–D10 | ⬜ | nhóm `d`, thư mục `designs/` |
