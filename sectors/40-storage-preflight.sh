#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

log "Running storage preflight..."
is_ubuntu_24 || die "Unsupported OS. Requires Ubuntu 24.04"
require_cmds lsblk blkid findmnt df awk sed grep mount umount

for id in $(volume_ids); do
  dev="$(volume_key "$id" DEVICE)"
  fs="$(volume_key "$id" FS)"
  mnt="$(volume_key "$id" MOUNT)"
  [[ -n "$dev" && -n "$fs" && -n "$mnt" ]] || die "Incomplete volume config for $id"
  [[ "$fs" == "xfs" || "$fs" == "ext4" ]] || die "Unsupported FS for $id: $fs"
  if [[ ! -b "$dev" && ! -e "$dev" ]]; then
    die "Device path not found for $id: $dev"
  fi
done

log "Storage preflight passed."