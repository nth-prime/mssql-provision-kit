#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

log "Running host preflight checks..."
is_ubuntu_24 || die "Unsupported OS. Requires Ubuntu 24.04 for SQL Server 2025 in this kit."

require_cmds curl gpg lsblk findmnt awk sed grep systemctl

if [[ "${TARGET_SQL_MAJOR:-}" != "2025" ]]; then
  die "Only SQL Server 2025 is supported by this kit scope."
fi

ensure_sql_paths_from_root
for key in SQL_STORAGE_ROOT SQL_DATA_PATH SQL_LOG_PATH SQL_BACKUP_PATH SQL_TEMPDB_PATH; do
  p="$(config_get "$key")"
  [[ -n "$p" ]] || die "Missing $key"
  [[ "$p" == /* ]] || die "$key must be an absolute path"
done

log "Preflight passed."