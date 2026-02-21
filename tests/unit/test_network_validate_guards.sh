#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/31-network-validate.sh"
assert_file_exists "$f"

assert_contains "$f" 'ensure_network_defaults'
assert_contains "$f" '== Effective network config =='
assert_contains "$f" '== Listener check =='
assert_contains "$f" '== Firewall check (ufw) =='
assert_contains "$f" '== Tailscale exposure check =='
assert_contains "$f" 'NETWORK_ALLOW_TAILSCALE=1 but interface $ts_if is missing'
assert_contains "$f" 'NETWORK_ALLOW_TAILSCALE=1 but no SQL port allow rule found on interface $ts_if'
assert_contains "$f" 'NETWORK_ALLOW_TAILSCALE=0 but SQL port rule still allows interface $ts_if'
assert_contains "$f" 'Tailscale SQL exposure enabled and validated.'
assert_contains "$f" 'Tailscale SQL exposure disabled and validated.'
assert_contains "$f" 'Whitelist enforcement enabled but NETWORK_ALLOWED_IPV4/IPv6 are empty'
assert_contains "$f" 'Broad SQL port allow rule found (Anywhere) while whitelist enforcement is enabled'
assert_contains "$f" 'Whitelist enforcement checks passed.'
assert_contains "$f" 'Network validation complete.'

echo "network validation guard checks passed"
