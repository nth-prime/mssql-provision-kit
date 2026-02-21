#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config
ensure_network_defaults

log "Running network validation checks..."

sql_port="$(config_get SQL_TCP_PORT)"
enforce="$(config_get NETWORK_ENFORCE_WHITELIST)"
wl4="$(config_get NETWORK_ALLOWED_IPV4)"
wl6="$(config_get NETWORK_ALLOWED_IPV6)"
allow_ts="$(config_get NETWORK_ALLOW_TAILSCALE)"
ts_if="$(config_get NETWORK_TAILSCALE_INTERFACE)"

echo "== Effective network config =="
echo "SQL_TCP_PORT=$sql_port"
echo "NETWORK_ENFORCE_WHITELIST=$enforce"
echo "NETWORK_ALLOWED_IPV4=${wl4:-<empty>}"
echo "NETWORK_ALLOWED_IPV6=${wl6:-<empty>}"
echo "NETWORK_ALLOW_TAILSCALE=$allow_ts"
echo "NETWORK_TAILSCALE_INTERFACE=$ts_if"

echo
echo "== Listener check =="
if command -v ss >/dev/null 2>&1; then
  ss -ltnp | awk -v p=":${sql_port}" 'NR==1 || index($4,p)>0 {print}' || true
else
  echo "ss command not found"
fi

echo
echo "== Firewall check (ufw) =="
if ! command -v ufw >/dev/null 2>&1; then
  echo "ufw not installed"
  [[ "$enforce" == "0" ]] || die "Whitelist enforcement requested but ufw is unavailable"
  log "Network validation complete."
  exit 0
fi

ufw_status_raw="$(ufw status 2>/dev/null || true)"
ufw_status_num="$(ufw status numbered 2>/dev/null || true)"

status_line="$(echo "$ufw_status_raw" | sed -n '1p')"
echo "$status_line"

echo "Rules touching SQL port $sql_port:"
echo "$ufw_status_num" | grep -E "\b${sql_port}\b" || echo "(none)"

sql_rules="$(echo "$ufw_status_num" | grep -E "\b${sql_port}\b" || true)"

echo
echo "== Tailscale exposure check =="
if command -v ip >/dev/null 2>&1; then
  if ip link show "$ts_if" >/dev/null 2>&1; then
    echo "Tailscale interface present: $ts_if"
  else
    echo "Tailscale interface not present: $ts_if"
    [[ "$allow_ts" == "0" ]] || die "NETWORK_ALLOW_TAILSCALE=1 but interface $ts_if is missing"
  fi
else
  echo "ip command not found"
  [[ "$allow_ts" == "0" ]] || die "NETWORK_ALLOW_TAILSCALE=1 but cannot verify interface without ip command"
fi

if [[ "$allow_ts" == "1" ]]; then
  echo "$sql_rules" | grep -Fqi "on $ts_if" || die "NETWORK_ALLOW_TAILSCALE=1 but no SQL port allow rule found on interface $ts_if"
  echo "Tailscale SQL exposure enabled and validated."
else
  if echo "$sql_rules" | grep -Fqi "on $ts_if"; then
    die "NETWORK_ALLOW_TAILSCALE=0 but SQL port rule still allows interface $ts_if"
  fi
  echo "Tailscale SQL exposure disabled and validated."
fi

if [[ "$enforce" == "1" ]]; then
  [[ -n "$wl4$wl6" ]] || die "Whitelist enforcement enabled but NETWORK_ALLOWED_IPV4/IPv6 are empty"
  echo "$status_line" | grep -qi "Status: active" || die "Whitelist enforcement enabled but ufw is not active"

  [[ -n "$sql_rules" ]] || die "No ufw rules found for SQL port $sql_port"

  # Fail if broad allow rules exist on non-Tailscale scope while whitelist enforcement is requested.
  while IFS= read -r rule; do
    [[ -n "$rule" ]] || continue
    if echo "$rule" | grep -Eq 'Anywhere( \(v6\))?'; then
      if [[ "$allow_ts" == "1" ]] && echo "$rule" | grep -Fqi "on $ts_if"; then
        continue
      fi
      die "Broad SQL port allow rule found (Anywhere) on non-Tailscale scope while whitelist enforcement is enabled"
    fi
  done <<< "$sql_rules"

  for cidr in $wl4; do
    echo "$sql_rules" | grep -Fq "$cidr" || die "Missing ufw SQL allow rule for IPv4 CIDR: $cidr"
  done
  for cidr in $wl6; do
    echo "$sql_rules" | grep -Fq "$cidr" || die "Missing ufw SQL allow rule for IPv6 CIDR: $cidr"
  done

  echo "Whitelist enforcement checks passed."
else
  echo "Whitelist enforcement disabled by config (NETWORK_ENFORCE_WHITELIST=0)."
fi

log "Network validation complete."
