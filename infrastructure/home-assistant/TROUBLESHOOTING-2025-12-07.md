# Home Assistant Troubleshooting Session - 2025-12-07

## Issue
Home Assistant at 10.0.10.24:8123 is not responding - web interface returns "Empty reply from server"

## Diagnosis
- **Server Status**: Reachable via ping, SSH port open
- **HA Version**: 2025.12.1
- **Problem**: Home Assistant Core is crashing on startup

## Root Cause
**UniFi Integration Error** causing startup failure:
- Error: `Error setting up entry default_config for unifi`
- ValueError: `list.remove(x): x not in list`
- Session/connection errors with UniFi controller

## Solution Steps

### 1. Access Home Assistant Console
Via Proxmox web interface:
- URL: https://10.0.10.3:8006 (main-pve) or https://10.0.10.2:8006 (pve-router)
- Navigate to: Home Assistant VM → Console

### 2. Get Root Shell
At the `ha >` prompt:
```bash
login
```

### 3. Edit Configuration
```bash
nano /config/configuration.yaml
```

Find and comment out the `unifi:` section:
```yaml
# unifi:
#   host: 10.0.10.1
#   username: ...
#   password: ...
```

Or search for it:
```bash
grep -n "unifi" /config/configuration.yaml
```

Save: Ctrl+O, Enter, Exit: Ctrl+X

### 4. Restart Home Assistant
```bash
ha core restart
```

Wait 1-2 minutes, then verify:
```bash
ha core info
ha core logs | tail -50
```

### 5. Test Web Interface
Open browser: http://10.0.10.24:8123

## Alternative: Remove Integration via Files

If UniFi is not in configuration.yaml, it might be in:
```bash
ls -la /config/.storage/
grep -r "unifi" /config/.storage/core.config_entries
```

You may need to edit `/config/.storage/core.config_entries` and remove the UniFi entry.

## Restore from Git (If Needed)

If you want to restore the last known good configuration:
```bash
# On your dev machine
cd /home/fred/projects/infrastructure
./scripts/sync-ha-config.sh

# This requires SSH access to be working
```

## Screenshots Captured
- `Pasted image.png` - ha core info output
- `Pasted image (2).png` - ha core logs showing UniFi errors

## SOLUTION - What Actually Fixed It

### Root Cause Identified
The real problem was **NOT** the UniFi integration crashing Home Assistant. The actual issue was **broken SSL certificate configuration** in `configuration.yaml`.

The configuration had:
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
  ssl_certificate: /config/ssl/bob.crt
  ssl_key: /config/ssl/bob.key
```

The SSL certificates didn't exist or had mismatched keys, causing the HTTP component to fail and cascade into complete system failure.

### Fix Applied
**Via Proxmox Console:**

1. Accessed Proxmox → Home Assistant VM → Console
2. Typed `login` to get root shell
3. Navigated to `/mnt/data/supervisor/homeassistant`
4. Edited `configuration.yaml` and removed these lines:
   - `ssl_certificate: /config/ssl/bob.crt`
   - `ssl_key: /config/ssl/bob.key`
5. Exited to `ha >` prompt and ran `ha core restart`
6. Home Assistant came up successfully at http://10.0.10.24:8123

### Additional Fixes Applied
1. **Migrated legacy switch templates to modern syntax** - Digital Loggers power strip switches converted from `platform: template` to modern `template:` section syntax
2. **Updated git repository** with fixed configuration

## Lessons Learned
1. SSL configuration errors in Home Assistant cause cascading failures across all integrations
2. When troubleshooting HA startup failures, check logs for HTTP component errors first
3. The configuration on the server can differ from git repo - always verify both
4. UniFi integration warnings were a red herring - the real issue was SSL certificates

## Next Steps After Fix
1. ✅ Home Assistant working at http://10.0.10.24:8123
2. ✅ Legacy switch templates migrated to modern syntax
3. ✅ Configuration synchronized to git repository
4. Consider: Set up SSH keys for easier remote access/config sync
5. Consider: Create regular backups of working configuration
6. Optional: Investigate UniFi integration if network device monitoring is desired (not critical)
