#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

usage() {
  echo "Usage: $0 [--dry-run|--apply]"
}

wait_for_unit_active() {
  local timeout_s="${1:-180}"
  local interval_s="${2:-5}"
  local waited=0
  local state

  while (( waited < timeout_s )); do
    state="$(systemctl is-active mssql-server 2>/dev/null || true)"
    case "$state" in
      active)
        log "mssql-server unit state is active."
        return 0
        ;;
      activating|deactivating|reloading)
        log "mssql-server unit state: ${state} (${waited}/${timeout_s}s)"
        ;;
      failed|inactive|"")
        log "mssql-server unit state: ${state:-unknown} (${waited}/${timeout_s}s)"
        ;;
      *)
        log "mssql-server unit state: $state (${waited}/${timeout_s}s)"
        ;;
    esac
    sleep "$interval_s"
    waited=$((waited + interval_s))
  done
  return 1
}

recover_mssql_service() {
  log "Attempting mssql-server recovery sequence (stop/kill/reset-failed/start)"
  systemctl stop mssql-server || true
  sleep 2
  systemctl kill -s SIGKILL mssql-server || true
  pkill -9 -f /opt/mssql/bin/sqlservr || true
  systemctl reset-failed mssql-server || true
  systemctl start mssql-server || die "Unable to start mssql-server after recovery sequence"
  wait_for_unit_active 180 5 || die "mssql-server did not reach active state after recovery sequence"
}

restart_mssql_resilient() {
  log "Restarting mssql-server (non-blocking)"
  systemctl restart --no-block mssql-server || true
  if ! wait_for_unit_active 180 5; then
    log "mssql-server restart did not converge; attempting recovery"
    recover_mssql_service
  fi
}

wait_for_sql_ready() {
  local sqlcmd_bin="$1"
  local sa_pw="$2"
  local timeout_s="${3:-180}"
  local interval_s="${4:-5}"
  local waited=0
  local attempt=0

  log "Waiting for SQL Server to accept connections (timeout: ${timeout_s}s, interval: ${interval_s}s)"
  while (( waited < timeout_s )); do
    attempt=$((attempt + 1))
    log "Probe attempt ${attempt}: checking SQL connectivity on localhost"
    if command -v timeout >/dev/null 2>&1; then
      if timeout 8 "$sqlcmd_bin" -l 3 -S localhost -U sa -P "$sa_pw" -Q "SELECT 1" >/dev/null 2>&1; then
        log "SQL Server is accepting connections."
        return 0
      fi
    elif "$sqlcmd_bin" -l 3 -S localhost -U sa -P "$sa_pw" -Q "SELECT 1" >/dev/null 2>&1; then
      log "SQL Server is accepting connections."
      return 0
    fi
    waited=$((waited + interval_s))
    log "Still waiting for SQL Server... (${waited}/${timeout_s}s)"
    sleep "$interval_s"
  done

  die "SQL Server did not become ready within ${timeout_s}s"
}

sql_escape_literal() {
  local v="$1"
  echo "${v//\'/\'\'}"
}

sql_escape_identifier() {
  local v="$1"
  echo "${v//]/]]}"
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
run_cmd "$dry_run" bash -c "curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/prod.list > /etc/apt/sources.list.d/msprod.list"
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

# sqlcmd is required for creating the mandatory sysadmin login and post-install actions.
if [[ "$dry_run" == "1" ]]; then
  log "DRY-RUN: would install sqlcmd tools from Microsoft prod repo."
  log "DRY-RUN: ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev"
else
  if ! ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev; then
    log "mssql-tools18 not found, trying mssql-tools fallback"
    ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev || die "Unable to install sqlcmd tools"
  fi
fi

pid="Developer"
if [[ "$edition" == "Standard" ]]; then
  pid="$product_key"
fi

if [[ "$dry_run" == "1" ]]; then
  log "DRY-RUN: would run mssql-conf with PID and SA password (redacted)."
  log "DRY-RUN: would set default data/log/backup paths via mssql-conf."
  log "DRY-RUN: would restart mssql-server and wait for readiness before sqlcmd actions."
else
  MSSQL_PID="$pid" ACCEPT_EULA=Y MSSQL_SA_PASSWORD="$sa_pw" /opt/mssql/bin/mssql-conf -n setup
  /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir "$data_path"
  /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir "$log_path"
  /opt/mssql/bin/mssql-conf set filelocation.defaultbackupdir "$backup_path"
  mkdir -p "$tempdb_path"
  chown -R mssql:mssql "$storage_root"
  restart_mssql_resilient
fi

if [[ "$dry_run" == "0" ]]; then
  sqlcmd_bin="/opt/mssql-tools18/bin/sqlcmd"
  if [[ ! -x "$sqlcmd_bin" ]]; then
    sqlcmd_bin="/opt/mssql-tools/bin/sqlcmd"
  fi
  [[ -x "$sqlcmd_bin" ]] || die "sqlcmd not found at /opt/mssql-tools18/bin/sqlcmd or /opt/mssql-tools/bin/sqlcmd"

  wait_for_sql_ready "$sqlcmd_bin" "$sa_pw" 180 5

  login_esc="$(sql_escape_identifier "$sys_login")"
  pw_esc="$(sql_escape_literal "$sys_pw")"
  temp_path_esc="$(sql_escape_literal "$tempdb_path")"

  q="CREATE LOGIN [$login_esc] WITH PASSWORD=N'$pw_esc', DEFAULT_DATABASE=[master], CHECK_POLICY=ON; ALTER SERVER ROLE [sysadmin] ADD MEMBER [$login_esc];"
  "$sqlcmd_bin" -S localhost -U sa -P "$sa_pw" -Q "$q"

  # Set tempdb primary file/log locations to the configured directory.
  "$sqlcmd_bin" -S localhost -U sa -P "$sa_pw" -Q "ALTER DATABASE [tempdb] MODIFY FILE (NAME = N'tempdev', FILENAME = N'$temp_path_esc/tempdb.mdf'); ALTER DATABASE [tempdb] MODIFY FILE (NAME = N'templog', FILENAME = N'$temp_path_esc/templog.ldf');"

  restart_mssql_resilient
  wait_for_sql_ready "$sqlcmd_bin" "$sa_pw" 180 5
fi

log "Install workflow complete."
