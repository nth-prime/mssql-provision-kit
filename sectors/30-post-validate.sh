#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

log "Running post-install validation..."
require_cmds systemctl
systemctl is-active --quiet mssql-server || die "mssql-server is not active"

if command -v /opt/mssql-tools18/bin/sqlcmd >/dev/null 2>&1; then
  log "sqlcmd found at /opt/mssql-tools18/bin/sqlcmd"
fi

log "Validation complete."