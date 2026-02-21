# mssql-provision-kit

SQL Server 2025 provisioning kit for Ubuntu 24.04 with modular sectors, idempotent scripts, mandatory preflight checks, and a single-drive SQL directory layout.

## Scope and Support

- OS: Ubuntu 24.04
- SQL: SQL Server 2025
- Storage model: single drive with directories for data, log, backup, and tempdb

The kit hard-fails outside this scope by design.

## Security and Safety Defaults

- Mandatory preflight before install
- Dry-run path for install and storage layout
- Explicit typed confirmations for apply/uninstall paths
- Uninstall requires exact input: `uninstall`

## Repository Layout

```text
mssql-provision-kit/
  VERSION
  install.sh
  provision
  config/
    provision.conf.example
  lib/
    lib.sh
  sectors/
    05-update-kit.sh
    10-host-preflight.sh
    20-install-sql.sh
    30-post-validate.sh
    40-storage-preflight.sh
    41-storage-inspect.sh
    42-storage-health.sh
    43-storage-layout.sh
    44-storage-validate.sh
    47-storage-report.sh
    50-run-unit-tests.sh
    80-uninstall-cleanup.sh
    85-restart-now.sh
    90-show-state.sh
  tests/
    tester
    lib/assert.sh
    unit/*.sh
```

Install target paths:

- `/opt/mssql-provision-kit`
- `/etc/mssql-provision-kit/provision.conf`
- `/usr/local/bin/mssql-provision-kit` (symlink)
- `/var/lib/mssql-provision-kit/state`
- `/var/log/mssql-provision-kit`

## Requirements

- Ubuntu 24.04 host
- Root or `sudo` privileges
- `systemd`
- Internet access for package/repository installation

## Install

### Option 1: Clone and install

```bash
git clone https://github.com/nth-prime/mssql-provision-kit.git
cd mssql-provision-kit
sudo bash install.sh
```

### Option 2: One-liner from GitHub

```bash
set -euo pipefail
tmpdir="$(mktemp -d)"
curl -fsSL "https://github.com/nth-prime/mssql-provision-kit/archive/refs/heads/main.tar.gz" -o "$tmpdir/mssql-provision-kit.tar.gz"
tar -xzf "$tmpdir/mssql-provision-kit.tar.gz" -C "$tmpdir"
cd "$tmpdir/mssql-provision-kit-main"
sudo bash install.sh
```

After install:

```bash
mssql-provision-kit
```

## Configuration

Config file path:

`/etc/mssql-provision-kit/provision.conf`

Initial config is copied from:

`config/provision.conf.example`

Key settings:

- `VERSION_STRATEGY=latest|pinned|explicit`
- `PINNED_BUILD` for pinned package installs
- `EXPLICIT_DEB_URL` for explicit package URL installs
- `MSSQL_PROVISION_KIT_REPO_URL` updater source repository
- `MSSQL_PROVISION_KIT_BRANCH` updater branch
- `MSSQL_EDITION=Developer|Standard`
- `PROMPT_FOR_SA_PASSWORD=1|0`
- `DEFAULT_SYSADMIN_LOGIN` (prompt allows override)
- `SQL_STORAGE_ROOT` single storage root
- `SQL_DATA_PATH`, `SQL_LOG_PATH`, `SQL_BACKUP_PATH`, `SQL_TEMPDB_PATH`

Default paths:

- root: `/var/opt/mssql`
- data: `/var/opt/mssql/data`
- log: `/var/opt/mssql/log`
- backup: `/var/opt/mssql/backup`
- tempdb: `/var/opt/mssql/tempdb`

## Usage

Run selector:

```bash
mssql-provision-kit
```

Top-level menu:

1. Edit Config
2. Run Host + SQL Preflight
3. Dry-Run Install Plan
4. Install SQL Server 2025
5. Post-Install Validation
6. Storage Layout
7. Uninstall / Cleanup
8. Show State + Logs
9. Run Unit Tests
10. Restart Machine Now
11. Update Provision Kit from GitHub

Storage Layout submenu:

1. Run Storage Preflight
2. Inspect Storage and Filesystems
3. Run Storage Health Checks
4. Preview SQL Directory Layout (Dry-Run)
5. Apply SQL Directory Layout
6. Validate SQL Directory Layout
7. Export Storage Report
8. Back

## Versioning

- Repository version is stored in `VERSION`.
- Installed version is copied to `/opt/mssql-provision-kit/VERSION`.
- Selector header displays `MSSQL Provision Kit v<version>`.
- Installer prints installed version on completion.

Suggested release flow:

1. Update `VERSION`
2. Run tests
3. Tag release (for example `v0.1.0`)

## Troubleshooting

- `Missing config: /etc/mssql-provision-kit/provision.conf`:
  - Re-run `sudo bash install.sh`.
- `Unsupported OS` errors:
  - Confirm host is Ubuntu 24.04.
- Storage layout failures:
  - Run Storage Layout options `1`, `2`, `4`, and `6` in sequence.

## Testing

```bash
chmod +x tests/tester tests/unit/*.sh tests/lib/assert.sh
./tests/tester
```
