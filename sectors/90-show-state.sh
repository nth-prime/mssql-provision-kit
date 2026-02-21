#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root

log "State dir: $STATE_DIR"
log "Log dir: $LOG_DIR"

echo
if [[ -d "$STATE_DIR" ]]; then
  echo "State files:"
  ls -la "$STATE_DIR" 2>/dev/null || true
fi

echo
echo "Recent log tail:"
tail -n 200 "$LOG_DIR/kit.log" 2>/dev/null || echo "(no log yet)"