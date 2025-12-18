#!/bin/bash
# Home Assistant Configuration Sync Script (Linux/Mac)
# Syncs local config files to Home Assistant server via SCP

HA_SERVER="${HA_SERVER:-10.0.10.24}"
HA_USER="${HA_USER:-root}"
CONFIG_DIR="$(dirname "$0")/../home-assistant"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DRY_RUN=false
CHECK_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --server)
            HA_SERVER="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--check-only] [--server IP]"
            exit 1
            ;;
    esac
done

echo "====================================="
echo "Home Assistant Config Sync"
echo "====================================="
echo "Source: $CONFIG_DIR"
echo "Target: $HA_USER@$HA_SERVER:/config"
echo ""

# Check if config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "ERROR: Config directory not found: $CONFIG_DIR"
    exit 1
fi

# Check if server is reachable
echo "Checking connectivity to $HA_SERVER..."
if ! ping -c 1 -W 2 "$HA_SERVER" &>/dev/null; then
    echo "ERROR: Cannot reach Home Assistant server at $HA_SERVER"
    exit 1
fi
echo "✓ Server is reachable"

# Check SSH access
echo "Checking SSH access..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$HA_USER@$HA_SERVER" exit &>/dev/null; then
    echo "ERROR: Cannot SSH to $HA_USER@$HA_SERVER"
    echo "Make sure SSH add-on is installed and SSH keys are set up"
    exit 1
fi
echo "✓ SSH access OK"
echo ""

# Files to sync
FILES_TO_SYNC=(
    "configuration.yaml"
    "automations.yaml"
    "scripts.yaml"
    "scenes.yaml"
    "switches.yaml"
    "secrets.yaml"
)

if [ "$CHECK_ONLY" = true ]; then
    echo "Configuration check mode - comparing local vs remote files:"
    echo ""

    for file in "${FILES_TO_SYNC[@]}"; do
        local_file="$CONFIG_DIR/$file"
        if [ -f "$local_file" ]; then
            local_hash=$(md5sum "$local_file" | awk '{print $1}')
            remote_hash=$(ssh "$HA_USER@$HA_SERVER" "md5sum /config/$file 2>/dev/null | awk '{print \$1}'")

            if [ -z "$remote_hash" ]; then
                echo "  + $file - New file"
            elif [ "$local_hash" = "$remote_hash" ]; then
                echo "  ✓ $file - No changes"
            else
                echo "  ⚠ $file - Modified"
            fi
        fi
    done
    echo ""
    echo "Use without --check-only flag to sync files"
    exit 0
fi

# Create backup on remote server
echo "Creating backup on remote server..."
ssh "$HA_USER@$HA_SERVER" "mkdir -p /config/backup_$TIMESTAMP"
for file in "${FILES_TO_SYNC[@]}"; do
    ssh "$HA_USER@$HA_SERVER" "[ -f /config/$file ] && cp /config/$file /config/backup_$TIMESTAMP/ || true"
done
echo "✓ Backup created at /config/backup_$TIMESTAMP"
echo ""

# Sync files
echo "Syncing configuration files..."
SYNC_COUNT=0

for file in "${FILES_TO_SYNC[@]}"; do
    local_file="$CONFIG_DIR/$file"

    if [ -f "$local_file" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [DRY RUN] Would copy: $file"
        else
            if scp "$local_file" "$HA_USER@$HA_SERVER:/config/$file" &>/dev/null; then
                echo "  ✓ $file"
                ((SYNC_COUNT++))
            else
                echo "  ✗ $file - ERROR"
            fi
        fi
    else
        echo "  - $file (not found locally, skipping)"
    fi
done

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete. No files were actually copied."
else
    echo "Sync complete! $SYNC_COUNT file(s) copied."
    echo ""
    echo "Next steps:"
    echo "1. Go to Home Assistant: http://$HA_SERVER:8123"
    echo "2. Developer Tools → YAML → Check Configuration"
    echo "3. If valid, reload or restart Home Assistant"
    echo ""
    echo "Backup location: /config/backup_$TIMESTAMP"
fi
