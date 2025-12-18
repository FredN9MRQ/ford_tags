#!/bin/bash
#
# Gerbil Tunnel Monitor
# Monitors tunnel status and restarts if disconnected
#
# Usage: ./tunnel-monitor.sh
#

set -euo pipefail

# Configuration
TUNNELS=(
    "gerbil-tunnel-1"
    "gerbil-tunnel-2"
    # Add more tunnel service names
)

LOG_FILE="/var/log/infrastructure/tunnel-monitor.log"
ALERT_EMAIL=""

# Functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    local message="$1"
    log "ALERT: $message"

    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Tunnel Alert" "$ALERT_EMAIL" 2>/dev/null || true
    fi
}

mkdir -p "$(dirname "$LOG_FILE")"

for tunnel in "${TUNNELS[@]}"; do
    # Check if service is running
    if systemctl is-active --quiet "$tunnel"; then
        # Service is running, but is tunnel actually connected?
        # This depends on how Gerbil reports status
        # Adjust the check method for your setup

        # Example: Check if specific port is established
        # if ! ss -tn | grep -q "ESTAB.*:PORT"; then
        #     log "$tunnel service running but no connection"
        #     systemctl restart "$tunnel"
        #     alert "$tunnel was disconnected and has been restarted"
        # fi

        : # Placeholder - implement your connection check
    else
        log "$tunnel is not running, restarting..."
        systemctl restart "$tunnel"

        # Wait and verify restart
        sleep 5
        if systemctl is-active --quiet "$tunnel"; then
            log "$tunnel restarted successfully"
            alert "$tunnel was down and has been restarted"
        else
            log "ERROR: Failed to restart $tunnel"
            alert "CRITICAL: Failed to restart $tunnel"
        fi
    fi
done

log "Tunnel monitor completed"
exit 0
