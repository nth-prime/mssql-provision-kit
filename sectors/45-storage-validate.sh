#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

log "Validating provisioned volumes..."
for id in $(volume_ids); do
  mnt="$(volume_key "$id" MOUNT)"
  [[ -n "$mnt" ]] || die "Missing mount for $id"
  findmnt -n "$mnt" >/dev/null 2>&1 || die "Not mounted: $mnt"
  probe="$mnt/.mssql-provision-write-test"
  echo "ok $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$probe"
  rm -f "$probe"
  grep -q "$mnt" /etc/fstab || die "Mount missing in fstab: $mnt"
  log "Validated: $id -> $mnt"
done

log "Validation successful."