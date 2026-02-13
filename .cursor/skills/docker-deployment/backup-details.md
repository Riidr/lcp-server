# Backup Procedures — Details

## Hot Backup (`scripts/hot-backup.sh`)
- Method: `mysqldump --single-transaction --quick --lock-tables=false`
- Impact: <5% write, no read impact, service stays up
- Output: `backups/lcp_hot_YYYYMMDD_HHMMSS.sql.gz`
- Auto-cleans backups older than 30 days
- Includes integrity verification

## Cold Backup (`scripts/cold-backup.sh`)
- Method: Stops server + nginx → `FLUSH TABLES WITH READ LOCK` → full dump
- Impact: 30–120s downtime, maximum consistency
- Output: `backups/lcp_cold_YYYYMMDD_HHMMSS.sql.gz`
- Includes `--master-data=2` for replication
- Auto-restarts services after completion

## Restore (`scripts/restore-backup.sh`)
1. Stops LCP server
2. Drops and recreates database
3. Restores from `.sql.gz` file
4. Restarts server
5. Verifies table count
- Requires interactive confirmation

## Automated Backup (`scripts/automated-backup.sh`)
- Cron-friendly wrapper for hot-backup
- Logs to `logs/hot-backup.log`
- Example cron: `0 2 * * * /path/to/automated-backup.sh`

## Monitor Impact (`scripts/monitor-backup-impact.sh`)
- Run during backup to monitor MySQL connections, QPS, container CPU/memory, response times
- 30s baseline, then 5 minutes of monitoring
