#!/bin/bash
# PostgreSQL Database Backup
# Backs up all databases from container 102
#
# Usage: ./backup-postgresql.sh [--test] [--dry-run]
#
# Installation:
# 1. Copy to /usr/local/bin/backup-postgresql.sh on Proxmox host with PostgreSQL
# 2. chmod +x /usr/local/bin/backup-postgresql.sh
# 3. Add to cron: 0 2 * * * /usr/local/bin/backup-postgresql.sh

set -e

# Configuration
BACKUP_ROOT="/mnt/omv-backups/databases/postgresql"
LOG_FILE="/var/log/homelab-backup.log"
CONTAINER_ID=102
RETENTION_DAYS=30

# Parse arguments
DRY_RUN=0
TEST_MODE=0
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=1 ;;
        --test) TEST_MODE=1 ;;
    esac
done

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if backup mount is available
if ! mountpoint -q /mnt/omv-backups; then
    log "ERROR: Backup mount /mnt/omv-backups not available!"
    exit 1
fi

# Check if container exists and is running
if ! pct status $CONTAINER_ID | grep -q "running"; then
    log "ERROR: PostgreSQL container $CONTAINER_ID is not running!"
    exit 1
fi

BACKUP_DATE=$(date +%Y-%m-%d)
if [ "$TEST_MODE" -eq 1 ]; then
    BACKUP_DIR="$BACKUP_ROOT/test/$(date +%Y-%m-%d_%H-%M-%S)"
else
    BACKUP_DIR="$BACKUP_ROOT/$BACKUP_DATE"
fi

mkdir -p "$BACKUP_DIR"

log "===== Starting PostgreSQL backup ====="
log "Container: $CONTAINER_ID"
log "Target: $BACKUP_DIR"

if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY RUN MODE - No actual backups will be performed"
    log "[DRY RUN] Would backup all databases"
    exit 0
fi

# Backup all databases (SQL format - portable, human-readable)
log "Backing up all databases (SQL format)..."
pct exec $CONTAINER_ID -- sudo -u postgres pg_dumpall > "$BACKUP_DIR/all_databases.sql" 2>&1

if [ $? -eq 0 ]; then
    log "✓ All databases backed up (SQL format)"
else
    log "✗ All databases backup FAILED"
    exit 1
fi

# Get list of databases
log "Getting list of databases..."
DATABASES=$(pct exec $CONTAINER_ID -- sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$')

DB_COUNT=0
DB_SUCCESS=0

# Backup individual databases (custom format - faster restore, compressed)
for db in $DATABASES; do
    DB_COUNT=$((DB_COUNT + 1))
    log "Backing up database: $db (custom format)..."

    pct exec $CONTAINER_ID -- sudo -u postgres pg_dump -F c "$db" > "$BACKUP_DIR/${db}.dump" 2>&1

    if [ $? -eq 0 ]; then
        log "✓ $db backed up successfully"
        DB_SUCCESS=$((DB_SUCCESS + 1))
    else
        log "✗ $db backup FAILED"
    fi
done

# Create metadata file
cat > "$BACKUP_DIR/backup-info.txt" << EOF
Backup Date: $(date '+%Y-%m-%d %H:%M:%S')
Container ID: $CONTAINER_ID
PostgreSQL Version: $(pct exec $CONTAINER_ID -- sudo -u postgres psql --version)
Databases Backed Up: $DB_SUCCESS/$DB_COUNT
Databases: $DATABASES
EOF

# Compress entire backup directory
log "Compressing backups..."
PARENT_DIR=$(dirname "$BACKUP_DIR")
cd "$PARENT_DIR"
tar -czf "postgresql_${BACKUP_DATE}.tar.gz" "$(basename $BACKUP_DIR)" 2>&1

if [ $? -eq 0 ]; then
    COMPRESSED_SIZE=$(du -sh "postgresql_${BACKUP_DATE}.tar.gz" | awk '{print $1}')
    log "✓ Backup compressed: $COMPRESSED_SIZE"

    # Remove uncompressed directory
    rm -rf "$BACKUP_DIR"
else
    log "✗ Compression failed, keeping uncompressed backup"
fi

# Cleanup old backups
if [ "$TEST_MODE" -eq 0 ]; then
    log "Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
    find "$BACKUP_ROOT" -name "postgresql_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    OLD_COUNT=$(find "$BACKUP_ROOT" -name "postgresql_*.tar.gz" -mtime +$RETENTION_DAYS | wc -l)
    if [ $OLD_COUNT -gt 0 ]; then
        log "✓ Removed $OLD_COUNT old backups"
    fi
fi

# Calculate total size
TOTAL_SIZE=$(du -sh "$BACKUP_ROOT" 2>/dev/null | awk '{print $1}')

# Summary
log "===== Backup Summary ====="
log "Databases: $DB_SUCCESS/$DB_COUNT successful"
log "Backup size: $COMPRESSED_SIZE"
log "Total backup storage: $TOTAL_SIZE"
log "Location: $BACKUP_ROOT/postgresql_${BACKUP_DATE}.tar.gz"

if [ $DB_SUCCESS -lt $DB_COUNT ]; then
    log "WARNING: Some database backups failed!"
    exit 1
fi

log "✅ PostgreSQL backup complete!"
exit 0
