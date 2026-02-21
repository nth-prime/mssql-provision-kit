#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
ensure_sql_paths_from_root

log "Running storage health checks..."

root="$(config_get SQL_STORAGE_ROOT)"
for key in SQL_DATA_PATH SQL_LOG_PATH SQL_BACKUP_PATH SQL_TEMPDB_PATH; do
  p="$(config_get "$key")"
  echo "[$key] path=$p"
  path_is_within_root "$root" "$p" || die "$key must be under SQL_STORAGE_ROOT ($root)"
  parent="$(dirname "$p")"
  [[ -d "$parent" ]] || die "Parent directory missing for $key: $parent"
  [[ -w "$parent" ]] || die "Parent directory not writable for $key: $parent"
  if [[ -d "$p" ]]; then
    [[ -w "$p" ]] || die "Directory not writable: $p"
  fi
done

log "Storage health checks passed."
