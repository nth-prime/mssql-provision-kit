#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

usage() {
  echo "Usage: $0 [--dry-run|--apply]"
}

require_root
load_config

mode="${1:---dry-run}"
dry_run=1
[[ "$mode" == "--apply" ]] && dry_run=0
[[ "$mode" == "--dry-run" || "$mode" == "--apply" ]] || { usage; exit 1; }

is_ubuntu_24 || die "Unsupported OS. Requires Ubuntu 24.04."
require_cmds curl gpg apt-get systemctl

strategy="$(config_get VERSION_STRATEGY)"
edition="$(config_get MSSQL_EDITION)"

if [[ "$edition" != "Developer" && "$edition" != "Standard" ]]; then
  die "MSSQL_EDITION must be Developer or Standard"
fi

sa_pw="$(config_get MSSQL_SA_PASSWORD)"
if [[ "$(config_get PROMPT_FOR_SA_PASSWORD)" == "1" ]]; then
  read -rsp "Enter SA password: " sa_pw
  echo
  read -rsp "Confirm SA password: " sa_pw2
  echo
  [[ "$sa_pw" == "$sa_pw2" ]] || die "SA passwords did not match"
fi
[[ ${#sa_pw} -ge 8 ]] || die "SA password too short"

product_key="$(config_get MSSQL_STANDARD_PRODUCT_KEY)"
if [[ "$edition" == "Standard" && -z "$product_key" ]]; then
  read -rsp "Enter SQL Server Standard product key (25 chars): " product_key
  echo
  if [[ "$(config_get ALLOW_KEY_PERSIST)" == "1" ]]; then
    config_set MSSQL_STANDARD_PRODUCT_KEY "$product_key"
    log "Persisted product key by explicit config opt-in."
  fi
fi

sys_login="$(config_get DEFAULT_SYSADMIN_LOGIN)"
read -rp "Sysadmin login name [$sys_login]: " user_input
sys_login="${user_input:-$sys_login}"
[[ -n "$sys_login" ]] || die "Sysadmin login cannot be empty"

read -rsp "Sysadmin password: " sys_pw
echo
read -rsp "Confirm sysadmin password: " sys_pw2
echo
[[ "$sys_pw" == "$sys_pw2" ]] || die "Sysadmin passwords did not match"
[[ ${#sys_pw} -ge 8 ]] || die "Sysadmin password too short"

ensure_sql_paths_from_root
storage_root="$(config_get SQL_STORAGE_ROOT)"
data_path="$(config_get SQL_DATA_PATH)"
log_path="$(config_get SQL_LOG_PATH)"
backup_path="$(config_get SQL_BACKUP_PATH)"
tempdb_path="$(config_get SQL_TEMPDB_PATH)"

log "Install mode: $mode"
log "Version strategy: $strategy"
log "Edition: $edition"
log "Sysadmin login: $sys_login"
log "SQL storage root: $storage_root"

run_cmd "$dry_run" mkdir -p "$storage_root" "$data_path" "$log_path" "$backup_path" "$tempdb_path"

# Repos and package install
run_cmd "$dry_run" bash -c "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg"
run_cmd "$dry_run" bash -c "curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list > /etc/apt/sources.list.d/mssql-server-2025.list"
run_cmd "$dry_run" apt-get update

if [[ "$strategy" == "latest" ]]; then
  run_cmd "$dry_run" apt-get install -y mssql-server
elif [[ "$strategy" == "pinned" ]]; then
  pinned="$(config_get PINNED_BUILD)"
  [[ -n "$pinned" ]] || die "PINNED_BUILD required when VERSION_STRATEGY=pinned"
  run_cmd "$dry_run" apt-get install -y "mssql-server=$pinned"
elif [[ "$strategy" == "explicit" ]]; then
  deb_url="$(config_get EXPLICIT_DEB_URL)"
  [[ -n "$deb_url" ]] || die "EXPLICIT_DEB_URL required when VERSION_STRATEGY=explicit"
  run_cmd "$dry_run" bash -c "curl -fsSL '$deb_url' -o /tmp/mssql-server.explicit.deb"
  run_cmd "$dry_run" dpkg -i /tmp/mssql-server.explicit.deb
  run_cmd "$dry_run" apt-get -f install -y
else
  die "Unknown VERSION_STRATEGY: $strategy"
fi

pid="Developer"
if [[ "$edition" == "Standard" ]]; then
  pid="$product_key"
fi

if [[ "$dry_run" == "1" ]]; then
  log "DRY-RUN: would run mssql-conf with PID and SA password (redacted)."
  log "DRY-RUN: would set default data/log/backup paths via mssql-conf."
else
  MSSQL_PID="$pid" ACCEPT_EULA=Y MSSQL_SA_PASSWORD="$sa_pw" /opt/mssql/bin/mssql-conf -n setup
  /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir "$data_path"
  /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir "$log_path"
  /opt/mssql/bin/mssql-conf set filelocation.defaultbackupdir "$backup_path"
  chown -R mssql:mssql "$storage_root"
fi

if [[ "$dry_run" == "0" ]]; then
  q="CREATE LOGIN [$sys_login] WITH PASSWORD=N'$sys_pw', DEFAULT_DATABASE=[master], CHECK_POLICY=ON; ALTER SERVER ROLE [sysadmin] ADD MEMBER [$sys_login];"
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$sa_pw" -Q "$q"

  # Best-effort tempdb relocation statement for new files.
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$sa_pw" -Q "IF DB_ID('tempdb') IS NOT NULL PRINT 'tempdb path target: $tempdb_path';"

  systemctl restart mssql-server
fi

log "Install workflow complete."