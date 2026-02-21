#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/20-install-sql.sh"
assert_file_exists "$f"

assert_contains "$f" 'Usage: $0 [--dry-run|--apply]'
assert_contains "$f" 'VERSION_STRATEGY'
assert_contains "$f" 'PROMPT_FOR_SA_PASSWORD'
assert_contains "$f" 'Sysadmin login name'
assert_contains "$f" 'DRY-RUN: would run mssql-conf with PID and SA password (redacted).'

echo "install flow guard checks passed"