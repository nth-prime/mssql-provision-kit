#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/30-post-validate.sh"
assert_file_exists "$f"

assert_contains "$f" '== Service status =='
assert_contains "$f" '== Connectivity tooling =='
assert_contains "$f" '== Configured SQL paths =='
assert_contains "$f" '== Directory permissions and usage =='
assert_contains "$f" '== Database and backup files (top-level) =='
assert_contains "$f" 'Run SQL catalog checks with SA credentials? (y/N): '
assert_contains "$f" '== SQL server identity =='
assert_contains "$f" '== Database size summary (MB) =='
assert_contains "$f" 'Validation complete.'

echo "post-validate verbosity checks passed"