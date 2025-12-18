#!/bin/bash
#
# SSL Certificate Expiration Check
# Alerts when certificates are expiring soon
#
# Usage: ./cert-check.sh [--days N]
#

set -euo pipefail

# Configuration
WARN_DAYS=30  # Warn if cert expires within this many days
LOG_FILE="/var/log/infrastructure/cert-check.log"
ALERT_EMAIL=""
SLACK_WEBHOOK=""

# Domains to check
DOMAINS=(
    "example.com"
    "service1.example.com"
    "service2.example.com"
)

# Functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    local message="$1"
    log "ALERT: $message"

    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Certificate Expiration Alert" "$ALERT_EMAIL" 2>/dev/null || true
    fi

    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Certificate Alert: $message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --days)
            WARN_DAYS="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [--days N]"
            exit 1
            ;;
    esac
done

mkdir -p "$(dirname "$LOG_FILE")"

log "Checking SSL certificates (warning threshold: $WARN_DAYS days)"

EXPIRING_CERTS=0

for domain in "${DOMAINS[@]}"; do
    log "Checking $domain..."

    # Get certificate expiration date
    expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$expiry_date" ]; then
        log "  ERROR: Could not retrieve certificate for $domain"
        alert "Failed to retrieve certificate for $domain"
        ((EXPIRING_CERTS++))
        continue
    fi

    # Convert to epoch for comparison
    expiry_epoch=$(date -d "$expiry_date" +%s)
    now_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [ "$days_until_expiry" -lt 0 ]; then
        log "  ✗ EXPIRED! Expired on $expiry_date"
        alert "$domain certificate EXPIRED on $expiry_date"
        ((EXPIRING_CERTS++))
    elif [ "$days_until_expiry" -lt "$WARN_DAYS" ]; then
        log "  ⚠ WARNING: Expires in $days_until_expiry days ($expiry_date)"
        alert "$domain certificate expires in $days_until_expiry days"
        ((EXPIRING_CERTS++))
    else
        log "  ✓ OK: Valid for $days_until_expiry days (expires $expiry_date)"
    fi
done

if [ "$EXPIRING_CERTS" -eq 0 ]; then
    log "All certificates are valid"
    exit 0
else
    log "Found $EXPIRING_CERTS certificate(s) expiring soon or expired"
    exit 1
fi
