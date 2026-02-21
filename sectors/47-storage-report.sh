#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
ensure_sql_paths_from_root

out="$LOG_DIR/storage-report-$(date -u +%Y%m%dT%H%M%SZ).txt"
root="$(config_get SQL_STORAGE_ROOT)"
data="$(config_get SQL_DATA_PATH)"
logp="$(config_get SQL_LOG_PATH)"
backup="$(config_get SQL_BACKUP_PATH)"
tempdb="$(config_get SQL_TEMPDB_PATH)"

{
  echo "mssql-provision-kit storage report"
  echo "generated_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "layout=single-drive"
  echo
  echo "root=$root"
  echo "data=$data"
  echo "log=$logp"
  echo "backup=$backup"
  echo "tempdb=$tempdb"
  echo
  echo "== findmnt targets =="
  for p in "$root" "$data" "$logp" "$backup" "$tempdb"; do
    if [[ -e "$p" ]]; then
      findmnt -T "$p" || true
    else
      echo "missing=$p"
    fi
  done
  echo
  echo "== df -hT =="
  df -hT
} > "$out"

log "Report written: $out"
cat "$out"