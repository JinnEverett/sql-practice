#!/usr/bin/env bash
# O02 · Phòng thí nghiệm PITR bằng Docker (không đụng container sql-practice-pg).
#   bash lessons/O02-backup/pitr-lab.sh up        # dựng Postgres nguồn bật WAL archiving (volume pitr_archive)
#   bash lessons/O02-backup/pitr-lab.sh base      # pg_basebackup + pg_verifybackup
#   bash lessons/O02-backup/pitr-lab.sh oops      # chèn thêm dữ liệu, ghi lại T1, rồi "xóa nhầm"; in T1 và T2
#   bash lessons/O02-backup/pitr-lab.sh restore "<T1>"   # dựng bản khôi phục tới thời điểm T1 (container pitr_new, port 5434)
#   bash lessons/O02-backup/pitr-lab.sh down      # xóa container và volume của bài
set -euo pipefail
export MSYS_NO_PATHCONV=1
IMG=postgres:18
S="docker exec pitr_src"
case "${1:-}" in
  up)
    docker rm -f pitr_src pitr_new >/dev/null 2>&1 || true
    docker volume create pitr_archive >/dev/null
    docker run --rm -v pitr_archive:/archive "$IMG" chmod 777 /archive
    docker run -d --name pitr_src -e POSTGRES_PASSWORD=postgres -v pitr_archive:/archive "$IMG" \
      -c wal_level=replica -c archive_mode=on \
      -c "archive_command=test ! -f /archive/%f && cp %p /archive/%f" \
      -c archive_timeout=30 -c max_wal_size=1GB >/dev/null
    until $S pg_isready -U postgres -q 2>/dev/null; do sleep 1; done
    $S psql -U postgres -q -c "create table orders_demo as select i as id, (random()*1000)::int as customer_id, now() as created_at from generate_series(1,200000) i" -c "alter table orders_demo add primary key (id)"
    echo "OK: pitr_src chạy, orders_demo có $($S psql -U postgres -Atc 'select count(*) from orders_demo') dòng"
    ;;
  base)
    $S pg_basebackup -U postgres -D /archive/base -Fp -X stream -c fast
    $S pg_verifybackup /archive/base
    ;;
  oops)
    $S psql -U postgres -q -c "insert into orders_demo select i, 1, now() from generate_series(200001,300000) i"
    sleep 2
    echo "T1 (thời điểm tốt) = $($S psql -U postgres -Atc 'select clock_timestamp()')"
    sleep 3
    $S psql -U postgres -c "delete from orders_demo where id > 100"
    echo "T2 (sau sự cố)     = $($S psql -U postgres -Atc 'select clock_timestamp()')"
    $S psql -U postgres -Atc "select pg_switch_wal()" >/dev/null   # ép lưu trữ đoạn WAL cuối
    sleep 5
    echo "bảng hiện có $($S psql -U postgres -Atc 'select count(*) from orders_demo') dòng (đáng lẽ 300000)"
    ;;
  restore)
    T1=${2:?cần thời điểm đích, vd "2026-10-18 02:05:57+00"}
    docker rm -f pitr_new >/dev/null 2>&1 || true
    docker volume rm -f pitr_restore >/dev/null
    docker volume create pitr_restore >/dev/null
    docker run --rm -v pitr_archive:/archive -v pitr_restore:/restore "$IMG" bash -c "
      cp -a /archive/base/. /restore/ &&
      printf \"restore_command = 'cp /archive/%%f %%p'\nrecovery_target_time = '$T1'\nrecovery_target_action = 'promote'\n\" >> /restore/postgresql.auto.conf &&
      touch /restore/recovery.signal && chown -R postgres:postgres /restore && chmod 700 /restore"
    docker run -d --name pitr_new -e POSTGRES_PASSWORD=postgres -p 5434:5432 \
      -v pitr_restore:/var/lib/postgresql/18/docker -v pitr_archive:/archive:ro "$IMG" >/dev/null
    until docker exec pitr_new psql -U postgres -Atqc "select not pg_is_in_recovery()" 2>/dev/null | grep -q t; do sleep 1; done
    docker exec pitr_new psql -U postgres -c "select count(*) as rows_after_pitr, max(id) from orders_demo"
    ;;
  down)
    docker rm -f pitr_src pitr_new >/dev/null 2>&1 || true
    docker volume rm -f pitr_archive pitr_restore >/dev/null
    echo "đã dọn"
    ;;
  *) sed -n '2,8p' "$0"; exit 1;;
esac
