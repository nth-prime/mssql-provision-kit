#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root

read -rp "Restart this machine immediately? (y/n): " yn
[[ "$yn" =~ ^[yY]$ ]] || exit 0

log "Restarting machine now"
systemctl reboot