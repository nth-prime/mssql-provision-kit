#!/usr/bin/env bash
set -euo pipefail

KIT_NAME="mssql-provision-kit"
BASE_DIR="/opt/${KIT_NAME}"
CONFIG_FILE="/etc/${KIT_NAME}/provision.conf"
STATE_DIR="/var/lib/${KIT_NAME}/state"
LOG_DIR="/var/log/${KIT_NAME}"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log() {
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "[$ts] $*" | tee -a "$LOG_DIR/kit.log"
}

die() {
  log "ERROR: $*"
  exit 1
}

require_root() {
  [[ $(id -u) -eq 0 ]] || die "Run as root/sudo."
}

load_config() {
  [[ -f "$CONFIG_FILE" ]] || die "Missing config: $CONFIG_FILE"
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
}

config_get() {
  local key="$1"
  local line
  line="$(grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n1 || true)"
  [[ -n "$line" ]] || return 0
  echo "$line" | sed -E 's/^[^=]+=//; s/^"//; s/"$//'
}

config_set() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}=" "$CONFIG_FILE"; then
    sed -i "s|^${key}=.*$|${key}=\"${value}\"|" "$CONFIG_FILE"
  else
    echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
  fi
}

is_ubuntu_24() {
  [[ -f /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "24.04" ]]
}

run_cmd() {
  local dry_run="$1"
  shift
  if [[ "$dry_run" == "1" ]]; then
    log "DRY-RUN: $*"
  else
    log "RUN: $*"
    "$@"
  fi
}

require_cmds() {
  local missing=0
  for c in "$@"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      log "Missing command: $c"
      missing=1
    fi
  done
  [[ $missing -eq 0 ]] || die "Install missing dependencies and retry."
}

path_is_within_root() {
  local root="$1"
  local child="$2"
  [[ "$child" == "$root" || "$child" == "$root/"* ]]
}

ensure_sql_paths_from_root() {
  local root data logp back temp
  root="$(config_get SQL_STORAGE_ROOT)"
  if [[ -z "$root" ]]; then
    root="/var/opt/mssql"
  fi
  # Reject malformed root values from legacy/bad config edits.
  if [[ "$root" == *"\""* || "$root" == *"="* || "$root" != /* ]]; then
    root="/var/opt/mssql"
  fi
  config_set SQL_STORAGE_ROOT "$root"

  data="$(config_get SQL_DATA_PATH)"
  logp="$(config_get SQL_LOG_PATH)"
  back="$(config_get SQL_BACKUP_PATH)"
  temp="$(config_get SQL_TEMPDB_PATH)"

  [[ -n "$data" && "$data" == /* && "$data" != *"\""* && "$data" != *"="* ]] || data="$root/data"
  [[ -n "$logp" && "$logp" == /* && "$logp" != *"\""* && "$logp" != *"="* ]] || logp="$root/log"
  [[ -n "$back" && "$back" == /* && "$back" != *"\""* && "$back" != *"="* ]] || back="$root/backup"
  [[ -n "$temp" && "$temp" == /* && "$temp" != *"\""* && "$temp" != *"="* ]] || temp="$root/tempdb"

  config_set SQL_DATA_PATH "$data"
  config_set SQL_LOG_PATH "$logp"
  config_set SQL_BACKUP_PATH "$back"
  config_set SQL_TEMPDB_PATH "$temp"
}
