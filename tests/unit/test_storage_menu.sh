#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

selector="$ROOT_DIR/provision"
assert_file_exists "$selector"

assert_contains "$selector" 'echo " Drive Provisioning"'
assert_contains "$selector" 'echo "1) Run Storage Preflight"'
assert_contains "$selector" 'echo "5) Build Provisioning Plan (Interactive)"'
assert_contains "$selector" 'echo "6) Preview Plan (Dry-Run)"'
assert_contains "$selector" 'echo "7) Apply Plan: Partition + Format + Mount"'
assert_contains "$selector" 'echo "8) Apply Plan: Mount + Fstab Only"'
assert_contains "$selector" 'echo "12) Rollback Last Provisioning Transaction"'
assert_contains "$selector" 'echo "13) Advanced Tools (Expert Mode)"'

assert_contains "$selector" '1) run_sector "$SECTOR_DIR/40-storage-preflight.sh" ;;'
assert_contains "$selector" '5) run_sector "$SECTOR_DIR/43-storage-plan.sh" ;;'
assert_contains "$selector" '6) run_sector "$SECTOR_DIR/44-storage-apply.sh" --dry-run ;;'
assert_contains "$selector" '8) run_sector "$SECTOR_DIR/44-storage-apply.sh" --apply --mount-only ;;'
assert_contains "$selector" '12) run_sector "$SECTOR_DIR/48-storage-rollback.sh" ;;'

echo "storage menu checks passed"