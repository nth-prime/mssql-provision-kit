#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

out="$LOG_DIR/storage-report-$(date -u +%Y%m%dT%H%M%SZ).txt"
{
  echo "mssql-provision-kit storage report"
  echo "generated_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "== config volume map =="
  for id in $(volume_ids); do
    echo "$id device=$(volume_key "$id" DEVICE) fs=$(volume_key "$id" FS) mount=$(volume_key "$id" MOUNT)"
  done
  echo
  echo "== sql role mapping =="
  echo "data=$(config_get SQL_DATA_VOLUME) path=$(config_get SQL_DATA_PATH)"
  echo "log=$(config_get SQL_LOG_VOLUME) path=$(config_get SQL_LOG_PATH)"
  echo "backup=$(config_get SQL_BACKUP_VOLUME) path=$(config_get SQL_BACKUP_PATH)"
  echo "tempdb=$(config_get SQL_TEMPDB_VOLUME) path=$(config_get SQL_TEMPDB_PATH)"
  echo
  echo "== lsblk -f =="
  lsblk -f
  echo
  echo "== findmnt =="
  findmnt -lo TARGET,SOURCE,FSTYPE,OPTIONS | sed -n '1,200p'
  echo
  echo "== df -hT =="
  df -hT
} > "$out"

log "Report written: $out"
cat "$out"