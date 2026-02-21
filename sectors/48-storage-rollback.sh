#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

tx="$(latest_tx)"
[[ -n "$tx" ]] || die "No transaction found."

log "Latest transaction: $tx"
read -rp "Type rollback to restore last transaction: " typed
[[ "$typed" == "rollback" ]] || die "Rollback cancelled"

if [[ -f "$tx/fstab.before" ]]; then
  cp -a "$tx/fstab.before" /etc/fstab
  log "Restored /etc/fstab from transaction snapshot."
else
  die "No fstab backup in transaction."
fi

# Best effort: unmount only mounts touched by this transaction plan.
if [[ -f "$tx/plan.used" ]]; then
  # shellcheck disable=SC1090
  source "$tx/plan.used"
  for id in $VOLUMES; do
    mnt_var="VOLUME_${id}_MOUNT"
    mnt="${!mnt_var:-}"
    if [[ -n "$mnt" ]] && findmnt -n "$mnt" >/dev/null 2>&1; then
      umount "$mnt" 2>/dev/null || true
    fi
  done
fi

mount -a

log "Rollback completed for $tx"
