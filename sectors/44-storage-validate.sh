#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
ensure_sql_paths_from_root

log "Validating SQL directory layout..."
root="$(config_get SQL_STORAGE_ROOT)"
for key in SQL_DATA_PATH SQL_LOG_PATH SQL_BACKUP_PATH SQL_TEMPDB_PATH; do
  p="$(config_get "$key")"
  [[ -d "$p" ]] || die "Missing directory for $key: $p"
  [[ -w "$p" ]] || die "Directory not writable for $key: $p"
  path_is_within_root "$root" "$p" || die "$key is outside SQL_STORAGE_ROOT"
  probe="$p/.mssql-provision-write-test"
  echo "ok $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$probe"
  rm -f "$probe"
done

log "Directory layout validation passed."
