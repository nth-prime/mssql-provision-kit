#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root

echo "This will remove mssql-server package and kit files tracked by this installer."
read -rp "Type uninstall to proceed: " typed
[[ "$typed" == "uninstall" ]] || die "Uninstall cancelled"

log "Starting uninstall cleanup"

if dpkg -s mssql-server >/dev/null 2>&1; then
  apt-get remove -y mssql-server || true
fi

rm -f /usr/local/bin/mssql-provision-kit || true
rm -rf /opt/mssql-provision-kit || true
rm -rf /etc/mssql-provision-kit || true
rm -rf /var/lib/mssql-provision-kit || true
rm -rf /var/log/mssql-provision-kit || true

echo "Uninstall cleanup complete."
