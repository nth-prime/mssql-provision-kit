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

for role in SQL_DATA_VOLUME SQL_LOG_VOLUME SQL_BACKUP_VOLUME SQL_TEMPDB_VOLUME; do
  vid="$(config_get "$role")"
  [[ -n "$vid" ]] || die "Missing role mapping: $role"
  mnt="$(volume_key "$vid" MOUNT)"
  [[ -n "$mnt" ]] || die "Missing mount for $vid"
  if ! findmnt -n "$mnt" >/dev/null 2>&1; then
    die "Required mount is not active: $mnt ($role=$vid)"
  fi
done

log "Preflight passed."