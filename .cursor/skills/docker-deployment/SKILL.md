---
name: docker-deployment
description: Docker deployment and operations for the LCP Server — Compose services, secrets, backups, nginx, environment variables. Use when working on Dockerfile, compose.yaml, scripts/, config/, deployment, or infrastructure tasks.
---

# Docker Deployment & Operations

## Compose Services

| Service | Image | Port | Depends On | Health Check |
|---------|-------|------|------------|--------------|
| **nginx** | `nginx:1.27-alpine` | 80, 443 → host | server (healthy) | `wget --spider http://localhost/health` |
| **server** | Built from Dockerfile | 8989 (internal) | mysql (healthy) | `wget http://localhost:8989/health` |
| **encrypt** | Built from Dockerfile | — | server (healthy) | — |
| **dashboard** | `llemeur/lcp-dashboard` | 8080 (internal) | server | — |
| **mysql** | `mysql:8.4.7` | 3307 → host:3306 | — | `mysqladmin ping` |
| **hot-backup** | `mysql:8.4.7` | — | — | Profile: `backup` |
| **cold-backup** | `mysql:8.4.7` | — | — | Profile: `backup` |

## Docker Secrets

All file-based in `config/`:

| Secret | File | Used By |
|--------|------|---------|
| `access` | `config/access.txt` | server (Basic Auth + JWT admin) |
| `mysql-password` | `config/mysql-password.txt` | server, mysql |
| `mysql-root-password` | `config/mysql-root-password.txt` | mysql, backup services |
| `jwt-secretkey` | `config/jwt-secretkey.txt` | server |

Mounted at `/run/secrets/<name>`.

## Dockerfile Build

Multi-stage: `golang:1.24` → `debian:trixie-slim`

- AMD64 + `libuserkey.a` present → builds with `PLCP,MYSQL` tags
- AMD64 without → `MYSQL` tag only
- Other architectures → `CGO_ENABLED=0`, `MYSQL` tag
- Runtime: non-privileged `appuser` (UID 10001)
- Exposes port 8989, CMD `/app/lcpserver`

## Key Environment Variables

**Server** (`LCPSERVER_*`): `LOGLEVEL`, `PUBLICBASEURL`, `PORT`, `DSN`, `CERTIFICATE_CERT`, `CERTIFICATE_PRIVATEKEY`, `LICENSE_PROVIDER`, `LICENSE_PROFILE`, `LICENSE_HINTLINK`, `STATUS_*`, `DASHBOARD_*`, `RESOURCES`, `ACCESS_FILE`

**Encrypt** (`LCPENCRYPT_*`): `PROVIDER_URI`, `STORAGE_URL`, `LCPSERVER_URL`, `VERBOSE`, `V2`, `COVER`, `PDF_NO_META`, `CMS_URL`

**MySQL**: `MYSQL_DATABASE`, `MYSQL_USER` (passwords via secrets)

## Backup Commands

```bash
# Hot backup (minimal impact, service stays up)
docker compose --profile backup run --rm hot-backup

# Cold backup (full consistency, ~30-120s downtime)
docker compose --profile backup run --rm cold-backup

# Restore from backup
./scripts/restore-backup.sh backups/<file>.sql.gz
```

For detailed backup procedures, see [backup-details.md](backup-details.md).

## Volumes

- `db-data` → MySQL `/var/lib/mysql`
- `${LCPENCRYPT_STORAGE_PATH:-./resources}` → `/resources` (server + encrypt)
- `${LCPENCRYPT_INPUT_PATH:-./input}` → `/input` (encrypt watch folder)
- `./backups` → `/backup` (backup services)
