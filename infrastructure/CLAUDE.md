# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an infrastructure documentation and automation repository for a self-hosted home lab environment. The infrastructure is undergoing a critical architecture transition from Gerbil tunnels to WireGuard VPN connectivity via a UCG Ultra gateway.

### Infrastructure Components

**VPS (Hudson Valley Host - 66.63.182.168)**
- 2 vCPUs, 4GB RAM, 100GB storage, ubuntu-24.04-x86_64
- Caddy reverse proxy exposing services at nianticbooks.com (migrated from Pangolin)
- WireGuard VPN server (10.0.8.1) providing site-to-site connectivity

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

### Active Service Routes

Caddy routes at nianticbooks.com via WireGuard tunnel (10.0.8.0/24):
- `freddesk.nianticbooks.com` → 10.0.10.3:8006 (Proxmox web interface - main-pve)
- `bob.nianticbooks.com` → 10.0.10.24:8123 (Home Assistant)
- `ad5m.nianticbooks.com` → 10.0.10.30:80 (Prusa 3D printer)
- `auth.nianticbooks.com` → 10.0.10.21:9000 (Authentik SSO - planned)

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
- `tunnel-monitor.sh` - **DEPRECATED** (monitored Gerbil tunnels, needs WireGuard replacement)
- `resource-report.sh` - Weekly utilization reports

## Critical Architecture Considerations

### Resource Allocation Strategy

**VPS (2 CPU / 4GB RAM) - Lightweight Only:**
- Caddy reverse proxy with automatic HTTPS
- WireGuard VPN server
- RustDesk relay server (hbbr) - ~30-50MB RAM for NAT traversal

**DL380p (32 CPU / 96GB RAM) - Heavy Workloads:**
- PostgreSQL (shared database for all services)
- Authentik SSO with WebAuthn/FIDO2
- n8n workflow automation
- RustDesk ID server (hbbs)
- Prometheus + Grafana monitoring

### WireGuard Tunnel Architecture ✅

**Status:** Operational - Site-to-site VPN established

- VPS acts as WireGuard server (endpoint: 66.63.182.168:51820)
- UCG Ultra acts as WireGuard client
- Tunnel subnet: 10.0.8.0/24 (VPS: 10.0.8.1, UCG: 10.0.8.2)
- Caddy routes traffic through tunnel to home lab (10.0.10.0/24)
- Configuration: `/etc/wireguard/wg0.conf` on VPS
- Persistent keepalive: 25 seconds

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
- 10.0.10.10 - HOMELAB-COMMAND (Gaming PC - RTX 5060, Wyoming voice services, Ollama LLM, Claude Code host, Windows 11)
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
- Sylvania Smart+ WiFi Plug via LocalTuya (Christmas lights)
- Digital Loggers Web Power Switch (10.0.10.88) - 8 controllable outlets via RESTful switches

**Voice Assistant:**
- Wyoming Protocol: Gaming PC (10.0.10.10) provides Whisper STT, Piper TTS, OpenWakeWord
- GPU-accelerated processing via RTX 5060

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

### Authentik SSO ✅ DEPLOYED

**Status:** Operational at 10.0.10.21:9000 (https://auth.nianticbooks.com)
**Version:** 2025.10.2
**Database:** External PostgreSQL at 10.0.10.20
**Admin User:** akadmin
**API Token:** f7AsYT6FLZEWVvmN59lC0IQZfMLdgMniVPYhVwmYAFSKHez4aGxyn4Esm86r

**Active Integrations:**
- ✅ Proxmox (all 3 hosts via OpenID Connect)
  - Client ID: `proxmox`
  - **Login: Select "authentik" from Realm dropdown, then click "Login with authentik" button**
  - Scope mappings: openid, email, profile
  - Configured on: main-pve (10.0.10.3), gaming-pve (10.0.10.2), backup-pve (10.0.10.4)

**Planned Integrations:**
- ❌ n8n (OIDC SSO requires Enterprise license - not available in free self-hosted version)
- Grafana (OAuth2)
- Home Assistant (complex - requires proxy provider or LDAP)

**Configuration via API:**
- Use Django shell for provider creation when API is difficult
- All providers need scope mappings (openid, email, profile) added manually
- Redirect URIs must be exact matches (including protocol and port)

**Documentation:**
- AUTHENTIK-SSO-GUIDE.md - Complete integration reference
- AUTHENTIK-QUICK-START.md - Step-by-step manual setup guide

### RustDesk (Self-Hosted Remote Desktop)

**Split Architecture:**
- **VPS**: Relay server (hbbr) for NAT traversal (~30-50MB RAM)
- **main-pve (DL380p)**: ID server (hbbs) at 10.0.10.23 (~2 cores, ~2GB RAM, 10GB storage)

### Other Planned Services

- **PostgreSQL**: ✅ DEPLOYED at 10.0.10.20 on main-pve (~2 cores, ~4GB RAM, 20GB storage) - PostgreSQL 16, shared by Authentik, n8n, RustDesk, Grafana
- **n8n**: ✅ DEPLOYED at 10.0.10.22:5678 on main-pve (~4 cores, ~4GB RAM, 40GB storage)
  - Docker-based deployment with PostgreSQL backend
  - **Claude Code Integration** (in progress): n8n will SSH to HOMELAB-COMMAND (10.0.10.10) to execute Claude Code commands
  - Architecture: n8n orchestrates workflows → SSH → Claude Code on Gaming PC (headless mode)
  - Use cases: Infrastructure automation, AI-powered workflows, Slack bot integration
  - Reference: https://github.com/theNetworkChuck/n8n-claude-code-guide
- **Prometheus/Grafana**: 10.0.10.25 on main-pve - centralized monitoring

### Currently Running Services

- **Home Assistant**: ✅ 10.0.10.24 - smart home automation
- **ESPHome**: Runs as HA add-on (no longer separate VM)
- **Dockge**: ✅ 10.0.10.27 - Docker compose management
- **OpenMediaVault**: ✅ 10.0.10.5 - 12TB storage management
- **Docker Host**: ✅ 10.0.10.29 - General Docker workloads
- **pve-scripts-local**: ✅ 10.0.10.40 - Proxmox automation tools

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

## ESPHome and Voice Assistant

**ESPHome Location:** `/esphome/` directory
- **garage-controller.yaml** - ESP32-WROOM-32E with 8-relay board
  - Garage door control (North/South), bay lighting (3 zones)
  - Temperature/humidity monitoring (AHT20 + BMP280)
  - Planned: Furnace control integration

**Voice Assistant Location:** `/voice-assistant/` directory
- Gaming PC (10.0.10.10) runs Wyoming services: Whisper STT, Piper TTS, OpenWakeWord
- GPU-accelerated via RTX 5060
- Ollama LLM for local language model
- Surface Go acts as Wyoming satellite (microphone/speaker)
- See `voice-assistant/QUICK_START.md` for 30-minute setup guide

## Key Constraints and Warnings

- VPS has severe resource constraints - only lightweight services
- All automation scripts require customization before deployment
- Test all scripts with `--dry-run` before production use
- `tunnel-monitor.sh` is deprecated (needs WireGuard replacement)
- HOMELAB-COMMAND requires system restart to enable SSH server for n8n integration
