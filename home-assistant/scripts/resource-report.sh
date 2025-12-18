#!/bin/bash
#
# Resource Utilization Report
# Generates weekly report of cluster resource usage
#
# Usage: ./resource-report.sh
#

set -euo pipefail

# Configuration
REPORT_FILE="/var/log/infrastructure/resource-report-$(date +%Y%m%d).txt"
EMAIL_TO=""

# Functions
log() {
    echo "$*" | tee -a "$REPORT_FILE"
}

# Generate report
{
    echo "========================================="
    echo "Infrastructure Resource Report"
    echo "Generated: $(date)"
    echo "========================================="
    echo

    echo "=== CLUSTER STATUS ==="
    pvecm status 2>/dev/null || echo "Not in cluster mode"
    echo

    echo "=== NODE RESOURCES ==="
    pvesh get /nodes --output-format json | jq -r '.[] | "\(.node): CPU \(.cpu*100|floor)%, RAM \(.mem/1024/1024/1024|floor)GB/\(.maxmem/1024/1024/1024|floor)GB"' 2>/dev/null || {
        echo "Node information:"
        pvesh get /cluster/resources --type node
    }
    echo

    echo "=== VM/CONTAINER COUNT ==="
    echo "VMs: $(qm list | tail -n +2 | wc -l)"
    echo "Containers: $(pct list | tail -n +2 | wc -l)"
    echo

    echo "=== STORAGE USAGE ==="
    pvesm status
    echo

    echo "=== TOP 10 VMs BY DISK USAGE ==="
    echo "VMID | Name | Disk"
    pvesh get /cluster/resources --type vm --output-format json 2>/dev/null | \
        jq -r 'sort_by(.maxdisk) | reverse | .[:10] | .[] | "\(.vmid) | \(.name) | \(.maxdisk/1024/1024/1024|floor)GB"' || \
        echo "Unable to retrieve VM disk usage"
    echo

    echo "=== TOP 10 VMs BY RAM ALLOCATION ==="
    echo "VMID | Name | RAM"
    pvesh get /cluster/resources --type vm --output-format json 2>/dev/null | \
        jq -r 'sort_by(.maxmem) | reverse | .[:10] | .[] | "\(.vmid) | \(.name) | \(.maxmem/1024/1024/1024|floor)GB"' || \
        echo "Unable to retrieve VM RAM allocation"
    echo

    echo "=== RUNNING VMs/CONTAINERS ==="
    qm list | grep running | awk '{print "VM "$1" - "$2}'
    pct list | grep running | awk '{print "CT "$1" - "$3}'
    echo

    echo "=== RECENT BACKUPS ==="
    find /var/lib/vz/dump/ -name "vzdump-*.log" -mtime -7 -exec basename {} \; 2>/dev/null | head -10 || \
        echo "No recent backups found"
    echo

    echo "========================================="
    echo "End of Report"
    echo "========================================="
} > "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"

# Email report if configured
if [ -n "$EMAIL_TO" ]; then
    mail -s "Weekly Infrastructure Report" "$EMAIL_TO" < "$REPORT_FILE"
    echo "Report emailed to $EMAIL_TO"
fi

exit 0
