#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root

echo "This will remove SQL Server packages and SQL data/tooling remnants."
echo "The mssql-provision-kit itself will remain installed."
read -rp "Type uninstall to proceed: " typed
[[ "$typed" == "uninstall" ]] || die "Uninstall cancelled"

log "Starting uninstall cleanup"

if dpkg -s mssql-server >/dev/null 2>&1; then
  apt-get remove -y mssql-server || true
fi

# Optional SQL client tooling packages.
if dpkg -s mssql-tools18 >/dev/null 2>&1; then
  ACCEPT_EULA=Y apt-get remove -y mssql-tools18 || true
fi
if dpkg -s mssql-tools >/dev/null 2>&1; then
  ACCEPT_EULA=Y apt-get remove -y mssql-tools || true
fi

# Remove SQL Server runtime and data remnants, but keep the provision kit.
rm -rf /var/opt/mssql || true
rm -rf /opt/mssql || true
rm -f /etc/apt/sources.list.d/mssql-server-2025.list || true
rm -f /etc/apt/sources.list.d/msprod.list || true
apt-get update || true

echo "Uninstall cleanup complete."
