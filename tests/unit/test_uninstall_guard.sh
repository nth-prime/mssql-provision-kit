#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/80-uninstall-cleanup.sh"
assert_file_exists "$f"

assert_contains "$f" 'read -rp "Type uninstall to proceed: " typed'
assert_contains "$f" '[[ "$typed" == "uninstall" ]] || die "Uninstall cancelled"'
assert_not_contains "$f" 'load_config'
assert_contains "$f" 'rm -rf /opt/mssql-provision-kit || true'
assert_contains "$f" 'rm -rf /etc/mssql-provision-kit || true'
assert_contains "$f" 'rm -rf /var/lib/mssql-provision-kit || true'
assert_contains "$f" 'rm -rf /var/log/mssql-provision-kit || true'

echo "uninstall guard checks passed"
