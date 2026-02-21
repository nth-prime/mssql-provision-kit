#!/usr/bin/env bash
set -euo pipefail
source /opt/mssql-provision-kit/lib/lib.sh

require_root
load_config

repo_url="$(config_get MSSQL_PROVISION_KIT_REPO_URL)"
branch="$(config_get MSSQL_PROVISION_KIT_BRANCH)"

[[ -n "$repo_url" ]] || die "MSSQL_PROVISION_KIT_REPO_URL must be set"
[[ -n "$branch" ]] || die "MSSQL_PROVISION_KIT_BRANCH must be set"

case "$repo_url" in
  https://github.com/*) ;;
  *) die "Only https://github.com/* repo URLs are supported" ;;
esac

repo_no_git="${repo_url%.git}"
tar_url="${repo_no_git}/archive/refs/heads/${branch}.tar.gz"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

log "Updating kit from $repo_url (branch: $branch)"
log "Downloading: $tar_url"

curl -fsSL "$tar_url" -o "$tmpdir/kit.tar.gz"
tar -xzf "$tmpdir/kit.tar.gz" -C "$tmpdir"

src_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[[ -n "$src_dir" ]] || die "Unable to locate extracted source directory"

log "Running installer from extracted source"
bash "$src_dir/install.sh"

log "Update complete."