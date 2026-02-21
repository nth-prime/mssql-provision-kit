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
assert_contains "$cfg" 'MSSQL_PROVISION_KIT_REPO_URL="https://github.com/nth-prime/mssql-provision-kit"'
assert_contains "$cfg" 'MSSQL_PROVISION_KIT_BRANCH="main"'
assert_contains "$cfg" 'MSSQL_EDITION="Developer"'
assert_contains "$cfg" 'PROMPT_FOR_SA_PASSWORD="1"'

assert_contains "$cfg" 'SQL_STORAGE_ROOT="/var/opt/mssql"'
assert_contains "$cfg" 'SQL_DATA_PATH="/var/opt/mssql/data"'
assert_contains "$cfg" 'SQL_LOG_PATH="/var/opt/mssql/log"'
assert_contains "$cfg" 'SQL_BACKUP_PATH="/var/opt/mssql/backup"'
assert_contains "$cfg" 'SQL_TEMPDB_PATH="/var/opt/mssql/tempdb"'
assert_contains "$cfg" 'SQL_TCP_PORT="1433"'
assert_contains "$cfg" 'NETWORK_ENFORCE_WHITELIST="1"'
assert_contains "$cfg" 'NETWORK_ALLOWED_IPV4=""'
assert_contains "$cfg" 'NETWORK_ALLOWED_IPV6=""'
assert_contains "$cfg" 'NETWORK_ALLOW_TAILSCALE="1"'
assert_contains "$cfg" 'NETWORK_TAILSCALE_INTERFACE="tailscale0"'
assert_contains "$cfg" 'NETWORK_ALLOWED_IPV6=""'

echo "config defaults checks passed"
