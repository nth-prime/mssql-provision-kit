#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/80-uninstall-cleanup.sh"
assert_file_exists "$f"

assert_contains "$f" 'read -rp "Type uninstall to proceed: " typed'
assert_contains "$f" '[[ "$typed" == "uninstall" ]] || die "Uninstall cancelled"'
assert_not_contains "$f" 'load_config'
assert_not_contains "$f" 'rm -rf /opt/mssql-provision-kit || true'
assert_not_contains "$f" 'rm -rf /etc/mssql-provision-kit || true'
assert_not_contains "$f" 'rm -rf /var/lib/mssql-provision-kit || true'
assert_not_contains "$f" 'rm -rf /var/log/mssql-provision-kit || true'
assert_contains "$f" 'apt-get remove -y mssql-server || true'
assert_contains "$f" 'rm -rf /var/opt/mssql || true'
assert_contains "$f" 'rm -rf /opt/mssql || true'
assert_contains "$f" 'rm -f /etc/apt/sources.list.d/mssql-server-2025.list || true'
assert_contains "$f" 'rm -f /etc/apt/sources.list.d/msprod.list || true'

echo "uninstall guard checks passed"
