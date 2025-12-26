#!/bin/bash
# VPS Configuration Backup
# Backs up critical configs from VPS to OMV via rsync
#
# Usage: ./backup-vps-configs.sh [--test] [--dry-run]
#
# Installation (on VPS):
# 1. Copy to /usr/local/bin/backup-vps-configs.sh
# 2. chmod +x /usr/local/bin/backup-vps-configs.sh
# 3. Add to cron: 30 2 * * * /usr/local/bin/backup-vps-configs.sh

set -e

# Configuration
BACKUP_DIR="/tmp/vps-backup-$(date +%Y-%m-%d)"
OMV_HOST="root@10.0.10.5"
OMV_PATH="/srv/backups/configs/vps"
LOG_FILE="/var/log/vps-backup.log"

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

log "===== Starting VPS configuration backup ====="

if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY RUN MODE - No actual backups will be performed"
fi

# Create temp backup directory
mkdir -p "$BACKUP_DIR"

# Caddy configuration
if [ -d /etc/caddy ]; then
    log "Backing up Caddy configuration..."
    if [ "$DRY_RUN" -eq 0 ]; then
        cp -r /etc/caddy "$BACKUP_DIR/" 2>&1 | tee -a "$LOG_FILE"
        log "✓ Caddy config backed up"
    else
        log "[DRY RUN] Would backup /etc/caddy"
    fi
fi

# WireGuard configuration
if [ -d /etc/wireguard ]; then
    log "Backing up WireGuard configuration..."
    if [ "$DRY_RUN" -eq 0 ]; then
        cp -r /etc/wireguard "$BACKUP_DIR/" 2>&1 | tee -a "$LOG_FILE"
        log "✓ WireGuard config backed up"
    else
        log "[DRY RUN] Would backup /etc/wireguard"
    fi
fi

# SSL Certificates (from Caddy)
if [ -d /var/lib/caddy/.local/share/caddy ]; then
    log "Backing up SSL certificates..."
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$BACKUP_DIR/ssl-certs"
        cp -r /var/lib/caddy/.local/share/caddy "$BACKUP_DIR/ssl-certs/" 2>&1 | tee -a "$LOG_FILE"
        log "✓ SSL certificates backed up"
    else
        log "[DRY RUN] Would backup SSL certificates"
    fi
fi

# Custom systemd services
if ls /etc/systemd/system/rustdesk-* &> /dev/null; then
    log "Backing up custom systemd services..."
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$BACKUP_DIR/systemd"
        cp /etc/systemd/system/rustdesk-* "$BACKUP_DIR/systemd/" 2>&1 | tee -a "$LOG_FILE"
        log "✓ Systemd services backed up"
    else
        log "[DRY RUN] Would backup systemd services"
    fi
fi

# Network configuration
if [ -d /etc/netplan ] || [ -f /etc/network/interfaces ]; then
    log "Backing up network configuration..."
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$BACKUP_DIR/network"
        cp /etc/netplan/* "$BACKUP_DIR/network/" 2>/dev/null || true
        cp /etc/network/interfaces "$BACKUP_DIR/network/" 2>/dev/null || true
        log "✓ Network config backed up"
    else
        log "[DRY RUN] Would backup network config"
    fi
fi

# SSH configuration
if [ -d /etc/ssh ]; then
    log "Backing up SSH configuration..."
    if [ "$DRY_RUN" -eq 0 ]; then
        cp -r /etc/ssh "$BACKUP_DIR/" 2>&1 | tee -a "$LOG_FILE"
        # Remove host keys for security (can be regenerated)
        rm -f "$BACKUP_DIR/ssh/ssh_host_*" 2>/dev/null || true
        log "✓ SSH config backed up (without host keys)"
    else
        log "[DRY RUN] Would backup SSH config"
    fi
fi

# Installed packages list
log "Saving installed packages list..."
if [ "$DRY_RUN" -eq 0 ]; then
    dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt" 2>&1
    log "✓ Package list saved"
else
    log "[DRY RUN] Would save package list"
fi

# System information
log "Saving system information..."
if [ "$DRY_RUN" -eq 0 ]; then
    cat > "$BACKUP_DIR/system-info.txt" << EOF
Hostname: $(hostname)
Kernel: $(uname -r)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)
Uptime: $(uptime)
Backup Date: $(date)
EOF
    log "✓ System info saved"
else
    log "[DRY RUN] Would save system info"
fi

# Create compressed archive
if [ "$DRY_RUN" -eq 0 ]; then
    log "Creating compressed archive..."
    cd /tmp
    ARCHIVE_NAME="vps-backup-$(date +%Y-%m-%d).tar.gz"
    tar -czf "$ARCHIVE_NAME" "$(basename $BACKUP_DIR)" 2>&1 | tee -a "$LOG_FILE"
    ARCHIVE_SIZE=$(du -sh "$ARCHIVE_NAME" | awk '{print $1}')
    log "✓ Archive created: $ARCHIVE_SIZE"

    # Sync to OMV
    log "Syncing to OMV storage..."
    rsync -avz --progress "$ARCHIVE_NAME" "${OMV_HOST}:${OMV_PATH}/" 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "✓ Backup synced to OMV successfully"

        # Cleanup
        rm -rf "$BACKUP_DIR" "$ARCHIVE_NAME"
        log "✓ Temporary files cleaned up"
    else
        log "✗ Sync to OMV FAILED - keeping local backup"
        log "Local backup: /tmp/$ARCHIVE_NAME"
        exit 1
    fi

    # Cleanup old backups on OMV (keep last 30 days)
    log "Cleaning up old backups on OMV..."
    ssh $OMV_HOST "find $OMV_PATH -name 'vps-backup-*.tar.gz' -mtime +30 -delete" 2>&1 | tee -a "$LOG_FILE"
else
    log "[DRY RUN] Would create archive and sync to OMV"
fi

log "===== VPS backup complete! ====="
exit 0
