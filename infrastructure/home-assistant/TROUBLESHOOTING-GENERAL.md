# Home Assistant Troubleshooting Guide

Comprehensive guide for diagnosing and fixing common Home Assistant issues.

## Table of Contents
- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Access Methods](#access-methods)
- [Configuration Issues](#configuration-issues)
- [Integration Problems](#integration-problems)
- [Performance Issues](#performance-issues)
- [Network Issues](#network-issues)
- [Recovery Procedures](#recovery-procedures)

## Environment Information

**Home Assistant Details:**
- **IP Address:** 10.0.10.24
- **Web Interface:** http://10.0.10.24:8123
- **Proxmox Hosts:**
  - main-pve: https://10.0.10.3:8006
  - pve-router: https://10.0.10.2:8006
- **Configuration Location:** `/config/` (inside HA container)
- **Git Repository:** `C:\Users\Fred\projects\infrastructure\home-assistant\`

## Quick Diagnostics

### Is Home Assistant Running?

```bash
# From any machine on network
ping 10.0.10.24

# Test web interface
curl -I http://10.0.10.24:8123

# From Proxmox host
pct status <CTID>  # Or qm status <VMID> if it's a VM
```

### Check Logs

**Via Web Interface (if accessible):**
- Settings → System → Logs

**Via Console:**
```bash
# Get to ha prompt via Proxmox console, then:
ha core logs | tail -100

# Filter for errors
ha core logs | grep -i error

# Watch logs in real-time
ha core logs -f
```

**Via SSH (if enabled):**
```bash
ssh root@10.0.10.24
ha core logs | tail -100
```

### Check Core Status

```bash
# At ha> prompt
ha core info
ha core check

# See all components
ha core stats
```

## Common Issues

### Issue 1: Web Interface Not Loading

**Symptoms:**
- Browser shows "Empty reply from server"
- Connection timeout
- "This site can't be reached"

**Diagnosis Steps:**

1. **Check if HA is running:**
   ```bash
   # Via Proxmox
   pct status <CTID>

   # Via console
   ha core info
   ```

2. **Check for startup errors:**
   ```bash
   ha core logs | tail -100
   ```

**Common Causes:**

**A. SSL Certificate Configuration Error**
- Symptoms: Logs show HTTP component failing to start
- Solution: Remove or fix SSL certificate configuration

```bash
# Via console
login
nano /config/configuration.yaml

# Find and comment out or fix:
# ssl_certificate: /path/to/cert
# ssl_key: /path/to/key

# Restart
ha core restart
```

**B. Port Already in Use**
- Symptoms: "Address already in use" in logs
- Solution: Check for conflicting services

```bash
# Find what's using port 8123
netstat -tlnp | grep 8123

# Kill conflicting process or change HA port
```

**C. Memory/Resource Exhaustion**
- Symptoms: HA crashes shortly after startup
- Solution: Check container/VM resources

```bash
# Via Proxmox web UI
# Check Memory and CPU allocation
# Increase if needed

# Or check inside container
free -h
top
```

### Issue 2: Configuration Validation Errors

**Symptoms:**
- HA won't start after configuration changes
- "Configuration invalid" message

**Diagnosis:**

```bash
# Check configuration
ha core check

# View specific errors
ha core logs | grep -i "invalid\|error"
```

**Common Configuration Errors:**

**A. YAML Syntax Errors**
```yaml
# WRONG - missing space after colon
sensor:
  - platform:mqtt

# CORRECT
sensor:
  - platform: mqtt
```

**B. Indentation Errors**
```yaml
# WRONG - inconsistent indentation
automation:
  - alias: Test
  trigger:  # Should be indented 4 spaces
    platform: state

# CORRECT
automation:
  - alias: Test
    trigger:
      platform: state
```

**C. Legacy Syntax (Needs Migration)**
```yaml
# OLD syntax (pre-2024)
switch:
  - platform: template
    switches:
      my_switch:
        value_template: "{{ states('input_boolean.test') }}"

# NEW syntax
template:
  - switch:
      - name: "My Switch"
        state: "{{ states('input_boolean.test') }}"
```

**Fix Process:**

1. Access console
2. Edit `/config/configuration.yaml`
3. Fix syntax errors
4. Run `ha core check`
5. If valid, `ha core restart`

### Issue 3: Integration Failures

**Symptoms:**
- Specific integration not working
- Errors in logs mentioning integration name

**Common Integration Issues:**

**A. UniFi Integration Error**
- Symptoms: `Error setting up entry default_config for unifi`
- Cause: Connection issues with UniFi controller
- Solutions:
  1. Check UniFi controller is accessible
  2. Verify credentials
  3. Temporarily disable integration to allow HA to start:
     ```bash
     # Remove from configuration.yaml or
     # Delete from .storage/core.config_entries
     ```

**B. MQTT Integration**
- Symptoms: Devices not updating, MQTT unavailable
- Solutions:
  ```bash
  # Check MQTT broker is running
  # Settings → Devices & Services → MQTT
  # Test connection

  # From MQTT broker
  mosquitto -v

  # Test publish/subscribe
  mosquitto_pub -h 10.0.10.24 -t test -m "hello"
  mosquitto_sub -h 10.0.10.24 -t test
  ```

**C. Google Calendar**
- Symptoms: Calendar not syncing
- Causes: OAuth token expired, API quota exceeded
- Solutions:
  1. Re-authenticate integration
  2. Check Google Cloud Console for API errors
  3. Verify OAuth consent screen status

### Issue 4: Automations Not Working

**Symptoms:**
- Automations not triggering
- Actions not executing

**Diagnosis:**

```bash
# Check automation config
ha core check

# View automation traces
# Web UI: Settings → Automations & Scenes → [Select automation] → Traces

# Check logs for automation errors
ha core logs | grep automation
```

**Common Causes:**

**A. Trigger Not Firing**
```yaml
# Verify entity exists and state is changing
# Developer Tools → States → Search for entity
# Watch for state changes
```

**B. Condition Not Met**
```yaml
# Check condition logic
# Automations can have conditions that prevent execution
# Test without conditions first
```

**C. Action Service Not Available**
```yaml
# Verify service exists
# Developer Tools → Services
# Try calling service manually
```

### Issue 5: Database Growing Too Large

**Symptoms:**
- Slow web interface
- High disk usage
- Database errors in logs

**Solutions:**

```bash
# Check database size
du -h /config/home-assistant_v2.db

# Purge old data
# Web UI: Settings → System → Repairs
# Or via service call:
# Developer Tools → Services
# Service: recorder.purge
# Data: {"keep_days": 7, "repack": true}
```

**Prevention:**

```yaml
# Add to configuration.yaml
recorder:
  purge_keep_days: 7
  commit_interval: 30
  exclude:
    domains:
      - sun
      - updater
    entities:
      - sensor.high_frequency_sensor
```

## Access Methods

### Method 1: Proxmox Console

1. Open Proxmox web interface
   - https://10.0.10.3:8006 (main-pve)
   - https://10.0.10.2:8006 (pve-router)
2. Navigate to: Home Assistant VM/CT → Console
3. At `ha >` prompt, type `login` for root shell

### Method 2: SSH (If Enabled)

```bash
# Enable SSH Add-on first via web UI
# Settings → Add-ons → SSH Server

ssh root@10.0.10.24
# Or if using SSH add-on on different port
ssh -p 22222 root@10.0.10.24
```

### Method 3: Safe Mode

```bash
# Start HA in safe mode (disables custom integrations)
ha core options --safe-mode
ha core restart

# After troubleshooting, disable safe mode
ha core options --no-safe-mode
ha core restart
```

## Configuration Issues

### Backup Configuration Before Changes

```bash
# From dev machine
cd C:\Users\Fred\projects\infrastructure\home-assistant
git add .
git commit -m "Backup before changes"

# Or via console
cp /config/configuration.yaml /config/configuration.yaml.backup
```

### Common Configuration Files

```
/config/
├── configuration.yaml       # Main config
├── automations.yaml        # Automations
├── scripts.yaml            # Scripts
├── scenes.yaml             # Scenes
├── secrets.yaml            # Secrets (not in git)
├── .storage/               # Integration configs
│   ├── core.config_entries
│   └── ...
└── home-assistant_v2.db    # Database
```

### Synchronizing Configuration

**Push to Server:**
```powershell
# From dev machine
cd C:\Users\Fred\projects\infrastructure\home-assistant

# Using script
.\sync-ha-config.ps1

# Or manually via SCP
scp configuration.yaml root@10.0.10.24:/config/
scp automations.yaml root@10.0.10.24:/config/
scp scripts.yaml root@10.0.10.24:/config/
```

**Pull from Server:**
```powershell
scp root@10.0.10.24:/config/configuration.yaml .
scp root@10.0.10.24:/config/automations.yaml .
```

### Validating Configuration

**Before Applying Changes:**
```bash
# Check config validity
ha core check

# If errors found
ha core logs | grep -i "invalid\|error"

# Fix errors in configuration files
# Then check again
```

## Integration Problems

### Debugging Integration Issues

1. **Check Integration Status**
   - Settings → Devices & Services
   - Look for error icons

2. **View Integration Logs**
   ```bash
   ha core logs | grep -i "[integration-name]"
   ```

3. **Reload Integration**
   - Settings → Devices & Services → [Integration] → Reload

4. **Remove and Re-add**
   - Remove integration
   - Restart HA
   - Re-add integration

### ESPHome Integration

**Issue: Devices offline/unavailable**

```bash
# Ping device
ping esphome-device.local

# Check ESPHome dashboard
http://10.0.10.24:6052

# Check device logs (via ESPHome dashboard)
# Or via CLI
esphome logs device-name.yaml
```

**Solution:**
- Check WiFi signal strength
- Verify mDNS working on network
- Use static IP instead of .local
- Update ESPHome firmware

## Performance Issues

### Slow Web Interface

**Causes:**
- Large database
- Too many entities
- Resource constraints
- Frontend cache issues

**Solutions:**

```bash
# 1. Check resource usage
top
free -h

# 2. Clear frontend cache
# In browser: Ctrl+Shift+R (hard refresh)

# 3. Purge database
# Developer Tools → Services → recorder.purge

# 4. Check for slow integrations
ha core logs | grep -i "slow"
```

### High CPU Usage

```bash
# Identify culprit
top

# Check for polling integrations
# Settings → Devices & Services
# Look for integrations with high poll rates

# Reduce polling frequency in configuration
```

### Memory Leaks

```bash
# Monitor memory over time
watch -n 5 free -h

# Restart HA to clear
ha core restart

# If persistent, check for problematic custom components
```

## Network Issues

### Can't Reach Devices

**Check Network Connectivity:**
```bash
# From HA console
ping 10.0.10.1  # Gateway
ping 10.0.10.24  # Self
ping 8.8.8.8     # Internet

# Check routing
ip route

# Check firewall
iptables -L
```

**Check DNS:**
```bash
# Test DNS resolution
nslookup google.com
nslookup esphome-device.local

# If issues, check /etc/resolv.conf
cat /etc/resolv.conf
```

### Firewall Issues

```bash
# On Proxmox host, check firewall
# Datacenter → Firewall

# Or via command line
pve-firewall status
```

## Recovery Procedures

### Restore from Backup

**Via Proxmox:**
1. Proxmox → Backups → Select backup
2. Restore → Start
3. Wait for completion
4. Start VM/Container

**Via Snapshot:**
```bash
# Create snapshot before risky changes
pct snapshot <CTID> <snapshot-name>

# Restore snapshot if needed
pct rollback <CTID> <snapshot-name>
```

### Restore Configuration from Git

```bash
# On dev machine
cd C:\Users\Fred\projects\infrastructure\home-assistant

# Identify last good commit
git log --oneline

# Copy to server
scp configuration.yaml root@10.0.10.24:/config/
scp automations.yaml root@10.0.10.24:/config/
scp scripts.yaml root@10.0.10.24:/config/

# Restart HA
ssh root@10.0.10.24 "ha core restart"
```

### Factory Reset (Last Resort)

**Warning: This will erase all configuration!**

```bash
# Backup first!
# Then:
ha core rebuild
```

## Preventive Maintenance

### Weekly Tasks
- Review logs for errors: `ha core logs | grep -i error`
- Check database size: `du -h /config/home-assistant_v2.db`
- Verify backups are running

### Monthly Tasks
- Update Home Assistant: Settings → System → Updates
- Update add-ons
- Purge old database entries
- Test restore from backup

### Best Practices
- Always test configuration before restarting: `ha core check`
- Commit configuration changes to git
- Create snapshot before major changes
- Document custom configurations
- Keep secrets.yaml out of version control

## Recent Issues and Resolutions

### 2025-12-07: SSL Certificate Causing Startup Failure
- **Issue:** HA not starting after SSL cert configuration
- **Cause:** Invalid/missing SSL certificates in configuration.yaml
- **Solution:** Removed SSL certificate lines from http: section
- **Prevention:** Verify cert files exist before configuring SSL
- **Details:** See `TROUBLESHOOTING-2025-12-07.md`

### Legacy Template Switch Migration
- **Issue:** Warnings about deprecated template platform
- **Cause:** Old `platform: template` syntax under switch:
- **Solution:** Migrated to modern `template:` section syntax
- **Prevention:** Follow HA breaking changes announcements

## Useful Commands Reference

```bash
# Core management
ha core info                  # Show HA info
ha core check                 # Validate config
ha core logs                  # View logs
ha core restart               # Restart HA
ha core stop                  # Stop HA
ha core start                 # Start HA
ha core update                # Update HA
ha core rebuild               # Factory reset

# Supervisor
ha supervisor info            # Supervisor info
ha supervisor reload          # Reload supervisor
ha supervisor logs            # Supervisor logs

# Add-ons
ha addons                     # List add-ons
ha addons info <addon>        # Add-on info
ha addons logs <addon>        # Add-on logs
ha addons restart <addon>     # Restart add-on

# System
ha os info                    # OS info
ha host reboot                # Reboot host
ha host shutdown              # Shutdown host

# Network
ha network info               # Network info
ha dns info                   # DNS info
```

## External Resources

- [Home Assistant Forums](https://community.home-assistant.io/)
- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [Breaking Changes](https://www.home-assistant.io/blog/categories/release-notes/)
- [GitHub Issues](https://github.com/home-assistant/core/issues)

## Contact Information

**For infrastructure issues:**
- Check this documentation first
- Review git repository history for recent changes
- Consult Proxmox logs if HA container/VM issues

---

**Last Updated:** 2025-12-13
**Version:** 1.0
