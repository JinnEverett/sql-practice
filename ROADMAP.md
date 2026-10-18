# Lộ trình SQL / PostgreSQL

> Nguồn sự thật cho **module ID**. Các skill đọc file này để biết nội dung từng buổi.
> Mỗi module ≈ 1 buổi (60–90 phút). Module lớn có thể chia 2 buổi (`F05a`, `F05b`).

## Sơ đồ tổng thể

```mermaid
flowchart TD
    S00["S00 · Setup môi trường<br/>Docker + psql + bậc thang dataset + bench"]

    subgraph T1["Tier F · Foundations"]
        F01[F01 SELECT/WHERE/ORDER] --> F02[F02 Data types]
        F02 --> F03[F03 NULL & 3-valued logic]
        F03 --> F04[F04 Aggregates]
        F04 --> F05[F05 JOINs]
        F05 --> F06[F06 Subqueries]
        F06 --> F07[F07 Set operations]
        F05 --> F08[F08 DML & UPSERT]
        F08 --> F09[F09 DDL & Constraints]
        F03 --> F10[F10 CASE / string / date]
    end

    subgraph T2["Tier I · Intermediate"]
        I01[I01 CTE] --> I02[I02 Recursive CTE]
        I01 --> I03[I03 Window I: ranking]
        I03 --> I04[I04 Window II: frames]
        I05[I05 Date/time deep dive]
        I06[I06 Text & regex]
        I07[I07 JSONB & arrays]
        I08[I08 LATERAL / GROUPING SETS / pivot]
        I09[I09 Views / functions / triggers]
    end

    subgraph T3["Tier P · Internals & Performance"]
        P01[P01 Storage: heap, page, TOAST] --> P02[P02 B-tree index]
        P02 --> P03[P03 EXPLAIN ANALYZE]
        P03 --> P04[P04 Statistics & planner]
        P03 --> P05[P05 GIN / GiST / BRIN]
        P06[P06 Transactions & isolation] --> P07[P07 MVCC & VACUUM]
        P06 --> P08[P08 Locks & deadlocks]
        P04 --> P09[P09 Query anti-patterns]
        P04 --> P10[P10 Scale effects<br/>1 → 10k → 1M → 10M]
        P05 --> P10
        P10 --> P09
    end

    subgraph T4["Tier R · Real-world patterns"]
        R01[R01 Data modeling]
        R02[R02 Keyset pagination]
        R03[R03 Idempotency & dedup]
        R04[R04 Job queue SKIP LOCKED]
        R05[R05 Audit / soft delete / SCD2]
        R06[R06 Hierarchical data]
        R07[R07 Analytics: cohort, funnel, gaps&islands]
        R08[R08 Concurrency bugs]
        R09[R09 Multi-tenancy & RLS]
        R10[R10 Zero-downtime migrations]
        R11[R11 Full-text & fuzzy search]
        R12[R12 Partitioning & time-series]
    end

    subgraph T5["Tier O · Operations"]
        O01[O01 Roles & security]
        O02[O02 Backup / PITR / WAL]
        O03[O03 Monitoring: pg_stat_*]
        O04[O04 Connection pooling]
        O05[O05 Config tuning]
        O06[O06 Replication & HA]
    end

    subgraph T6["Tier D · System Design"]
        D01[D01 Phương pháp thiết kế] --> D02[D02 URL shortener]
        D01 --> D03[D03 E-commerce]
        D01 --> D04[D04 Banking ledger]
        D01 --> D05[D05 Booking system]
        D01 --> D06[D06 Social feed]
        D01 --> D07[D07 Chat]
        D01 --> D08[D08 Multi-tenant SaaS]
        D01 --> D09[D09 Analytics / CDC / Outbox]
        D01 --> D10[D10 Scaling Postgres]
    end

    CAP["🏁 Capstone<br/>Thiết kế + hiện thực 1 hệ thống end-to-end"]

    S00 --> T1
    T1 --> T2
    T2 --> T3
    T2 --> R01
    T3 --> T4
    T3 --> T5
    T4 --> T6
    T5 --> T6
    T6 --> CAP
```

Ghi chú phụ thuộc chéo quan trọng:
`P06–P08 → R04, R08` · `P02–P05 → R02, R11, R12` · `I03–I04 → R07` · `F09 + R01 → D*` · `O06 → D10` · `P10 → R10, R12, O05, D*`

## Trục quy mô (xuyên suốt mọi tier)

Học SQL không dừng ở chỗ query ra kết quả đúng. Cần biết thêm query còn chạy được ở quy mô nào, và lý do.

```mermaid
flowchart LR
    XS["shop_xs · 100<br/>đúng/sai"] --> S["shop_s · 10k<br/>mặc định F/I"]
    S --> M["shop_m · 1M<br/>index bắt đầu quan trọng"]
    M --> L["shop_l · 10M<br/>vượt RAM, spill, lock lâu"]
    L -.-> XL["shop_xl · 100M<br/>tùy chọn"]
```

| Tier | Quy mô được dùng | Cách luyện |
|---|---|---|
| F | `xs` / `s` | Tập trung vào đúng/sai. Cuối mỗi buổi có thêm 1 câu "dự đoán ở 1M" để làm quen |
| I | `s` + `bench` | Mỗi lesson có ≥1 câu hỏi quy mô: dự đoán trước, sau đó chạy `bench` trên `s,m,l` |
| P | `m` / `l` | Mặc định đo trên dữ liệu lớn. P10 là module chuyên về hiệu ứng quy mô |
| R / O | `m` / `l` | Migration, partition, backup, vacuum: đo thời gian chạy và thời gian giữ lock theo quy mô |
| D | Ước lượng + `bench` | Ước lượng trên giấy, sau đó chứng minh bằng số đo thật ở `l` |

## Sơ đồ hệ thống skill

```mermaid
flowchart LR
    U((Người học)) --> SQL["/sql<br/>coach & router"]
    SQL -->|module tiếp theo| LES["/sql-lesson"]
    SQL -->|ôn điểm yếu| DRL["/sql-drill"]
    SQL -->|Tier R/O| CAS["/sql-case"]
    SQL -->|Tier D| DES["/sql-design"]
    LES -->|nộp bài| REV["/sql-review"]
    CAS -->|nộp bài| REV
    REV -->|lỗi lặp lại| W[(weaknesses.md)]
    LES & REV & DRL & CAS & DES --> T[(tracker.md)]
    W --> DRL
    T --> SQL
    LES & REV & CAS --> PG[(Postgres 18<br/>Docker)]
```

## Nhịp một buổi học chuẩn

```mermaid
flowchart LR
    A["Warm-up 5'<br/>2–3 câu ôn (drill)"] --> B["Concept 10'<br/>lý thuyết cô đọng"]
    B --> C["Practice 40–60'<br/>bài tập tăng dần độ khó"]
    C --> D["Review 10'<br/>chấm + EXPLAIN + edge case"]
    D --> E["Log 2'<br/>cập nhật tracker"]
```

---

## Danh mục module

Cột **Pass** = tiêu chí để đánh dấu ✅.

### S · Setup
| ID | Chủ đề | Nội dung chính | Pass |
|---|---|---|---|
| S00 | Môi trường | docker-compose Postgres 18, psql cơ bản (`\d`, `\dt`, `\x`, `\timing`), script sinh dữ liệu e-commerce (users, products, categories, orders, order_items, payments, events) có tham số N và seed cố định. Sinh bậc thang `shop_xs/s/m` (sinh `l` khi tới Tier P), DB `lab`, công cụ `bench/bench.sh` | `bench` chạy được 1 query trên `xs,s,m` và xuất bảng so sánh |

### F · Foundations
| ID | Chủ đề | Nội dung chính | Pass |
|---|---|---|---|
| F01 | SELECT cơ bản | SELECT, WHERE, ORDER BY, LIMIT/OFFSET, DISTINCT, alias, thứ tự thực thi logic | 8/10 bài, ≤2 hint |
| F02 | Data types | numeric vs float, text/varchar, boolean, timestamp vs timestamptz, uuid, cast `::`, overflow & làm tròn | 8/10 |
| F03 | NULL | three-valued logic, COALESCE, NULLIF, `IS DISTINCT FROM`, NULL trong ORDER BY / aggregate | 8/10 |
| F04 | Aggregates | GROUP BY, HAVING, COUNT(*) vs COUNT(col), `FILTER (WHERE)`, string_agg/array_agg | 8/10 |
| F05 | JOINs | INNER/LEFT/RIGHT/FULL/CROSS, self join, semi/anti join, bẫy nhân dòng (fan-out) | 8/10 |
| F06 | Subqueries | scalar, IN, EXISTS, correlated, bẫy `NOT IN` với NULL | 8/10 |
| F07 | Set operations | UNION vs UNION ALL, INTERSECT, EXCEPT, so sánh 2 tập dữ liệu | 8/10 |
| F08 | DML | INSERT…SELECT, UPDATE…FROM, DELETE…USING, RETURNING, `ON CONFLICT`, MERGE | 8/10 |
| F09 | DDL & constraints | CREATE/ALTER TABLE, PK/FK/UNIQUE/CHECK/NOT NULL, identity, ON DELETE, generated columns | Thiết kế được schema có ràng buộc đúng |
| F10 | Biểu thức | CASE, hàm string/date cơ bản, format số/ngày | 8/10 |

### I · Intermediate
| ID | Chủ đề | Nội dung chính | Pass |
|---|---|---|---|
| I01 | CTE | WITH, chia nhỏ query, `MATERIALIZED`/`NOT MATERIALIZED`, data-modifying CTE | 8/10 |
| I02 | Recursive CTE | cây danh mục, org chart, đường đi đồ thị, chống vòng lặp, sinh chuỗi | 6/8 |
| I03 | Window I | ROW_NUMBER, RANK, DENSE_RANK, NTILE, PARTITION BY, top-N mỗi nhóm | 8/10 |
| I04 | Window II | LAG/LEAD, running total, moving average, frame ROWS/RANGE/GROUPS, FIRST/LAST_VALUE | 8/10 |
| I05 | Date/time | time zone, date_trunc, interval, generate_series, lấp khoảng trống ngày | 8/10 |
| I06 | Text | LIKE/ILIKE, regex (`~`, regexp_*), split, string_agg, collation | 8/10 |
| I07 | JSONB & arrays | `->`, `->>`, `@>`, `?`, jsonb_path_query, jsonb_agg, unnest, array ops | 8/10 |
| I08 | Nâng cao | LATERAL, GROUPING SETS/ROLLUP/CUBE, pivot bằng FILTER, crosstab | 6/8 |
| I09 | Đối tượng DB | view, materialized view, function SQL/PL/pgSQL, trigger cơ bản | 6/8 |

### P · Internals & Performance (mặc định `shop_m`, thí nghiệm trên `shop_l`)
| ID | Chủ đề | Nội dung chính | Pass |
|---|---|---|---|
| P01 | Storage | heap, page 8KB, tuple header, ctid, TOAST, fillfactor, `pg_relation_size` | Giải thích được bằng số liệu thật |
| P02 | B-tree index | composite & thứ tự cột, covering `INCLUDE`, partial, expression index, index-only scan | Tối ưu 5 query chậm |
| P03 | EXPLAIN | đọc plan, Seq/Index/Bitmap scan, Nested Loop/Hash/Merge join, BUFFERS, cost vs actual | Đọc đúng 5 plan |
| P04 | Planner | ANALYZE, pg_stats, selectivity, ước lượng lệch, extended statistics | Sửa 3 plan sai do stats |
| P05 | Index đặc biệt | GIN (jsonb, trigram, FTS), GiST, BRIN, khi nào KHÔNG nên index | Chọn đúng loại index cho 6 tình huống |
| P06 | Transactions | ACID, isolation levels, anomalies (dirty, non-repeatable, phantom, write skew), SERIALIZABLE retry | Tái hiện được 3 anomaly bằng 2 session |
| P07 | MVCC & VACUUM | xmin/xmax, dead tuples, autovacuum, bloat, HOT update, XID wraparound | Đo & giải thích bloat |
| P08 | Locks | lock mode, `FOR UPDATE/SHARE/NO KEY UPDATE`, deadlock, lock queue khi ALTER, advisory lock, `lock_timeout` | Tái hiện & sửa 1 deadlock |
| P09 | Anti-patterns | N+1, OFFSET lớn, hàm bọc cột index, OR, implicit cast, `SELECT *`, `COUNT(*)` chậm | Refactor 8 query |
| P10 | Scale effects (2 buổi: P10a, P10b) | **P10a · Đọc:** điểm planner đổi từ Seq sang Index/Bitmap scan (selectivity × số dòng); join đổi từ Nested Loop sang Hash/Merge; sort/hash tràn ra đĩa khi vượt `work_mem`; bảng/index vượt `shared_buffers` (`pg_buffercache`, cache hit ratio); `COUNT(*)`, `ORDER BY` không có index, OFFSET sâu; độ phức tạp O(n) so với O(log n) đo thực tế. **P10b · Ghi & vận hành:** INSERT từng dòng, INSERT theo batch và `COPY`; chi phí index khi ghi (write amplification); thời gian `CREATE INDEX` / `CONCURRENTLY`; `ALTER TABLE` rewrite và thời gian giữ lock; `UPDATE` hàng loạt gây bloat; thời gian VACUUM/ANALYZE; dung lượng bảng + index + TOAST theo N | Mỗi thí nghiệm có dự đoán trước. Dự đoán đúng xu hướng ≥ 70%. Giải thích được mọi điểm gãy bằng số đo từ `bench` |

### R · Real-world patterns
| ID | Chủ đề | Nội dung chính | Pass |
|---|---|---|---|
| R01 | Data modeling | ERD, 1NF→BCNF, khi nào denormalize, naming convention, khóa tự nhiên vs surrogate | Model 1 domain có review |
| R02 | Pagination | keyset/cursor pagination, sort ổn định, so sánh với OFFSET | Benchmark 2 cách |
| R03 | Idempotency & dedup | upsert, idempotency key, xóa trùng giữ bản mới nhất, unique cho business rule | 6/8 |
| R04 | Job queue | `FOR UPDATE SKIP LOCKED`, retry/backoff, LISTEN/NOTIFY, so sánh với broker ngoài | Queue chạy đúng với nhiều worker |
| R05 | Lịch sử dữ liệu | audit log bằng trigger, soft delete, temporal table, SCD type 2 | 6/8 |
| R06 | Dữ liệu cây | adjacency list, ltree, closure table, nested set — trade-off | So sánh 3 cách |
| R07 | Analytics SQL | cohort retention, funnel, gaps & islands, sessionization, percentile | 6/8 |
| R08 | Concurrency bugs | lost update, oversell tồn kho, double booking (exclusion constraint), optimistic locking | Tái hiện & sửa 3 bug |
| R09 | Multi-tenancy | shared table + tenant_id, schema-per-tenant, Row-Level Security | RLS chặn đúng truy cập chéo |
| R10 | Migrations | add column/NOT NULL an toàn, backfill theo batch, `CREATE INDEX CONCURRENTLY`, expand/contract | Kế hoạch migration không downtime |
| R11 | Search | tsvector/tsquery, ranking, pg_trgm fuzzy, unaccent (tiếng Việt) | Search đúng + có index |
| R12 | Bảng lớn | partitioning range/list/hash, partition pruning, retention, time-series rollup | Partition + pruning hoạt động |

### O · Operations
| ID | Chủ đề | Nội dung chính | Pass |
|---|---|---|---|
| O01 | Security | role, GRANT/REVOKE, default privileges, least privilege, SQL injection & prepared statement | Thiết lập role cho 1 app |
| O02 | Backup | pg_dump/pg_restore, WAL, PITR, kiểm thử restore | Restore thành công |
| O03 | Monitoring | pg_stat_statements, pg_stat_activity, pg_locks, auto_explain, log_min_duration_statement | Tìm top 5 query tệ nhất |
| O04 | Connections | chi phí connection, max_connections, PgBouncer session/transaction mode | Giải thích & cấu hình |
| O05 | Tuning | shared_buffers, work_mem, effective_cache_size, checkpoint, random_page_cost | Đo trước/sau |
| O06 | Replication & HA | streaming vs logical replication, replica lag, read-your-writes, failover (Patroni — khái niệm) | Dựng 1 replica bằng Docker |

### D · System Design
| ID | Chủ đề | Trọng tâm | Pass |
|---|---|---|---|
| D01 | Phương pháp | requirements → access patterns → ước lượng tải → schema → index → bottleneck → scale | Áp dụng được checklist |
| D02 | URL shortener | sinh ID, hot read, cache, analytics click | Bản thiết kế + review |
| D03 | E-commerce | đơn hàng, tồn kho, thanh toán, trạng thái đơn (state machine) | 〃 |
| D04 | Banking ledger | double-entry, số dư, chuyển tiền idempotent, đối soát | 〃 |
| D05 | Booking | giữ chỗ tạm, hết hạn, chống double booking | 〃 |
| D06 | Social feed | follow graph, fan-out on write/read, counter hot row | 〃 |
| D07 | Chat | lưu tin nhắn, unread count, phân trang lịch sử | 〃 |
| D08 | Multi-tenant SaaS | isolation, noisy neighbor, migrate tenant lớn | 〃 |
| D09 | Data pipeline | OLTP vs OLAP, outbox pattern, CDC, materialized aggregates | 〃 |
| D10 | Scaling Postgres | replica, cache, partition, sharding (Citus), khi nào rời Postgres | 〃 |
| CAP | Capstone | chọn 1 đề D*, hiện thực schema + seed + query chính + benchmark | Demo + review |
