#!/bin/bash
#
# VPS Backup Script
# Backs up critical VPS configurations and data
#
# Usage: ./backup-vps.sh [--dry-run]
#

set -euo pipefail

# Configuration
BACKUP_DIR="/root/backups"
REMOTE_BACKUP="user@backup-host:/backups/vps"  # Optional: rsync to remote
LOG_FILE="/var/log/infrastructure/vps-backup.log"
RETENTION_DAYS=30

# Directories and files to backup
BACKUP_ITEMS=(
    "/etc/pangolin"
    "/etc/gerbil"
    "/etc/letsencrypt"
    "/etc/nginx"
    "/etc/apache2"
    "/etc/systemd/system"
    "/root/.ssh"
    "/etc/ssh/sshd_config"
    "/etc/ufw"
    "/etc/iptables"
)

# Functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Parse arguments
DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    log "DRY RUN MODE"
fi

# Ensure directories exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/vps-backup-$TIMESTAMP.tar.gz"

log "Starting VPS backup to $BACKUP_FILE"

# Create backup archive
if [ "$DRY_RUN" = false ]; then
    # Build tar command with existing paths only
    TAR_PATHS=()
    for item in "${BACKUP_ITEMS[@]}"; do
        if [ -e "$item" ]; then
            TAR_PATHS+=("$item")
        else
            log "WARNING: $item does not exist, skipping"
        fi
    done

    if [ ${#TAR_PATHS[@]} -gt 0 ]; then
        tar -czf "$BACKUP_FILE" "${TAR_PATHS[@]}" 2>/dev/null
        log "Backup archive created: $(du -h "$BACKUP_FILE" | cut -f1)"
    else
        log "ERROR: No paths to backup!"
        exit 1
    fi
else
    log "Would backup: ${BACKUP_ITEMS[*]}"
fi

# Sync to remote backup location
if [ -n "$REMOTE_BACKUP" ] && [ "$DRY_RUN" = false ]; then
    log "Syncing to remote backup location..."
    if rsync -avz "$BACKUP_FILE" "$REMOTE_BACKUP/" >> "$LOG_FILE" 2>&1; then
        log "Remote sync completed"
    else
        log "WARNING: Remote sync failed"
    fi
fi

# Clean up old backups
if [ "$DRY_RUN" = false ]; then
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "vps-backup-*.tar.gz" -mtime "+$RETENTION_DAYS" -delete
fi

log "VPS backup completed successfully"
exit 0
