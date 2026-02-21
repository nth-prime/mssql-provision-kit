#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

log "Running non-destructive filesystem health checks..."
for id in $(volume_ids); do
  dev="$(volume_key "$id" DEVICE)"
  fs="$(volume_key "$id" FS)"
  mnt="$(volume_key "$id" MOUNT)"
  echo "[$id] device=$dev fs=$fs mount=$mnt"
  sig="$(blkid -o value -s TYPE "$dev" 2>/dev/null || true)"
  echo "  detected_fs=${sig:-unknown}"
  if findmnt -n "$mnt" >/dev/null 2>&1; then
    echo "  mount_status=mounted"
  else
    echo "  mount_status=not-mounted"
  fi
  if [[ "$fs" == "ext4" && -b "$dev" ]]; then
    echo "  check=e2fsck -n"
  elif [[ "$fs" == "xfs" && -b "$dev" ]]; then
    echo "  check=xfs_repair -n (must be unmounted to run safely)"
  fi
done