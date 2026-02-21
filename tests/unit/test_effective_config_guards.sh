#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/92-print-effective-config.sh"
assert_file_exists "$f"
assert_contains "$f" 'ensure_sql_paths_from_root'
assert_contains "$f" 'ensure_network_defaults'
assert_contains "$f" '== Effective config: /etc/mssql-provision-kit/provision.conf =='
assert_contains "$f" "awk 'NF && \$1 !~ /^#/' \"\$CONFIG_FILE\""

echo "effective config guard checks passed"