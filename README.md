# mssql-provision-kit

SQL Server 2025 provisioning kit for Ubuntu 24.04 with modular sectors, idempotent scripts, mandatory preflight checks, and storage provisioning workflows.

## Scope and Support

- OS: Ubuntu 24.04
- SQL: SQL Server 2025
- Filesystems: `xfs` and `ext4`
The kit hard-fails outside this scope by design.

## Security and Safety Defaults

- Mandatory preflight before install
- Dry-run path for install and storage planning
- Explicit typed confirmations for apply/rollback/uninstall paths
- Uninstall requires exact input: `uninstall`
- Transaction snapshots for storage changes under `/var/lib/mssql-provision-kit/state/transactions`

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
    10-host-preflight.sh
    20-install-sql.sh
    30-post-validate.sh
    40-storage-preflight.sh
    41-storage-inspect.sh
    42-storage-health.sh
    43-storage-plan.sh
    44-storage-apply.sh
    45-storage-validate.sh
    46-storage-role-map.sh
    47-storage-report.sh
    48-storage-rollback.sh
    49-storage-advanced.sh
    80-uninstall-cleanup.sh
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
- `MSSQL_EDITION=Developer|Standard`
- `PROMPT_FOR_SA_PASSWORD=1|0`
- `DEFAULT_SYSADMIN_LOGIN` (prompt allows override)
- `VOLUMES="v1 v2 ..."` with per-volume `DEVICE/FS/MOUNT` keys
- SQL role mapping: `SQL_DATA_VOLUME`, `SQL_LOG_VOLUME`, `SQL_BACKUP_VOLUME`, `SQL_TEMPDB_VOLUME`

Default role intent mount mapping:

- data: `/mnt/d`
- log: `/mnt/l`
- backup: `/mnt/b`
- tempdb: `/mnt/t`

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
6. Drive Provisioning
7. Uninstall / Cleanup
8. Show State + Logs

Drive Provisioning submenu:

1. Run Storage Preflight
2. Inspect Disks and Topology
3. Inspect Mounts and Free Space
4. Inspect Filesystem Health
5. Build Provisioning Plan (Interactive)
6. Preview Plan (Dry-Run)
7. Apply Plan: Partition + Format + Mount
8. Apply Plan: Mount + Fstab Only
9. Validate Provisioned Volumes
10. Map Volumes to SQL Roles
11. Export Provisioning Report
12. Rollback Last Provisioning Transaction
13. Advanced Tools (Expert Mode)
14. Back

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
- Storage apply/validate failures:
  - Run Drive Provisioning options `1`, `2`, `6`, and `9` in sequence.

## Testing

```bash
chmod +x tests/tester tests/unit/*.sh tests/lib/assert.sh
./tests/tester
```
