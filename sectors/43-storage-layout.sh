#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

usage() {
  echo "Usage: $0 [--dry-run|--apply]"
}

require_root
load_config
mode="${1:---dry-run}"
dry_run=1
[[ "$mode" == "--apply" ]] && dry_run=0
[[ "$mode" == "--dry-run" || "$mode" == "--apply" ]] || { usage; exit 1; }

ensure_sql_paths_from_root
root="$(config_get SQL_STORAGE_ROOT)"
data="$(config_get SQL_DATA_PATH)"
logp="$(config_get SQL_LOG_PATH)"
backup="$(config_get SQL_BACKUP_PATH)"
tempdb="$(config_get SQL_TEMPDB_PATH)"

log "Configuring single-drive SQL directory layout ($mode)"

if [[ "$dry_run" == "0" ]]; then
  read -rp "Type apply to create/update SQL directories: " typed
  [[ "$typed" == "apply" ]] || die "Apply cancelled"
fi

run_cmd "$dry_run" mkdir -p "$root" "$data" "$logp" "$backup" "$tempdb"
run_cmd "$dry_run" chmod 750 "$root" "$data" "$logp" "$backup" "$tempdb"

if id mssql >/dev/null 2>&1; then
  run_cmd "$dry_run" chown -R mssql:mssql "$root"
else
  log "User mssql not present yet; ownership update skipped."
fi

log "Directory layout complete."