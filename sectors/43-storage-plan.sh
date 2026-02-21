#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

mkdir -p "$STATE_DIR"

read -rp "How many volumes to define? [4]: " count
count="${count:-4}"
[[ "$count" =~ ^[0-9]+$ ]] || die "Invalid count"

new_ids=()
for ((i=1; i<=count; i++)); do
  id="v${i}"
  new_ids+=("$id")
  read -rp "[$id] Device path: " dev
  read -rp "[$id] FS (xfs/ext4) [xfs]: " fs
  fs="${fs:-xfs}"
  read -rp "[$id] Mount path [/mnt/${id}]: " mnt
  mnt="${mnt:-/mnt/${id}}"
  read -rp "[$id] mkfs opts (optional): " mkfs_opts
  read -rp "[$id] mount opts [defaults,nofail]: " mnt_opts
  mnt_opts="${mnt_opts:-defaults,nofail}"

  [[ "$fs" == "xfs" || "$fs" == "ext4" ]] || die "Invalid fs for $id"
  [[ -n "$dev" && -n "$mnt" ]] || die "Device and mount required"

  config_set "VOLUME_${id}_DEVICE" "$dev"
  config_set "VOLUME_${id}_FS" "$fs"
  config_set "VOLUME_${id}_MOUNT" "$mnt"
  config_set "VOLUME_${id}_MKFS_OPTS" "$mkfs_opts"
  config_set "VOLUME_${id}_MOUNT_OPTS" "$mnt_opts"
done

config_set VOLUMES "${new_ids[*]}"

cat > "$PLAN_FILE" <<EOF
PLAN_CREATED_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
VOLUMES="${new_ids[*]}"
EOF

for id in "${new_ids[@]}"; do
  echo "VOLUME_${id}_DEVICE=\"$(volume_key "$id" DEVICE)\"" >> "$PLAN_FILE"
  echo "VOLUME_${id}_FS=\"$(volume_key "$id" FS)\"" >> "$PLAN_FILE"
  echo "VOLUME_${id}_MOUNT=\"$(volume_key "$id" MOUNT)\"" >> "$PLAN_FILE"
  echo "VOLUME_${id}_MKFS_OPTS=\"$(volume_key "$id" MKFS_OPTS)\"" >> "$PLAN_FILE"
  echo "VOLUME_${id}_MOUNT_OPTS=\"$(volume_key "$id" MOUNT_OPTS)\"" >> "$PLAN_FILE"
done

log "Saved plan to $PLAN_FILE"