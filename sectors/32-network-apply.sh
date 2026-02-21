#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
ensure_network_defaults

sql_port="$(config_get SQL_TCP_PORT)"
enforce="$(config_get NETWORK_ENFORCE_WHITELIST)"
wl4="$(config_get NETWORK_ALLOWED_IPV4)"
wl6="$(config_get NETWORK_ALLOWED_IPV6)"
allow_ts="$(config_get NETWORK_ALLOW_TAILSCALE)"
ts_if="$(config_get NETWORK_TAILSCALE_INTERFACE)"

log "Applying network policy from config..."
echo "SQL_TCP_PORT=$sql_port"
echo "NETWORK_ENFORCE_WHITELIST=$enforce"
echo "NETWORK_ALLOWED_IPV4=${wl4:-<empty>}"
echo "NETWORK_ALLOWED_IPV6=${wl6:-<empty>}"
echo "NETWORK_ALLOW_TAILSCALE=$allow_ts"
echo "NETWORK_TAILSCALE_INTERFACE=$ts_if"

[[ "$enforce" == "0" || "$enforce" == "1" ]] || die "NETWORK_ENFORCE_WHITELIST must be 0 or 1"
[[ "$allow_ts" == "0" || "$allow_ts" == "1" ]] || die "NETWORK_ALLOW_TAILSCALE must be 0 or 1"
[[ "$sql_port" =~ ^[0-9]+$ ]] || die "SQL_TCP_PORT must be numeric"
(( sql_port >= 1 && sql_port <= 65535 )) || die "SQL_TCP_PORT out of range"

if ! command -v ufw >/dev/null 2>&1; then
  die "ufw is required to configure network policy"
fi

if [[ "$enforce" == "1" && -z "$wl4$wl6" && "$allow_ts" == "0" ]]; then
  die "Whitelist enforcement enabled but no CIDRs configured and tailscale disabled"
fi

read -rp "Type apply to configure UFW SQL rules: " typed
[[ "$typed" == "apply" ]] || die "Network policy apply cancelled"

if ! ufw status 2>/dev/null | grep -qi '^Status: active'; then
  log "UFW is inactive; enabling now"
  ufw --force enable
fi

# Remove existing SQL port rules so desired state is deterministic.
nums="$(ufw status numbered 2>/dev/null | grep -E "\b${sql_port}\b" | sed -E 's/^\[ *([0-9]+)\].*/\1/' || true)"
if [[ -n "$nums" ]]; then
  log "Removing existing UFW rules for SQL port $sql_port"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    ufw --force delete "$n" || true
  done < <(echo "$nums" | sort -rn)
fi

# Apply desired rules.
if [[ "$allow_ts" == "1" ]]; then
  log "Allowing SQL port $sql_port on interface $ts_if"
  ufw allow in on "$ts_if" to any port "$sql_port" proto tcp
fi

if [[ "$enforce" == "1" ]]; then
  for cidr in $wl4; do
    log "Allowing SQL port $sql_port from IPv4 CIDR: $cidr"
    ufw allow from "$cidr" to any port "$sql_port" proto tcp
  done
  for cidr in $wl6; do
    log "Allowing SQL port $sql_port from IPv6 CIDR: $cidr"
    ufw allow from "$cidr" to any port "$sql_port" proto tcp
  done
fi

echo
echo "Current UFW SQL rules:"
ufw status numbered 2>/dev/null | grep -E "\b${sql_port}\b" || echo "(none)"

log "Network policy apply complete."