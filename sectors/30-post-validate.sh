#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
ensure_sql_paths_from_root

log "Running post-install validation..."
require_cmds systemctl awk sed grep df du find ls stat

systemctl is-active --quiet mssql-server || die "mssql-server is not active"

storage_root="$(config_get SQL_STORAGE_ROOT)"
data_path="$(config_get SQL_DATA_PATH)"
log_path="$(config_get SQL_LOG_PATH)"
backup_path="$(config_get SQL_BACKUP_PATH)"
tempdb_path="$(config_get SQL_TEMPDB_PATH)"

sqlcmd_bin=""
if [[ -x /opt/mssql-tools18/bin/sqlcmd ]]; then
  sqlcmd_bin="/opt/mssql-tools18/bin/sqlcmd"
elif [[ -x /opt/mssql-tools/bin/sqlcmd ]]; then
  sqlcmd_bin="/opt/mssql-tools/bin/sqlcmd"
fi

echo
echo "== Service status =="
echo "active: $(systemctl is-active mssql-server 2>/dev/null || true)"
echo "enabled: $(systemctl is-enabled mssql-server 2>/dev/null || true)"
systemctl status mssql-server --no-pager -l | sed -n '1,20p'

echo
echo "== Connectivity tooling =="
if [[ -n "$sqlcmd_bin" ]]; then
  echo "sqlcmd: $sqlcmd_bin"
else
  echo "sqlcmd: not found"
fi

if command -v ss >/dev/null 2>&1; then
  echo "listener check (:1433):"
  ss -ltn | awk 'NR==1 || /:1433[[:space:]]/' || true
fi

echo
echo "== Configured SQL paths =="
echo "root   : $storage_root"
echo "data   : $data_path"
echo "log    : $log_path"
echo "backup : $backup_path"
echo "tempdb : $tempdb_path"

echo
echo "== Directory permissions and usage =="
for p in "$storage_root" "$data_path" "$log_path" "$backup_path" "$tempdb_path"; do
  if [[ -e "$p" ]]; then
    stat -c '%A %U:%G %n' "$p"
    du -sh "$p" 2>/dev/null || true
    df -hT "$p" | sed -n '1,2p'
  else
    echo "MISSING: $p"
  fi
  echo "---"
done

echo
echo "== Database and backup files (top-level) =="
for p in "$data_path" "$tempdb_path" "$backup_path"; do
  [[ -d "$p" ]] || continue
  echo "Path: $p"
  find "$p" -maxdepth 1 -type f \( -name '*.mdf' -o -name '*.ndf' -o -name '*.ldf' -o -name '*.bak' \) -print | sed -n '1,200p'
  echo "---"
done

if [[ -n "$sqlcmd_bin" ]]; then
  echo
  read -rp "Run SQL catalog checks with SA credentials? (y/N): " run_sql
  if [[ "$run_sql" =~ ^[yY]$ ]]; then
    read -rsp "Enter SA password for SQL checks: " sa_pw
    echo

    echo "== SQL server identity =="
    "$sqlcmd_bin" -l 3 -S localhost -U sa -P "$sa_pw" -Q "SET NOCOUNT ON; SELECT @@SERVERNAME AS server_name, SERVERPROPERTY('Edition') AS edition, SERVERPROPERTY('ProductVersion') AS product_version, SERVERPROPERTY('ProductLevel') AS product_level;" || die "SQL identity query failed"

    echo
    echo "== Database size summary (MB) =="
    "$sqlcmd_bin" -l 3 -S localhost -U sa -P "$sa_pw" -Q "SET NOCOUNT ON; SELECT d.name AS db_name, CAST(SUM(CASE WHEN mf.type_desc='ROWS' THEN mf.size ELSE 0 END)*8.0/1024 AS DECIMAL(18,1)) AS data_mb, CAST(SUM(CASE WHEN mf.type_desc='LOG' THEN mf.size ELSE 0 END)*8.0/1024 AS DECIMAL(18,1)) AS log_mb FROM sys.master_files mf JOIN sys.databases d ON d.database_id = mf.database_id GROUP BY d.name ORDER BY d.name;" || die "Database size query failed"
  else
    echo "SQL catalog checks skipped."
  fi
fi

log "Validation complete."