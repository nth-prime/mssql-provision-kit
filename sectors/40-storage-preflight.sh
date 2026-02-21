#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

log "Running storage preflight (single-drive layout)..."
is_ubuntu_24 || die "Unsupported OS. Requires Ubuntu 24.04"
require_cmds lsblk findmnt df awk sed grep

ensure_sql_paths_from_root
root="$(config_get SQL_STORAGE_ROOT)"

if [[ ! -d "$root" ]]; then
  log "Storage root does not exist yet: $root"
else
  findmnt -T "$root" >/dev/null 2>&1 || die "Unable to resolve filesystem for $root"
fi

log "Storage preflight passed."