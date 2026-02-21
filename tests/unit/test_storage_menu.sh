#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

selector="$ROOT_DIR/provision"
assert_file_exists "$selector"

assert_contains "$selector" 'echo " Storage Layout"'
assert_contains "$selector" 'echo "1) Run Storage Preflight"'
assert_contains "$selector" 'echo "2) Inspect Storage and Filesystems"'
assert_contains "$selector" 'echo "3) Run Storage Health Checks"'
assert_contains "$selector" 'echo "4) Preview SQL Directory Layout (Dry-Run)"'
assert_contains "$selector" 'echo "5) Apply SQL Directory Layout"'
assert_contains "$selector" 'echo "6) Validate SQL Directory Layout"'
assert_contains "$selector" 'echo "7) Export Storage Report"'

assert_contains "$selector" '1) run_sector "$SECTOR_DIR/40-storage-preflight.sh" ;;'
assert_contains "$selector" '4) run_sector "$SECTOR_DIR/43-storage-layout.sh" --dry-run ;;'
assert_contains "$selector" '5) run_sector "$SECTOR_DIR/43-storage-layout.sh" --apply ;;'
assert_contains "$selector" '6) run_sector "$SECTOR_DIR/44-storage-validate.sh" ;;'
assert_contains "$selector" '7) run_sector "$SECTOR_DIR/47-storage-report.sh" ;;'

echo "storage menu checks passed"