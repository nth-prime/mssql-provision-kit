#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

cfg="$ROOT_DIR/config/provision.conf.example"
assert_file_exists "$cfg"

assert_contains "$cfg" 'TARGET_SQL_MAJOR="2025"'
assert_contains "$cfg" 'SUPPORTED_OS_ID="ubuntu"'
assert_contains "$cfg" 'SUPPORTED_OS_VERSION="24.04"'
assert_contains "$cfg" 'VERSION_STRATEGY="latest"'
assert_contains "$cfg" 'MSSQL_EDITION="Developer"'
assert_contains "$cfg" 'PROMPT_FOR_SA_PASSWORD="1"'
assert_contains "$cfg" 'VOLUMES="v1 v2 v3 v4"'
assert_contains "$cfg" 'SQL_DATA_VOLUME="v1"'
assert_contains "$cfg" 'SQL_LOG_VOLUME="v2"'
assert_contains "$cfg" 'SQL_BACKUP_VOLUME="v3"'
assert_contains "$cfg" 'SQL_TEMPDB_VOLUME="v4"'

# Ensure Linux mount-style defaults are present for D/L/B/T role intent.
assert_contains "$cfg" 'VOLUME_v1_MOUNT="/mnt/d"'
assert_contains "$cfg" 'VOLUME_v2_MOUNT="/mnt/l"'
assert_contains "$cfg" 'VOLUME_v3_MOUNT="/mnt/b"'
assert_contains "$cfg" 'VOLUME_v4_MOUNT="/mnt/t"'

echo "config defaults checks passed"