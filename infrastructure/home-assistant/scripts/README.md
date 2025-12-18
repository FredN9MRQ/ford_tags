# Automation Scripts

This directory contains example automation scripts for managing your infrastructure. Customize these scripts based on your specific environment.

## Available Scripts

| Script | Purpose | Run On | Frequency |
|--------|---------|--------|-----------|
| `backup-proxmox.sh` | Backup Proxmox VMs and configurations | Proxmox Node | Daily |
| `backup-vps.sh` | Backup VPS configurations and data | VPS | Daily |
| `health-check.sh` | Check health of all services | Any monitoring host | Every 5-15 min |
| `cert-check.sh` | Monitor SSL certificate expiration | VPS or monitoring host | Daily |
| `cleanup-old-backups.sh` | Remove old backups based on retention | Backup storage host | Weekly |
| `tunnel-monitor.sh` | Monitor and restart Gerbil tunnels | Home lab hosts | Every 5 min |
| `resource-report.sh` | Generate resource utilization report | Proxmox Node | Weekly |

## Usage

1. **Copy to appropriate host**:
   ```bash
   scp scripts/script-name.sh user@host:/usr/local/bin/
   ```

2. **Make executable**:
   ```bash
   chmod +x /usr/local/bin/script-name.sh
   ```

3. **Set up cron job** (example):
   ```bash
   # Edit crontab
   crontab -e

   # Daily backup at 2 AM
   0 2 * * * /usr/local/bin/backup-proxmox.sh

   # Health check every 5 minutes
   */5 * * * * /usr/local/bin/health-check.sh
   ```

4. **Or create systemd timer** (preferred):
   ```bash
   # See systemd-timer-examples/ directory
   ```

## Configuration

Most scripts read configuration from:
- Environment variables
- Config files in `/etc/infrastructure/`
- Command line arguments

Edit scripts to match your environment before deploying.

## Logging

Scripts log to:
- `/var/log/infrastructure/` (create this directory)
- Systemd journal (if run as service)
- Syslog

## Alerting

For critical failures, scripts can:
- Send email via mailx/sendmail
- Post to Slack/Discord webhook
- Create incident in monitoring system
- Send SMS via Twilio/similar

Configure alerting methods in each script's configuration section.

## Security Notes

- Store sensitive credentials in environment variables or secure vaults
- Restrict script permissions: `chmod 700`
- Run as dedicated service account, not root (where possible)
- Audit log access regularly

## Testing

Always test scripts in a non-production environment first:

```bash
# Dry run mode (if supported)
./backup-proxmox.sh --dry-run

# Test mode with verbose output
./health-check.sh --test --verbose
```
