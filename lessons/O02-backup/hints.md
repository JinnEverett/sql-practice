# O02 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint.

## ex01
<details><summary>H1</summary><code>-F</code> chọn định dạng (<code>p</code>, <code>c</code>, <code>d</code>); <code>-Z0</code> tắt nén.</details>
<details><summary>H2</summary>Chạy custom hai lần: nén mặc định và <code>-Z0</code>; phần chênh là thời gian nén.</details>
<details><summary>H3</summary>Chỉ directory format hỗ trợ <code>pg_dump -j</code>.</details>

## ex02
<details><summary>H1</summary><code>pg_restore -l file</code> đọc danh mục, không cần DB.</details>
<details><summary>H2</summary><code>pg_dump -s</code> (schema), <code>-t users</code> (một bảng).</details>
<details><summary>H3</summary>Dump một bảng không kèm bảng cha qua FK, nên restore riêng có thể thiếu tham chiếu.</details>

## ex03
<details><summary>H1</summary><code>createdb</code> DB mới, rồi <code>pg_restore -d</code>.</details>
<details><summary>H2</summary>Song song: <code>-j 4</code> (chỉ custom/directory).</details>
<details><summary>H3</summary>Restore gồm nạp <code>COPY</code> và dựng lại index/constraint: đây là phần tốn thời gian ngoài việc copy.</details>

## ex04
<details><summary>H1</summary><code>-t users</code> chọn bảng, <code>-a</code> chỉ dữ liệu.</details>
<details><summary>H2</summary>Tạo cấu trúc trước bằng <code>-s</code>, nạp dữ liệu bằng <code>-a -t users</code>.</details>
<details><summary>H3</summary>Sau khi nạp ở DB tạm, dùng <code>INSERT … SELECT</code>/<code>UPDATE … FROM</code> để cứu đúng dòng cần.</details>

## ex05
<details><summary>H1</summary>Cần base backup + mọi file WAL từ lúc đó tới thời điểm đích.</details>
<details><summary>H2</summary>Đích là T1 mà lệnh <code>oops</code> in ra, trước giao dịch DELETE.</details>
<details><summary>H3</summary>Log của <code>pitr_new</code> có dòng <code>recovery stopping before commit of transaction …</code>.</details>

## ex06
<details><summary>H1</summary><code>pg_basebackup -D dir -Fp -X stream -c fast</code> rồi <code>pg_verifybackup dir</code>.</details>
<details><summary>H2</summary>Verify kiểm tra file theo <code>backup_manifest</code>, không chứng minh khởi động được.</details>
<details><summary>H3</summary>Runbook gồm: restore tự động, kiểm tra count/checksum, ghi RTO, cảnh báo khi thất bại.</details>

## ex07
<details><summary>H1</summary>Nhân 10 cho phần tuyến tính theo kích thước.</details>
<details><summary>H2</summary>Chú ý số index, cache so với <code>shared_buffers</code>, nén một luồng.</details>
<details><summary>H3</summary>Đối chiếu <code>solutions/ex07.md</code> sau khi tự dự đoán.</details>
