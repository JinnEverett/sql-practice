# Nạp bằng `source`. Cung cấp sql_pg: chạy psql vào Postgres của workspace.
#   SQL_PG=docker (mặc định)  docker exec -i sql-practice-pg psql -U postgres ...
#   SQL_PG=local              psql trực tiếp (cho máy/cloud không có Docker): PGHOST, PGPORT, PGUSER, PGPASSWORD
sql_pg() {
  if [ "${SQL_PG:-docker}" = local ]; then
    psql -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" "$@"
  else
    docker exec -i sql-practice-pg psql -U postgres "$@"
  fi
}
