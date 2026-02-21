#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

f="$ROOT_DIR/sectors/20-install-sql.sh"
assert_file_exists "$f"

assert_contains "$f" 'Usage: $0 [--dry-run|--apply]'
assert_contains "$f" 'VERSION_STRATEGY'
assert_contains "$f" 'PROMPT_FOR_SA_PASSWORD'
assert_contains "$f" 'Sysadmin login name'
assert_contains "$f" 'DRY-RUN: would run mssql-conf with PID and SA password (redacted).'
assert_contains "$f" 'sql_escape_literal()'
assert_contains "$f" 'sql_escape_identifier()'
assert_contains "$f" 'wait_for_sql_ready()'
assert_contains "$f" 'wait_for_unit_active()'
assert_contains "$f" 'recover_mssql_service()'
assert_contains "$f" 'restart_mssql_resilient()'
assert_contains "$f" 'timeout 8 "$sqlcmd_bin" -C -l 3 -S localhost -U sa -P "$sa_pw" -Q "SELECT 1"'
assert_contains "$f" 'config/ubuntu/24.04/prod.list'
assert_contains "$f" 'apt-get install -y mssql-tools18 unixodbc-dev'
assert_contains "$f" 'apt-get install -y mssql-tools unixodbc-dev || die "Unable to install sqlcmd tools"'
assert_contains "$f" 'ALTER DATABASE [tempdb] MODIFY FILE'
assert_contains "$f" 'sqlcmd not found at /opt/mssql-tools18/bin/sqlcmd or /opt/mssql-tools/bin/sqlcmd'
assert_contains "$f" 'Still waiting for SQL Server...'
assert_contains "$f" 'systemctl restart --no-block mssql-server'
assert_contains "$f" 'mssql-server restart did not converge; attempting recovery'
assert_contains "$f" 'wait_for_sql_ready "$sqlcmd_bin" "$sa_pw" 180 5'

echo "install flow guard checks passed"
