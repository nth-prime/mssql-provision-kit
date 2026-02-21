#!/usr/bin/env bash
set -euo pipefail

KIT_NAME="mssql-provision-kit"
INSTALL_DIR="/opt/${KIT_NAME}"
CONFIG_DIR="/etc/${KIT_NAME}"
BIN_LINK="/usr/local/bin/${KIT_NAME}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $(id -u) -ne 0 ]]; then
  echo "Run with sudo."
  exit 1
fi

echo "Installing ${KIT_NAME}..."
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

find "$SRC_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -a {} "$INSTALL_DIR/" \;

if [[ ! -f "$CONFIG_DIR/provision.conf" ]]; then
  install -m 600 "$INSTALL_DIR/config/provision.conf.example" "$CONFIG_DIR/provision.conf"
  echo "Created default config at $CONFIG_DIR/provision.conf"
fi

ln -sf "$INSTALL_DIR/provision" "$BIN_LINK"
chmod +x \
  "$INSTALL_DIR/provision" \
  "$INSTALL_DIR"/sectors/*.sh \
  "$INSTALL_DIR"/tests/tester \
  "$INSTALL_DIR"/tests/unit/*.sh \
  "$BIN_LINK"

VERSION="unknown"
if [[ -f "$INSTALL_DIR/VERSION" ]]; then
  VERSION="$(tr -d '[:space:]' < "$INSTALL_DIR/VERSION")"
fi

echo "Install complete: ${KIT_NAME} v${VERSION}"
echo "Run: ${KIT_NAME}"
