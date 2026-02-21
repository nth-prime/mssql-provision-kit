#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
ensure_sql_paths_from_root
ensure_network_defaults

echo "== Effective config: /etc/mssql-provision-kit/provision.conf =="
awk 'NF && $1 !~ /^#/' "$CONFIG_FILE"