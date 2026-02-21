#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

ensure_sql_paths_from_root
root="$(config_get SQL_STORAGE_ROOT)"
data="$(config_get SQL_DATA_PATH)"
logp="$(config_get SQL_LOG_PATH)"
backup="$(config_get SQL_BACKUP_PATH)"
tempdb="$(config_get SQL_TEMPDB_PATH)"

log "Inspecting storage state..."
if command -v lsblk >/dev/null 2>&1; then
  lsblk -f || true
else
  echo "lsblk not found"
fi

echo
echo "Configured SQL paths:"
echo "  root   : $root"
echo "  data   : $data"
echo "  log    : $logp"
echo "  backup : $backup"
echo "  tempdb : $tempdb"

echo
for p in "$root" "$data" "$logp" "$backup" "$tempdb"; do
  if [[ -e "$p" ]]; then
    findmnt -T "$p" || true
  else
    echo "Path missing: $p"
  fi
done

echo
if command -v df >/dev/null 2>&1; then
  df -hT || true
else
  echo "df not found"
fi
