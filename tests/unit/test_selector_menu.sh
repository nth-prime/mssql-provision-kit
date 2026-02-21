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
assert_contains "$selector" 'echo "6) Storage Layout"'
assert_contains "$selector" 'echo "7) Uninstall / Cleanup"'
assert_contains "$selector" 'echo "8) Show State + Logs"'
assert_contains "$selector" 'echo "9) Run Unit Tests"'
assert_contains "$selector" 'echo "10) Restart Machine Now"'
assert_contains "$selector" 'echo "11) Update Provision Kit from GitHub"'
assert_contains "$selector" 'echo "12) Run Network Validation"'
assert_contains "$selector" 'echo "13) Print Effective Config"'

assert_contains "$selector" '3) run_sector_safe "$SECTOR_DIR/20-install-sql.sh" --dry-run ;;'
assert_contains "$selector" '4) run_sector_safe "$SECTOR_DIR/20-install-sql.sh" --apply ;;'
assert_contains "$selector" '7) run_sector_safe "$SECTOR_DIR/80-uninstall-cleanup.sh" ;;'
assert_contains "$selector" '9) run_sector_safe "$SECTOR_DIR/50-run-unit-tests.sh" ;;'
assert_contains "$selector" '10) run_sector_safe "$SECTOR_DIR/85-restart-now.sh" ;;'
assert_contains "$selector" '11) run_sector_safe "$SECTOR_DIR/05-update-kit.sh" ;;'
assert_contains "$selector" '12) run_sector_safe "$SECTOR_DIR/31-network-validate.sh" ;;'
assert_contains "$selector" '13) run_sector_safe "$SECTOR_DIR/92-print-effective-config.sh" ;;'

echo "selector menu checks passed"
