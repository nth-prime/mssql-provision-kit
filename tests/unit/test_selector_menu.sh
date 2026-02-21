#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

selector="$ROOT_DIR/provision"
assert_file_exists "$selector"

assert_contains "$selector" 'echo "1) Edit Config"'
assert_contains "$selector" 'echo "2) Run Host + SQL Preflight"'
assert_contains "$selector" 'echo "3) Dry-Run Install Plan"'
assert_contains "$selector" 'echo "4) Install SQL Server 2025"'
assert_contains "$selector" 'echo "6) Drive Provisioning"'
assert_contains "$selector" 'echo "7) Uninstall / Cleanup"'
assert_contains "$selector" 'echo "8) Show State + Logs"'

assert_contains "$selector" '3) run_sector "$SECTOR_DIR/20-install-sql.sh" --dry-run ;;'
assert_contains "$selector" '4) run_sector "$SECTOR_DIR/20-install-sql.sh" --apply ;;'
assert_contains "$selector" '7) run_sector "$SECTOR_DIR/80-uninstall-cleanup.sh" ;;'

echo "selector menu checks passed"