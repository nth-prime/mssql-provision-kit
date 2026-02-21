#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

ids="$(volume_ids)"
echo "Known volumes: $ids"

for role in SQL_DATA_VOLUME SQL_LOG_VOLUME SQL_BACKUP_VOLUME SQL_TEMPDB_VOLUME; do
  cur="$(config_get "$role")"
  read -rp "$role [$cur]: " v
  v="${v:-$cur}"
  [[ " $ids " == *" $v "* ]] || die "Unknown volume id for $role: $v"
  config_set "$role" "$v"
  mnt="$(volume_key "$v" MOUNT)"
  case "$role" in
    SQL_DATA_VOLUME) config_set SQL_DATA_PATH "$mnt" ;;
    SQL_LOG_VOLUME) config_set SQL_LOG_PATH "$mnt" ;;
    SQL_BACKUP_VOLUME) config_set SQL_BACKUP_PATH "$mnt" ;;
    SQL_TEMPDB_VOLUME) config_set SQL_TEMPDB_PATH "$mnt" ;;
  esac
done

log "Updated SQL role mappings."