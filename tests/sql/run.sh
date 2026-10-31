#!/usr/bin/env bash
# SQL(01~14) + 권한 규칙(RLS) 시나리오 테스트.
#   사용: tests/sql/run.sh            (임시 Postgres 를 띄워 돌리고 지웁니다)
#         DATABASE_URL=postgres://… tests/sql/run.sh   (이미 있는 빈 데이터베이스에서 돌림 — 운영 DB 에는 절대 쓰지 마세요)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(cd "$HERE/../.." && pwd)"
PSQL_OPTS=(-v ON_ERROR_STOP=1 -q -X)
if [ -n "${DATABASE_URL:-}" ]; then
  run() { psql "$DATABASE_URL" "${PSQL_OPTS[@]}" "$@"; }
  cleanup() { :; }
else
  PGBIN="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1 || true)"
  [ -n "$PGBIN" ] || { echo "Postgres 가 필요합니다 (apt install postgresql)"; exit 2; }
  TMP="$(mktemp -d)"; PORT=$((20000 + RANDOM % 20000))
  if [ "$(id -u)" = 0 ]; then
    chown postgres "$TMP"; AS="su postgres -c"
    sh_pg() { su postgres -c "$*"; }
  else
    sh_pg() { sh -c "$*"; }
  fi
  sh_pg "$PGBIN/initdb -D $TMP/d -A trust >/dev/null"
  sh_pg "$PGBIN/pg_ctl -D $TMP/d -o '-p $PORT -k $TMP' -l $TMP/log start >/dev/null"
  cleanup() { sh_pg "$PGBIN/pg_ctl -D $TMP/d stop -m fast >/dev/null" || true; rm -rf "$TMP"; }
  trap cleanup EXIT
  sleep 2
  run() { psql -h "$TMP" -p "$PORT" -U postgres -d postgres "${PSQL_OPTS[@]}" "$@"; }
fi
OUT="$(mktemp)"
{
  run -f "$HERE/stubs.sql"
  for f in "$ROOT"/sql/0[1235]_*.sql "$ROOT"/sql/0[789]_*.sql "$ROOT"/sql/1[0-9]_*.sql; do
    echo "-- load: $(basename "$f")" >&2
    run -f "$f"
  done
  run -c "grant usage on schema public to anon, authenticated; grant all on all tables in schema public to anon, authenticated; grant all on all sequences in schema public to anon, authenticated; grant execute on all functions in schema public to anon, authenticated;"
  run -f "$HERE/helpers.sql"
  run -f "${SCENARIOS:-$HERE/scenarios.sql}"
} >"$OUT" 2>&1 || { cat "$OUT"; echo; echo "✗ 실패 (위 마지막 오류를 보세요)"; exit 1; }
PASS=$(grep -c "PASS:" "$OUT" || true); FAIL=$(grep -c "FAIL" "$OUT" || true)
grep "PASS:" "$OUT" | sed 's/^psql:[^ ]* NOTICE: *//' || true
echo "—— $PASS 개 통과, $FAIL 개 실패"
[ "$FAIL" = 0 ]
