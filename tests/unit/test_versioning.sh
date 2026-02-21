#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

assert_file_exists "$ROOT_DIR/VERSION"
assert_regex "$ROOT_DIR/VERSION" '^[0-9]+\.[0-9]+\.[0-9]+$'

assert_contains "$ROOT_DIR/provision" 'VERSION_FILE="$BASE_DIR/VERSION"'
assert_contains "$ROOT_DIR/provision" 'echo " MSSQL Provision Kit v$VERSION"'
assert_contains "$ROOT_DIR/install.sh" 'Install complete: ${KIT_NAME} v${VERSION}'

echo "versioning checks passed"