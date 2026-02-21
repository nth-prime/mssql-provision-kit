#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

libf="$ROOT_DIR/lib/lib.sh"
health="$ROOT_DIR/sectors/42-storage-health.sh"
validate="$ROOT_DIR/sectors/44-storage-validate.sh"

assert_file_exists "$libf"
assert_file_exists "$health"
assert_file_exists "$validate"

# config_get must tolerate missing keys on upgraded configs.
assert_contains "$libf" 'line="$(grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n1 || true)"'

# Strict path boundary helper must exist and be used by health/validate sectors.
assert_contains "$libf" 'path_is_within_root()'
assert_contains "$health" 'path_is_within_root "$root" "$p" || die "$key must be under SQL_STORAGE_ROOT ($root)"'
assert_contains "$validate" 'path_is_within_root "$root" "$p" || die "$key is outside SQL_STORAGE_ROOT"'

echo "lib and path guard checks passed"