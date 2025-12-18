#!/bin/bash
#
# Infrastructure Health Check Script
# Checks health of all critical services
#
# Usage: ./health-check.sh [--verbose]
#

set -euo pipefail

# Configuration
LOG_FILE="/var/log/infrastructure/health-check.log"
ALERT_EMAIL=""
SLACK_WEBHOOK=""

# Service definitions (customize for your environment)
VPS_HOST="YOUR_VPS_IP"
VPS_USER="root"

# Services to check (format: "name|check_command|expected_result")
CHECKS=(
    "VPS SSH|ssh -o ConnectTimeout=5 $VPS_USER@$VPS_HOST 'echo ok'|ok"
    "Pangolin Service|ssh $VPS_USER@$VPS_HOST 'systemctl is-active pangolin'|active"
    "Gerbil Server|ssh $VPS_USER@$VPS_HOST 'systemctl is-active gerbil-server'|active"
    "VPS Disk Space|ssh $VPS_USER@$VPS_HOST 'df -h / | tail -1 | awk {print \$5} | sed s/%//'|<90"
    # Add more checks here
)

# Functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    local message="$1"
    log "ALERT: $message"

    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Health Check Alert" "$ALERT_EMAIL" 2>/dev/null || true
    fi

    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Health Check Alert: $message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Parse arguments
VERBOSE=false
if [ "${1:-}" = "--verbose" ]; then
    VERBOSE=true
fi

mkdir -p "$(dirname "$LOG_FILE")"

# Run checks
FAILED_CHECKS=0
TOTAL_CHECKS=0

for check in "${CHECKS[@]}"; do
    IFS='|' read -r name command expected <<< "$check"
    ((TOTAL_CHECKS++))

    if [ "$VERBOSE" = true ]; then
        log "Checking: $name"
    fi

    # Execute check
    result=$(eval "$command" 2>/dev/null || echo "FAILED")

    # Evaluate result
    if [ "$expected" = "<90" ]; then
        # Numeric comparison for disk space
        if [ "$result" -lt 90 ] 2>/dev/null; then
            [ "$VERBOSE" = true ] && log "  ✓ $name: OK ($result%)"
        else
            log "  ✗ $name: FAILED (${result}% >= 90%)"
            alert "$name check failed: Disk usage at ${result}%"
            ((FAILED_CHECKS++))
        fi
    else
        # String comparison
        if [ "$result" = "$expected" ]; then
            [ "$VERBOSE" = true ] && log "  ✓ $name: OK"
        else
            log "  ✗ $name: FAILED (expected: $expected, got: $result)"
            alert "$name check failed: expected '$expected', got '$result'"
            ((FAILED_CHECKS++))
        fi
    fi
done

# Summary
if [ "$FAILED_CHECKS" -eq 0 ]; then
    [ "$VERBOSE" = true ] && log "All checks passed ($TOTAL_CHECKS/$TOTAL_CHECKS)"
    exit 0
else
    log "Health check completed with failures: $FAILED_CHECKS/$TOTAL_CHECKS checks failed"
    exit 1
fi
