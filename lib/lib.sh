#!/usr/bin/env bash
set -euo pipefail

KIT_NAME="mssql-provision-kit"
BASE_DIR="/opt/${KIT_NAME}"
CONFIG_FILE="/etc/${KIT_NAME}/provision.conf"
STATE_DIR="/var/lib/${KIT_NAME}/state"
TX_DIR="$STATE_DIR/transactions"
LOG_DIR="/var/log/${KIT_NAME}"
PLAN_FILE="$STATE_DIR/storage-plan.conf"

mkdir -p "$STATE_DIR" "$TX_DIR" "$LOG_DIR"

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
  grep -E "^${key}=" "$CONFIG_FILE" | tail -n1 | sed -E 's/^[^=]+=//; s/^"//; s/"$//'
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

begin_tx() {
  local name="$1"
  local tx
  tx="${TX_DIR}/$(date -u +%Y%m%dT%H%M%SZ)-${name}"
  mkdir -p "$tx"
  [[ -f /etc/fstab ]] && cp -a /etc/fstab "$tx/fstab.before"
  echo "$tx"
}

latest_tx() {
  ls -1dt "$TX_DIR"/* 2>/dev/null | head -n1 || true
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

volume_ids() {
  local v
  v="$(config_get VOLUMES)"
  echo "$v"
}

volume_key() {
  local id="$1"
  local field="$2"
  config_get "VOLUME_${id}_${field}"
}

resolve_volume_device() {
  local id="$1"
  volume_key "$id" DEVICE
}