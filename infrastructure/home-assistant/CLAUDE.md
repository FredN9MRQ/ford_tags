# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an infrastructure documentation and automation repository for a self-hosted home lab environment. The infrastructure is undergoing a critical architecture transition from Gerbil tunnels to WireGuard VPN connectivity via a UCG Ultra gateway.

### Infrastructure Components

**VPS (Hudson Valley Host - 66.63.182.168)**
- 2 vCPUs, 4GB RAM, 100GB storage, ubuntu-24.04-x86_64
- Pangolin reverse proxy v1.10.3 exposing services at nianticbooks.com
- Services currently DOWN pending WireGuard tunnel restoration

**Home Lab (Proxmox Cluster)**
- **main-pve (DL380p)**: 32 cores, 96GB RAM, IP 10.0.10.3 (primary - heavy workloads, remote location)
- **pve-router (i5)**: 8 cores, 8GB RAM, IP 10.0.10.2 (secondary - local office access)
- **pve-storage**: Proxmox host at 10.0.10.4 running OMV VM (12TB storage, 3.5" drive support)
- **UCG Ultra**: UniFi gateway at 10.0.10.1 handling DHCP, routing, firewall, WireGuard VPN

### Network Configuration

**Subnet:** 10.0.10.0/24
**DHCP Pool:** 10.0.10.50-254
**Static/Reserved:** 10.0.10.1-49 (infrastructure and services)

See `IP-ALLOCATION.md` for complete IP addressing plan.

### Active Service Routes (Currently Down)

Pangolin routes at nianticbooks.com (need WireGuard tunnel + IP updates):
- `freddesk` → 10.0.10.3:8006 (Proxmox web interface - main-pve)
- `auth` → 10.0.10.21:9000 (Authentik SSO - planned)
- `ad5m` → 10.0.10.30:80 (Prusa 3D printer)
- `bob` → 10.0.10.24:8123 (Home Assistant)
- `spools` → REMOVE (deprecated)

## Documentation Structure

This repository follows a specific documentation architecture:

**Living Documentation:**
- `infrastructure-audit.md` - Real-time infrastructure state (actively being filled out)
- `IP-ALLOCATION.md` - **Complete network IP allocation plan (10.0.10.0/24)**
- `MIGRATION-CHECKLIST.md` - **Step-by-step IP migration and WireGuard setup checklist**
- `IMPROVEMENTS.md` - Enhancement tracking and feature requests
- `MORNING-REMINDER.md` - Cross-machine sync instructions and daily priorities

**Reference Guides:**
- `BRAINSTORM.md` - Original planning session with Phase 1-8 deployment roadmap
- `RUNBOOK.md` - Step-by-step operational procedures (Pangolin, Proxmox, SSL certs, network troubleshooting)
- `SERVICES.md` - Service configuration templates
- `DISASTER-RECOVERY.md` - Recovery procedures for failure scenarios
- `MONITORING.md` - Monitoring setup guidance

**Automation:**
- `scripts/README.md` - Script usage, deployment, and scheduling instructions
- All scripts are templates requiring environment-specific customization
- Scripts support `--dry-run` and `--test` flags - always test before production use
- Logs should go to `/var/log/infrastructure/` (must be created first)

## Working with Scripts

### Script Testing Protocol

```bash
# Always test scripts before production deployment
./script-name.sh --dry-run    # Preview actions without executing
./script-name.sh --test --verbose  # Test mode with detailed output
```

### Script Deployment Process

```bash
# 1. Customize script variables for your environment
# 2. Copy to target host
scp scripts/script-name.sh user@host:/usr/local/bin/

# 3. Make executable
ssh user@host "chmod +x /usr/local/bin/script-name.sh"

# 4. Set up automation (cron or systemd timer)
# See scripts/README.md for scheduling examples
```

### Key Scripts

- `backup-proxmox.sh` - Proxmox VM/container backups (daily on Proxmox nodes)
- `backup-vps.sh` - VPS configuration backups (daily on VPS)
- `health-check.sh` - Service health monitoring (every 5-15 min)
- `cert-check.sh` - SSL expiration monitoring (daily)
- `tunnel-monitor.sh` - **NEEDS UPDATE** for WireGuard (currently monitors deprecated Gerbil tunnels)
- `resource-report.sh` - Weekly utilization reports

## Critical Architecture Considerations

### Resource Allocation Strategy

**VPS (2 CPU / 4GB RAM) - Lightweight Only:**
- Pangolin reverse proxy
- RustDesk relay server (hbbr) - ~30-50MB RAM for NAT traversal

**DL380p (32 CPU / 96GB RAM) - Heavy Workloads:**
- PostgreSQL (shared database for all services)
- Authentik SSO with WebAuthn/FIDO2
- n8n workflow automation
- RustDesk ID server (hbbs)
- Prometheus + Grafana monitoring

### WireGuard Tunnel Architecture (In Progress)

**Critical Priority:** Services are down until this is configured

- VPS acts as WireGuard server (endpoint: 66.63.182.168)
- UCG Ultra acts as WireGuard client
- Default port: 51820 (customizable)
- Tunnel subnet: TBD (e.g., 10.0.8.0/24)
- Pangolin must route home lab traffic through tunnel

### IP Address Management

**Network:** 10.0.10.0/24
**DHCP Pool:** 10.0.10.50-254
**Static/Reserved:** 10.0.10.1-49

**Requirements:**
- UCG Ultra handles DHCP (replaced previous DHCP configuration)
- Critical infrastructure uses DHCP reservations (preferred) or static IPs
- All reservations documented in `IP-ALLOCATION.md` and `infrastructure-audit.md`
- mDNS references (like `homeassistant.local`) converted to static IPs (.24)

**Key Infrastructure IPs:**
- 10.0.10.1 - UCG Ultra (gateway)
- 10.0.10.2 - pve-router (i5 Proxmox)
- 10.0.10.3 - main-pve (DL380p Proxmox)
- 10.0.10.4 - pve-storage (Proxmox host)
- 10.0.10.5 - openmediavault (12TB storage VM)
- 10.0.10.13 - HP iLO (DL380p management)
- 10.0.10.24 - Home Assistant
- 10.0.10.88 - Digital Loggers Web Power Switch (8 outlets)

## Home Assistant Configuration Management

Home Assistant configurations are version-controlled in the `home-assistant/` directory.

### Directory Structure

```
home-assistant/
├── configuration.yaml      # Main config with includes
├── automations.yaml       # Automations (UI-managed)
├── scripts.yaml          # Scripts (UI-managed)
├── scenes.yaml           # Scenes (UI-managed)
├── switches.yaml         # Custom RESTful/template switches
├── lights.yaml           # Light groups (e.g., Christmas lights)
├── secrets.yaml          # Credentials (gitignored)
├── secrets.yaml.example  # Template for secrets
├── .gitignore           # Excludes sensitive files
└── README.md            # HA-specific documentation
```

### Configuration Sync Workflow

**1. Edit locally:**
```bash
cd home-assistant/
# Edit configuration files using Claude Code or your preferred editor
```

**2. Test locally:**
- Review changes carefully
- Ensure YAML syntax is valid

**3. Commit to git:**
```bash
git add home-assistant/
git commit -m "Update HA config: [description]"
git push
```

**4. Deploy to Home Assistant:**
```powershell
# Windows (PowerShell)
.\scripts\sync-ha-config.ps1

# Check only (no changes)
.\scripts\sync-ha-config.ps1 -CheckOnly

# Dry run (preview changes)
.\scripts\sync-ha-config.ps1 -DryRun
```

```bash
# Linux/Mac
./scripts/sync-ha-config.sh

# Check only
./scripts/sync-ha-config.sh --check-only

# Dry run
./scripts/sync-ha-config.sh --dry-run
```

**5. Validate in Home Assistant:**
- Go to http://10.0.10.24:8123
- Developer Tools → YAML → Check Configuration
- If valid: Reload specific sections or restart HA

### Sync Script Features

- **Automatic backups**: Creates timestamped backup before syncing
- **Connectivity checks**: Verifies HA server is reachable
- **Samba/SCP support**: PowerShell uses Samba, Bash uses SCP
- **Dry run mode**: Preview changes without applying
- **Check mode**: Compare local vs remote files

### Current Integrations

**Smart Devices:**
- Govee Curtain Lights (Official Govee LAN - local control)
- Sylvania Smart+ WiFi Plug via LocalTuya
- TP-Link Tapo Outdoor Plug
- Digital Loggers Web Power Switch (10.0.10.88) - 8 controllable outlets via RESTful switches
- **Christmas Lights Group**: `light.all_christmas_lights` (includes Govee curtains, Sylvania plug, Tapo outdoor plug, and Govee LED tree when added)

**Voice Assistant:**
- Wyoming Protocol: Gaming PC (10.0.10.92) provides Whisper STT, Piper TTS, OpenWakeWord

**Other:**
- Weather (Met.no)
- Local Todo lists
- ESPHome integration (10.0.10.28)

### Important Notes

- **NEVER commit secrets.yaml** - contains credentials for integrations
- Use `secrets.yaml.example` as template for new secrets
- Digital Loggers switches use command_line platform (requires `curl` in HA OS)
- Govee devices require LAN Control enabled in Govee app
- LocalTuya devices need local keys from Tuya IoT Platform

## Planned Service Deployments

### Authentik SSO (Priority 1)

**Critical Requirement:** WebAuthn/FIDO2 hardware authentication
- Supported: iPhone Face ID, Windows Hello (no YubiKey required)
- Integration targets: Proxmox (OpenID), n8n (OAuth2), Grafana, HomeAssistant
- Location: main-pve (DL380p) at 10.0.10.21:9000
- Public route: auth.nianticbooks.com

### RustDesk (Self-Hosted Remote Desktop)

**Split Architecture:**
- **VPS**: Relay server (hbbr) for NAT traversal (~30-50MB RAM)
- **main-pve (DL380p)**: ID server (hbbs) at 10.0.10.23 (~2 cores, ~2GB RAM, 10GB storage)

### Other Planned Services

- **PostgreSQL**: 10.0.10.20 on main-pve (~2 cores, ~4GB RAM, 20GB storage) - shared by Authentik, n8n, RustDesk, Grafana
- **n8n**: 10.0.10.22 on main-pve (~4 cores, ~4GB RAM, 40GB storage) with Authentik OAuth2
- **Prometheus/Grafana**: 10.0.10.25 on main-pve - centralized monitoring

### Currently Running Services (Need IP Migration)

- **Home Assistant**: 10.0.10.24 ✅ MIGRATED - smart home automation
- **ESPHome**: 10.0.10.28 (currently .113) - ESP device management
- **Dockge**: 10.0.10.27 (currently .104) - Docker compose management
- **OpenMediaVault**: 10.0.10.5 (currently .178) - 12TB storage management

## Multi-Machine Git Workflow

This repository is designed for use across multiple machines (VPS, Mac Pro, potentially others).

**Before switching machines:**
```bash
git add .
git commit -m "Description of changes"
git push
```

**On new machine:**
```bash
cd infrastructure
git pull
```

See `MORNING-REMINDER.md` for the complete workflow reference.

## Key Constraints and Warnings

- VPS has severe resource constraints - only lightweight services
- All automation scripts require customization before deployment
- Services currently down - WireGuard tunnel is blocking dependency
- `tunnel-monitor.sh` needs updating for WireGuard (currently monitors deprecated Gerbil)
- Test all scripts with `--dry-run` before production use
