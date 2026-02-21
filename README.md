# mssql-provision-kit

SQL Server 2025 provisioning kit for Ubuntu 24.04 with:

- strict support gating
- mandatory preflight checks
- dry-run install flow
- granular drive provisioning submenu
- uninstall/cleanup guardrails

## Support Matrix

- OS: Ubuntu 24.04
- SQL: SQL Server 2025
- Filesystems: `xfs` and `ext4`

The kit hard-fails outside this scope by design.

## Repository Layout

```text
install-mssql-kit/
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

## Install

```bash
sudo bash install.sh
```

Then run:

```bash
mssql-provision-kit
```

## Top-Level Selector

1. Edit Config
2. Run Host + SQL Preflight
3. Dry-Run Install Plan
4. Install SQL Server 2025
5. Post-Install Validation
6. Drive Provisioning
7. Uninstall / Cleanup
8. Show State + Logs

## Drive Provisioning Selector

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

## Configuration

Config file:

`/etc/mssql-provision-kit/provision.conf`

Seed example:

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

Default role intent maps to Linux mounts:

- data: `/mnt/d`
- log: `/mnt/l`
- backup: `/mnt/b`
- tempdb: `/mnt/t`

## Safety and Cleanup

- Install flow supports `--dry-run` and `--apply`.
- Storage apply requires explicit `apply` confirmation.
- Uninstall requires exact typed confirmation: `uninstall`.
- Transaction snapshots are stored under `/var/lib/mssql-provision-kit/state/transactions`.

## Versioning

- Repository version is stored in `VERSION`.
- Installed version is copied to `/opt/mssql-provision-kit/VERSION`.
- Selector header displays `MSSQL Provision Kit v<version>`.
- Installer prints installed version on completion.

Suggested release flow:

1. Update `VERSION`
2. Run tests
3. Tag release (for example `v0.1.0`)

## Testing

```bash
chmod +x tests/tester tests/unit/*.sh tests/lib/assert.sh
./tests/tester
```
