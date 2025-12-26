#!/bin/bash
# Proxmox Backup to OMV
# Backs up all VMs and containers to OMV NFS share
#
# Usage: ./backup-proxmox-to-omv.sh [--test] [--dry-run]
#
# Installation:
# 1. Copy to /usr/local/bin/backup-proxmox-to-omv.sh on each Proxmox host
# 2. chmod +x /usr/local/bin/backup-proxmox-to-omv.sh
# 3. Add to cron: 0 2 * * * /usr/local/bin/backup-proxmox-to-omv.sh

set -e

# Configuration
BACKUP_DIR="/mnt/omv-backups/proxmox/$(hostname)"
LOG_FILE="/var/log/homelab-backup.log"
RETENTION_DAYS=7
RETENTION_WEEKS=4
RETENTION_MONTHS=3

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

# Determine backup type based on date
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)

if [ "$TEST_MODE" -eq 1 ]; then
    BACKUP_TYPE="test"
    TARGET_DIR="$BACKUP_DIR/test/$(date +%Y-%m-%d_%H-%M-%S)"
elif [ "$DAY_OF_MONTH" == "01" ]; then
    BACKUP_TYPE="monthly"
    TARGET_DIR="$BACKUP_DIR/monthly/$(date +%Y-%m)"
elif [ "$DAY_OF_WEEK" == "7" ]; then
    BACKUP_TYPE="weekly"
    TARGET_DIR="$BACKUP_DIR/weekly/week-$(date +%U)"
else
    BACKUP_TYPE="daily"
    TARGET_DIR="$BACKUP_DIR/daily/$(date +%Y-%m-%d)"
fi

# Create target directory
mkdir -p "$TARGET_DIR"

log "===== Starting $BACKUP_TYPE backup for $(hostname) ====="
log "Target directory: $TARGET_DIR"

if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY RUN MODE - No actual backups will be performed"
fi

# Backup all VMs
VM_COUNT=0
VM_SUCCESS=0
if command -v qm &> /dev/null; then
    for vmid in $(qm list | tail -n +2 | awk '{print $1}'); do
        vm_name=$(qm list | grep "^$vmid" | awk '{print $2}')
        VM_COUNT=$((VM_COUNT + 1))

        log "Backing up VM $vmid ($vm_name)..."

        if [ "$DRY_RUN" -eq 0 ]; then
            vzdump $vmid \
                --dumpdir "$TARGET_DIR" \
                --mode snapshot \
                --compress zstd \
                --remove 0 \
                --quiet 1 2>&1 | tee -a "$LOG_FILE"

            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                log "✓ VM $vmid backed up successfully"
                VM_SUCCESS=$((VM_SUCCESS + 1))
            else
                log "✗ VM $vmid backup FAILED"
            fi
        else
            log "[DRY RUN] Would backup VM $vmid ($vm_name)"
            VM_SUCCESS=$((VM_SUCCESS + 1))
        fi
    done
else
    log "No VMs found (qm command not available)"
fi

# Backup all containers
CT_COUNT=0
CT_SUCCESS=0
if command -v pct &> /dev/null; then
    for ctid in $(pct list | tail -n +2 | awk '{print $1}'); do
        ct_name=$(pct list | grep "^$ctid" | awk '{print $3}')
        CT_COUNT=$((CT_COUNT + 1))

        log "Backing up Container $ctid ($ct_name)..."

        if [ "$DRY_RUN" -eq 0 ]; then
            vzdump $ctid \
                --dumpdir "$TARGET_DIR" \
                --mode snapshot \
                --compress zstd \
                --remove 0 \
                --quiet 1 2>&1 | tee -a "$LOG_FILE"

            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                log "✓ Container $ctid backed up successfully"
                CT_SUCCESS=$((CT_SUCCESS + 1))
            else
                log "✗ Container $ctid backup FAILED"
            fi
        else
            log "[DRY RUN] Would backup Container $ctid ($ct_name)"
            CT_SUCCESS=$((CT_SUCCESS + 1))
        fi
    done
else
    log "No containers found (pct command not available)"
fi

# Cleanup old backups (only for non-test backups)
if [ "$TEST_MODE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    log "Cleaning up old backups..."

    # Daily cleanup
    if [ -d "$BACKUP_DIR/daily" ]; then
        find "$BACKUP_DIR/daily" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true
        log "✓ Daily backups cleaned (keeping last $RETENTION_DAYS days)"
    fi

    # Weekly cleanup
    if [ -d "$BACKUP_DIR/weekly" ]; then
        find "$BACKUP_DIR/weekly" -type d -mtime +$((RETENTION_WEEKS * 7)) -exec rm -rf {} + 2>/dev/null || true
        log "✓ Weekly backups cleaned (keeping last $RETENTION_WEEKS weeks)"
    fi

    # Monthly cleanup
    if [ -d "$BACKUP_DIR/monthly" ]; then
        find "$BACKUP_DIR/monthly" -type d -mtime +$((RETENTION_MONTHS * 30)) -exec rm -rf {} + 2>/dev/null || true
        log "✓ Monthly backups cleaned (keeping last $RETENTION_MONTHS months)"
    fi
fi

# Calculate backup size
BACKUP_SIZE=$(du -sh "$TARGET_DIR" 2>/dev/null | awk '{print $1}')
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')

# Summary
log "===== Backup Summary ====="
log "Type: $BACKUP_TYPE"
log "VMs: $VM_SUCCESS/$VM_COUNT successful"
log "Containers: $CT_SUCCESS/$CT_COUNT successful"
log "This backup size: $BACKUP_SIZE"
log "Total backup size: $TOTAL_SIZE"
log "Target: $TARGET_DIR"

# Exit with error if any backups failed
TOTAL_COUNT=$((VM_COUNT + CT_COUNT))
TOTAL_SUCCESS=$((VM_SUCCESS + CT_SUCCESS))

if [ "$DRY_RUN" -eq 0 ] && [ $TOTAL_SUCCESS -lt $TOTAL_COUNT ]; then
    log "WARNING: Some backups failed! ($TOTAL_SUCCESS/$TOTAL_COUNT successful)"
    exit 1
fi

log "✅ Backup complete!"
exit 0
