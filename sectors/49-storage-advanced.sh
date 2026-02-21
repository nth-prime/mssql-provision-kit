#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root

cat <<'EOF'
Expert mode can run advanced tools and destructive commands.
Use with care.
EOF
read -rp "Type expert to continue: " typed
[[ "$typed" == "expert" ]] || die "Advanced mode cancelled"

while true; do
  echo "1) lsblk -f"
  echo "2) parted interactive (device)"
  echo "3) fdisk interactive (device)"
  echo "4) bash shell"
  echo "5) back"
  read -rp "Select: " opt
  case "$opt" in
    1) lsblk -f ;;
    2) read -rp "Device (example /dev/sdb): " dev; [[ -n "${dev:-}" ]] && parted "$dev" ;;
    3) read -rp "Device (example /dev/sdb): " dev; [[ -n "${dev:-}" ]] && fdisk "$dev" ;;
    4) bash ;;
    5) exit 0 ;;
    *) echo "Invalid" ;;
  esac
done
