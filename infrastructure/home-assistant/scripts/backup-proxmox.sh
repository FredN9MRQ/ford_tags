#!/bin/bash
#
# Proxmox Backup Script
# Backs up all running VMs and containers to specified storage
#
# Usage: ./backup-proxmox.sh [--dry-run]
#

set -euo pipefail

# Configuration
BACKUP_STORAGE="local"  # Change to your backup storage name (e.g., "backup-nfs")
BACKUP_MODE="snapshot"   # Options: snapshot, suspend, stop
COMPRESSION="zstd"       # Options: zstd, gzip, lzo
LOG_FILE="/var/log/infrastructure/proxmox-backup.log"
RETENTION_DAYS=30        # Keep backups for 30 days

# Alert configuration
ALERT_EMAIL=""           # Set to receive email alerts on failure
SLACK_WEBHOOK=""         # Set to receive Slack alerts

# Functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    local message="$1"
    log "ALERT: $message"

    # Email alert
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Proxmox Backup Alert" "$ALERT_EMAIL" 2>/dev/null || true
    fi

    # Slack alert
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Proxmox Backup Alert: $message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Parse arguments
DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    log "DRY RUN MODE - No actual backups will be performed"
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting Proxmox backup"

# Check if backup storage exists
if ! pvesm status | grep -q "^$BACKUP_STORAGE"; then
    alert "Backup storage '$BACKUP_STORAGE' not found!"
    exit 1
fi

# Check backup storage space
STORAGE_AVAILABLE=$(pvesm status -storage "$BACKUP_STORAGE" | awk -v storage="$BACKUP_STORAGE" '$1==storage {print $4}')
log "Available backup storage: $STORAGE_AVAILABLE"

# Backup VMs
BACKUP_FAILED=0
BACKUP_SUCCESS=0

log "Backing up VMs..."
while IFS= read -r line; do
    VMID=$(echo "$line" | awk '{print $1}')
    NAME=$(echo "$line" | awk '{print $2}')
    STATUS=$(echo "$line" | awk '{print $3}')

    # Skip stopped VMs in snapshot mode
    if [ "$BACKUP_MODE" = "snapshot" ] && [ "$STATUS" != "running" ]; then
        log "Skipping stopped VM $VMID ($NAME)"
        continue
    fi

    log "Backing up VM $VMID ($NAME)..."

    if [ "$DRY_RUN" = false ]; then
        if vzdump "$VMID" --storage "$BACKUP_STORAGE" --mode "$BACKUP_MODE" \
            --compress "$COMPRESSION" --quiet 1 >> "$LOG_FILE" 2>&1; then
            log "Successfully backed up VM $VMID"
            ((BACKUP_SUCCESS++))
        else
            log "ERROR: Failed to backup VM $VMID"
            ((BACKUP_FAILED++))
        fi
    else
        log "Would backup VM $VMID ($NAME)"
        ((BACKUP_SUCCESS++))
    fi
done < <(qm list | tail -n +2)

# Backup Containers
log "Backing up containers..."
while IFS= read -r line; do
    CTID=$(echo "$line" | awk '{print $1}')
    STATUS=$(echo "$line" | awk '{print $2}')
    NAME=$(echo "$line" | awk '{print $3}')

    # Skip stopped containers in snapshot mode
    if [ "$BACKUP_MODE" = "snapshot" ] && [ "$STATUS" != "running" ]; then
        log "Skipping stopped container $CTID ($NAME)"
        continue
    fi

    log "Backing up container $CTID ($NAME)..."

    if [ "$DRY_RUN" = false ]; then
        if vzdump "$CTID" --storage "$BACKUP_STORAGE" --mode "$BACKUP_MODE" \
            --compress "$COMPRESSION" --quiet 1 >> "$LOG_FILE" 2>&1; then
            log "Successfully backed up container $CTID"
            ((BACKUP_SUCCESS++))
        else
            log "ERROR: Failed to backup container $CTID"
            ((BACKUP_FAILED++))
        fi
    else
        log "Would backup container $CTID ($NAME)"
        ((BACKUP_SUCCESS++))
    fi
done < <(pct list | tail -n +2)

# Backup Proxmox configuration
log "Backing up Proxmox configuration..."
if [ "$DRY_RUN" = false ]; then
    CONFIG_BACKUP="/tmp/pve-config-$(date +%Y%m%d-%H%M%S).tar.gz"
    if tar -czf "$CONFIG_BACKUP" /etc/pve 2>/dev/null; then
        # Move to backup storage location
        BACKUP_PATH=$(pvesm path "$BACKUP_STORAGE")
        mv "$CONFIG_BACKUP" "$BACKUP_PATH/" 2>/dev/null || true
        log "Configuration backup saved"
    else
        log "WARNING: Configuration backup failed"
    fi
fi

# Clean up old backups
if [ "$DRY_RUN" = false ]; then
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    # This is storage-specific; adjust for your setup
    find "$BACKUP_PATH" -name "vzdump-*.{vma,tar}.{gz,zst,lzo}" -mtime "+$RETENTION_DAYS" -delete 2>/dev/null || true
fi

# Summary
log "Backup completed: $BACKUP_SUCCESS successful, $BACKUP_FAILED failed"

if [ "$BACKUP_FAILED" -gt 0 ]; then
    alert "Proxmox backup completed with $BACKUP_FAILED failures"
    exit 1
fi

log "All backups completed successfully"
exit 0
