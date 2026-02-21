#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/32-network-apply.sh"
assert_file_exists "$f"

assert_contains "$f" 'ensure_network_defaults'
assert_contains "$f" 'Type apply to configure UFW SQL rules: '
assert_contains "$f" 'ufw --force enable'
assert_contains "$f" 'Removing existing UFW rules for SQL port'
assert_contains "$f" 'ufw allow in on "$ts_if" to any port "$sql_port" proto tcp'
assert_contains "$f" 'ufw allow from "$cidr" to any port "$sql_port" proto tcp'
assert_contains "$f" 'Network policy apply complete.'

echo "network apply guard checks passed"