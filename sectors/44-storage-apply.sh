#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
[[ -f "$PLAN_FILE" ]] || die "Missing plan file: $PLAN_FILE. Run 43-storage-plan first."

# shellcheck disable=SC1090
source "$PLAN_FILE"

dry_run=1
mount_only=0
for a in "$@"; do
  [[ "$a" == "--apply" ]] && dry_run=0
  [[ "$a" == "--dry-run" ]] && dry_run=1
  [[ "$a" == "--mount-only" ]] && mount_only=1
done

if [[ "$dry_run" == "0" ]]; then
  read -rp "Type apply to continue: " typed
  [[ "$typed" == "apply" ]] || die "Apply cancelled"
fi

tx="$(begin_tx storage-apply)"
cp -a "$PLAN_FILE" "$tx/plan.used"

for id in $VOLUMES; do
  dev_var="VOLUME_${id}_DEVICE"
  fs_var="VOLUME_${id}_FS"
  mnt_var="VOLUME_${id}_MOUNT"
  mkfs_var="VOLUME_${id}_MKFS_OPTS"
  opts_var="VOLUME_${id}_MOUNT_OPTS"

  dev="${!dev_var}"
  fs="${!fs_var}"
  mnt="${!mnt_var}"
  mkfs_opts="${!mkfs_var}"
  mnt_opts="${!opts_var}"

  run_cmd "$dry_run" mkdir -p "$mnt"

  if [[ "$mount_only" == "0" ]]; then
    existing="$(blkid -o value -s TYPE "$dev" 2>/dev/null || true)"
    if [[ -z "$existing" ]]; then
      if [[ "$fs" == "xfs" ]]; then
        run_cmd "$dry_run" mkfs.xfs -f $mkfs_opts "$dev"
      else
        run_cmd "$dry_run" mkfs.ext4 -F $mkfs_opts "$dev"
      fi
    else
      log "Skipping mkfs on $dev (existing fs: $existing)"
    fi
  fi

  uuid="$(blkid -o value -s UUID "$dev" 2>/dev/null || true)"
  [[ -n "$uuid" ]] || { [[ "$dry_run" == "1" ]] || die "No UUID found for $dev"; uuid="DRYRUN-${id}"; }

  if ! grep -q "$mnt" /etc/fstab; then
    line="UUID=$uuid $mnt $fs ${mnt_opts:-defaults,nofail} 0 2"
    if [[ "$dry_run" == "1" ]]; then
      log "DRY-RUN: append fstab -> $line"
    else
      echo "$line" >> /etc/fstab
    fi
  else
    log "fstab already contains mount $mnt; leaving unchanged"
  fi

  run_cmd "$dry_run" mount "$mnt"
  if [[ "$dry_run" == "0" ]]; then
    touch "$tx/mounted.$id"
  fi
done

log "Storage apply completed. tx=$tx"