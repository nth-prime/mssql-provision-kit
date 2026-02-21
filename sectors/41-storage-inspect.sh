#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

view="${1:-all}"

log "Inspecting storage state..."
if [[ "$view" == "all" ]]; then
  lsblk -f
  echo
  blkid || true
  echo
  findmnt -lo TARGET,SOURCE,FSTYPE,OPTIONS | sed -n '1,200p'
  echo
  df -hT
else
  findmnt -lo TARGET,SOURCE,FSTYPE,OPTIONS
  echo
  df -hT
fi