#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root

tester="/opt/mssql-provision-kit/tests/tester"
[[ -f "$tester" ]] || die "Tester not found: $tester"

if ! command -v bash >/dev/null 2>&1; then
  die "bash is required to run tests"
fi

log "Running unit tests"
bash "$tester"