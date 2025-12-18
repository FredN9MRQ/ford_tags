# Infrastructure Audit Checklist

## 1. VPS Configuration
- [x] VPS Provider: Hudson Valley Host
- [x] Public IP Address: 66.63.182.168
- [ ] Current CPU Usage: ____% (currently running Claude Code - baseline TBD)
- [ ] Current RAM Usage: _____GB / 4GB
- [ ] Current Disk Usage: _____GB / 100GB
- [x] OS Version: ubuntu-24.04-x86_64

### Pangolin Reverse Proxy
- [x] Pangolin Version: 1.10.3
- [ ] Config Location: _______________ (likely /etc/pangolin/)
- [ ] Log Location: _______________
- [x] Current Number of Routes: 5 (4 active, 1 deprecated)

### Current Pangolin Routes (NEED UPDATING - Services DOWN)
**Status:** All routes currently non-functional until WireGuard tunnel established

**Current Configuration (needs IP updates):**
```
Route 1: freddesk.nianticbooks.com -> 10.0.10.3:8006 (Proxmox Web Interface - main-pve)
Route 2: auth.nianticbooks.com -> 10.0.10.21:9000 (Authentik - PLANNED, not deployed)
Route 3: ad5m.nianticbooks.com -> 10.0.10.30:80 (Prusa 3D printer - IP to be updated)
Route 4: bob.nianticbooks.com -> 10.0.10.24:8123 (Home Assistant - IP to be updated)
Route 5: spools.nianticbooks.com -> REMOVE (Spoolman DEPRECATED)
```

**Post-Migration Routes:**
See MIGRATION-CHECKLIST.md Phase 4 for route updates to implement after IP migrations complete

## 2. WireGuard Tunnel Configuration (Replacing Gerbil)

**Status:** Currently DOWN - migration from Gerbil to UCG WireGuard in progress
**See MIGRATION-CHECKLIST.md Phase 5 for implementation steps**

### Old Gerbil Setup (Deprecated)
```
Tunnel 1: Docker container with LAN access
  - Purpose: General network access for services
  - Status: DEPRECATED - removed with UCG Ultra migration

Tunnel 2: Dedicated Home Assistant endpoint
  - Purpose: Home Assistant connectivity
  - Status: DEPRECATED - removed with UCG Ultra migration
```

### New WireGuard Tunnel (UCG Ultra <-> VPS)
- [ ] WireGuard on VPS (66.63.182.168): Not configured yet
- [ ] WireGuard on UCG Ultra: Not configured yet
- [x] WireGuard Server Port: 51820 (default)
- [ ] WireGuard Network Subnet: TBD (e.g., 10.0.8.0/24 for tunnel IPs)
- [ ] Tunnel Status: NOT ACTIVE - AWAITING CONFIGURATION

### Planned Configuration
```
VPS Side (66.63.182.168):
  - Role: WireGuard Server
  - Listen Port: 51820/UDP
  - Public Key: [to be generated during setup]
  - Private Key: [stored in /etc/wireguard/server_private.key]
  - Allowed IPs: 10.0.10.0/24 (home lab subnet)
  - IP Forwarding: Enabled

UCG Ultra Side:
  - Role: WireGuard Client
  - Endpoint: 66.63.182.168:51820
  - Public Key: [to be generated during setup]
  - Private Key: [stored in UCG configuration]
  - Allowed IPs: Routes to home lab services
  - Persistent Keepalive: 25 seconds (NAT traversal)
```

### Post-Configuration Tasks
- [ ] Update scripts/tunnel-monitor.sh for WireGuard monitoring
- [ ] Configure Pangolin to route through tunnel
- [ ] Test all public service endpoints
- [ ] Set up monitoring and alerting

## 3. Proxmox Cluster Configuration

### Main Node - main-pve / DL380p (32 cores, 96GB RAM)
- [x] Hostname: main-pve
- [x] IP Address: 10.0.10.3 (static on machine)
- [x] Role: Production workloads
- [ ] Proxmox Version: _______________
- [ ] Current CPU Usage: ____%
- [ ] Current RAM Usage: _____GB / 96GB
- [ ] Number of VMs: _____
- [ ] Number of Containers: _____
- [ ] Cluster Name: _______________
- [x] Location: Remote (not in office)
- [x] iLO Management: 10.0.10.13 (b4:b5:2f:ea:8c:30)
- [ ] Storage Pools:
  - [ ] Pool 1: _____ (_____GB total, _____GB used)
  - [ ] Pool 2: _____ (_____GB total, _____GB used)

### Secondary Node - pve-router / i5 (8 cores, 8GB RAM)
- [x] Hostname: pve-router (also called "In house Proxmox")
- [x] IP Address: 10.0.10.2 (DHCP reservation: e4:54:e8:50:90:af)
- [x] DNS: proxmox.nianticbooks.home
- [x] Role: Local development, originally planned as virtualized router
- [x] Location: Office (local access available)
- [ ] Proxmox Version: _______________
- [ ] Current CPU Usage: ____%
- [ ] Current RAM Usage: _____GB / 8GB
- [ ] Number of VMs: _____
- [ ] Number of Containers: _____
- [ ] Storage Pools:
  - [ ] Pool 1: _____ (_____GB total, _____GB used)

### Storage Node - pve-storage + OMV VM (12TB)
- [x] Proxmox Host IP: 10.0.10.4 (static on machine)
- [x] OMV VM IP: 10.0.10.5 (to be configured - currently 10.0.10.178)
- [x] OMV VM MAC: bc:24:11:a8:ff:0b
- [x] Form Factor: Supports 3.5" drives (unique among Proxmox nodes)
- [x] Total Storage: 12TB
- [ ] OMV Version: _______________
- [ ] Used Storage: _____TB
- [ ] Available Storage: _____TB
- [ ] Shared via: NFS/CIFS/iSCSI
- [ ] Share Paths:
  - [ ] Share 1: _______________
  - [ ] Share 2: _______________

## 4. Network Configuration

### Home Lab Network
- [x] Network Subnet: 10.0.10.0/24
- [x] Gateway: 10.0.10.1 (UCG Ultra)
- [ ] DNS Servers: _______________, _______________
- [x] DHCP Range: 10.0.10.50-10.0.10.254 (to be configured)
- [x] VLAN Configuration (if any): Single VLAN (VLAN 1) - hardware not capable of multiple VLANs

### IP Address Allocation

**See IP-ALLOCATION.md for complete details**

**Infrastructure (10.0.10.1-9):**
- 10.0.10.1 - UCG Ultra (gateway)
- 10.0.10.2 - pve-router (i5 Proxmox node)
- 10.0.10.3 - main-pve (DL380p Proxmox - production)
- 10.0.10.4 - pve-storage (Proxmox host for OMV)
- 10.0.10.5 - openmediavault (12TB storage VM)

**Management (10.0.10.10-19):**
- 10.0.10.10 - HOMELAB-COMMAND (Dad's PC)
- 10.0.10.13 - HP iLO (DL380p management)

**Production Services (10.0.10.20-29):**
- 10.0.10.20 - PostgreSQL (shared database)
- 10.0.10.21 - Authentik SSO
- 10.0.10.22 - n8n workflow automation
- 10.0.10.23 - RustDesk ID server (hbbs)
- 10.0.10.24 - Home Assistant
- 10.0.10.25 - Prometheus + Grafana
- 10.0.10.27 - Dockge
- 10.0.10.28 - ESPHome
- 10.0.10.29 - Docker host

**IoT & 3D Printing (10.0.10.30-39):**
- 10.0.10.30 - ad5m (Prusa 3D printer)
- 10.0.10.31 - Bambu A1 (reserved)

**Utility (10.0.10.40-49):**
- 10.0.10.40 - pve-scripts-local

**Available for future services:**
- 10.0.10.6-9 (infrastructure expansion)
- 10.0.10.11-12, 10.0.10.14-19 (management)
- 10.0.10.26 (production services)
- 10.0.10.32-39 (IoT)
- 10.0.10.41-49 (utility)

### Port Forwarding (VPS → Home Lab via WireGuard)
**Current Status:** WireGuard tunnel not yet configured - all services DOWN

Once WireGuard established:
- Port 51820/UDP on VPS → UCG Ultra (WireGuard tunnel)
- All HTTP/HTTPS traffic routed through tunnel to home lab services via Pangolin

## 5. DNS Configuration

### Current DNS Provider
- [ ] Provider: _______________
- [ ] API Access: Yes/No
- [ ] API Key Location: _______________

### Current DNS Records
```
A Records:
- _______________ -> _______________
- _______________ -> _______________

CNAME Records:
- _______________ -> _______________
- _______________ -> _______________

TXT Records (for validation):
- _______________
```

### DNS Records Needed for New Services
```
Planned A Records:
- _______________ -> VPS_IP
- _______________ -> VPS_IP

Planned CNAME Records:
- _______________ -> _______________
```

## 6. SSL/TLS Certificate Strategy

### Current Certificate Management
- [ ] Certificate Authority: Let's Encrypt/Other: _______________
- [ ] Certificate Manager: Certbot/ACME/Manual
- [ ] Wildcard Certificates: Yes/No
- [ ] Certificate Storage Location: _______________
- [ ] Auto-renewal Configured: Yes/No

### Current Certificates
```
Certificate 1:
  - Domain(s): _______________
  - Issuer: _______________
  - Expiry Date: _______________
  - Renewal Method: _______________

Certificate 2:
  - Domain(s): _______________
  - Issuer: _______________
  - Expiry Date: _______________
  - Renewal Method: _______________
```

### SSL Strategy for New Services
- [ ] Use existing wildcard: Yes/No
- [ ] Generate new certificates: Yes/No
- [ ] Certificate validation method: HTTP-01/DNS-01/TLS-ALPN-01
- [ ] Who manages certificates: Pangolin/Individual services

## 7. Running Services Inventory

### VPS Services
```
Service 1: _______________
  - Port(s): _____
  - Resource Usage: CPU: ___%, RAM: _____MB
  - Purpose: _______________

[Add more as needed]
```

### Proxmox Services/VMs/Containers
```
VM/CT 1: _______________
  - Node: DL380p/i5
  - IP Address: _______________
  - Purpose: _______________
  - Resources: _____ cores, _____GB RAM
  - Exposed Services: _____
  - Publicly Accessible: Yes/No

[Add more as needed]
```

## 8. Security Configuration

### Firewall Rules (VPS)
- [ ] Firewall Software: iptables/ufw/firewalld/other: _______________
- [ ] Default Policy: _____
- [ ] Open Ports:
  - [ ] Port _____: _____
  - [ ] Port _____: _____
  - [ ] Port _____: _____

### Firewall Rules (Proxmox)
- [ ] Proxmox Firewall Enabled: Yes/No
- [ ] Datacenter Level Rules: _____
- [ ] Node Level Rules: _____

### Authentication
- [ ] SSH Key-based Auth: Yes/No
- [ ] Password Auth Disabled: Yes/No
- [ ] 2FA Enabled: Yes/No (Where: _______________)
- [ ] Fail2ban/Similar Installed: Yes/No

## 9. Backup Strategy
- [ ] VPS Backups: Method: _______________, Frequency: _______________
- [ ] Proxmox Backups: Method: _______________, Frequency: _______________
- [ ] Backup Location: _______________
- [ ] Last Backup Tested: _______________

## 10. Monitoring & Logging
- [ ] Monitoring Solution: _______________
- [ ] Log Aggregation: _______________
- [ ] Alerting Configured: Yes/No
- [ ] Uptime Monitoring: _______________

## 11. Resource Availability Summary

### DL380p Available Resources
- [ ] Available CPU Cores: _____ / 32
- [ ] Available RAM: _____GB / 96GB
- [ ] Available Storage: _____GB

### i5 Available Resources
- [ ] Available CPU Cores: _____ / 8
- [ ] Available RAM: _____GB / 8GB
- [ ] Available Storage: _____GB

### Recommendations for New Service Placement
- [ ] Best node for new service: _______________
- [ ] Estimated resources needed: _____ cores, _____GB RAM, _____GB storage

## Notes & Observations
```
[Add any additional notes, concerns, or observations about your current infrastructure]




```

---
**Date Completed:** _______________
**Completed By:** _______________
