# Network IP Allocation Plan

**Date:** 2025-11-14
**Status:** Approved - Ready for Implementation
**Network:** 10.0.10.0/24
**Gateway:** 10.0.10.1 (UCG Ultra)

---

## IP Range Allocation

| Range | Purpose | Count | Method |
|-------|---------|-------|--------|
| 10.0.10.1 | Gateway (UCG Ultra) | 1 | Static |
| 10.0.10.2-29 | **Infrastructure & Servers** | 28 | Static/Reserved |
| 10.0.10.30-39 | **IoT & 3D Printing** | 10 | Reserved |
| 10.0.10.40-49 | **Utility Services & Future** | 10 | Reserved |
| 10.0.10.50-254 | **DHCP Pool** | 205 | Dynamic |

---

## Detailed IP Assignments

### Core Infrastructure (10.0.10.1-9)

| IP | Hostname | Device/Service | MAC Address | Status | Notes |
|----|----------|----------------|-------------|--------|-------|
| 10.0.10.1 | ucg-ultra | UCG Ultra Gateway | - | ✅ Active | Static on device |
| 10.0.10.2 | pve-router | i5 Proxmox Node | e4:54:e8:50:90:af | ✅ Reserved | DNS: proxmox.nianticbooks.home |
| 10.0.10.3 | main-pve | DL380p Proxmox (Production) | - | ✅ Active | Static on device, 32c/96GB RAM |
| 10.0.10.4 | pve-storage | Proxmox Host for OMV | - | ✅ Active | Static on device, 3.5" drive support |
| 10.0.10.5 | openmediavault | OMV VM (12TB storage) | bc:24:11:a8:ff:0b | 🔄 To Reserve | Currently at .178 |
| 10.0.10.6 | - | AVAILABLE | - | - | - |
| 10.0.10.7 | - | AVAILABLE | - | - | - |
| 10.0.10.8 | - | AVAILABLE | - | - | - |
| 10.0.10.9 | - | AVAILABLE | - | - | - |

### Management & Remote Access (10.0.10.10-19)

| IP | Hostname | Device/Service | MAC Address | Status | Notes |
|----|----------|----------------|-------------|--------|-------|
| 10.0.10.10 | homelab-command | Gaming PC (Voice Assistant Hub) | 90:de:80:80:e7:04 | ✅ Active | Wyoming services, Ollama LLM |
| 10.0.10.11 | - | AVAILABLE (VPN endpoint) | - | - | Reserved for future WireGuard client |
| 10.0.10.12 | - | AVAILABLE | - | - | - |
| 10.0.10.13 | ilo | HP iLO (DL380p) | b4:b5:2f:ea:8c:30 | 🔄 To Update | Currently at .53 |
| 10.0.10.14 | - | AVAILABLE | - | - | - |
| 10.0.10.15 | - | AVAILABLE | - | - | - |
| 10.0.10.16 | - | AVAILABLE | - | - | - |
| 10.0.10.17 | - | AVAILABLE | - | - | - |
| 10.0.10.18 | - | AVAILABLE | - | - | - |
| 10.0.10.19 | - | AVAILABLE | - | - | - |

### Production Services (10.0.10.20-29)

| IP | Hostname | Service | MAC Address | Status | Notes |
|----|----------|---------|-------------|--------|-------|
| 10.0.10.20 | postgresql | PostgreSQL (Shared DB) | - | 📋 Planned | For Authentik, n8n, RustDesk, Grafana |
| 10.0.10.21 | authentik | Authentik SSO | - | 📋 Planned | WebAuthn/FIDO2, OAuth2/OIDC |
| 10.0.10.22 | n8n | n8n Workflow Automation | - | 📋 Planned | 4c/4GB RAM |
| 10.0.10.23 | rustdesk | RustDesk ID Server (hbbs) | - | 📋 Planned | 2c/2GB RAM |
| 10.0.10.24 | homeassistant | Home Assistant | 02:f5:e9:54:36:28 | ✅ Active | Static reservation configured |
| 10.0.10.25 | monitoring | Prometheus + Grafana | - | 📋 Planned | Centralized monitoring |
| 10.0.10.26 | - | AVAILABLE | - | - | (was authelia - removed) |
| 10.0.10.27 | dockge | Dockge | bc:24:11:4a:42:07 | 🔄 To Reserve | Currently at .104 |
| 10.0.10.28 | ~~esphome~~ | ~~ESPHome~~ | ~~bc:24:11:8f:eb:eb~~ | ✅ Available | ESPHome runs as HA add-on (no VM) |
| 10.0.10.29 | docker | Docker Host | bc:24:11:a8:ff:0b | 🔄 To Reserve | Currently at .108 |

### IoT & 3D Printing (10.0.10.30-39)

| IP | Hostname | Device | MAC Address | Status | Notes |
|----|----------|--------|-------------|--------|-------|
| 10.0.10.30 | ad5m | Prusa AD5M 3D Printer | 88:a9:a7:99:c3:64 | 🔄 To Update | Currently at .189, DNS: AD5M.nianticbooks.home |
| 10.0.10.31 | bambu-a1 | Bambu Lab A1 | cc:ba:97:21:4c:f8 | - | Reserved if network features become available |
| 10.0.10.32 | - | AVAILABLE | - | - | - |
| 10.0.10.33 | - | AVAILABLE | - | - | - |
| 10.0.10.34 | - | AVAILABLE | - | - | - |
| 10.0.10.35 | - | AVAILABLE | - | - | - |
| 10.0.10.36 | - | AVAILABLE | - | - | - |
| 10.0.10.37 | - | AVAILABLE | - | - | - |
| 10.0.10.38 | - | AVAILABLE | - | - | - |
| 10.0.10.39 | - | AVAILABLE | - | - | - |

### Utility Services (10.0.10.40-49)

| IP | Hostname | Service | MAC Address | Status | Notes |
|----|----------|---------|-------------|--------|-------|
| 10.0.10.40 | pve-scripts-local | PVE Scripts Local | bc:24:11:0f:78:84 | 🔄 To Reserve | Currently at .79 |
| 10.0.10.41 | - | AVAILABLE | - | - | - |
| 10.0.10.42 | - | AVAILABLE | - | - | - |
| 10.0.10.43 | - | AVAILABLE | - | - | - |
| 10.0.10.44 | - | AVAILABLE | - | - | - |
| 10.0.10.45 | - | AVAILABLE | - | - | - |
| 10.0.10.46 | - | AVAILABLE | - | - | - |
| 10.0.10.47 | - | AVAILABLE | - | - | - |
| 10.0.10.48 | - | AVAILABLE | - | - | - |
| 10.0.10.49 | - | AVAILABLE | - | - | - |

### DHCP Pool (10.0.10.50-254)
Dynamic assignments for:
- Workstations (Fred-M6800, Freds-iMac, Kevin-PC, etc.)
- Mobile devices (iPhones, iPads, Watches)
- IoT devices (Ecobee, Blink cameras, ESP devices, etc.)
- Guest devices
- Temporary connections

**Current DHCP Range:** 10.0.10.50-10.0.10.254 (need to update on UCG Ultra)

---

## Deprecated/To Remove

| IP | Hostname | Reason | Action |
|----|----------|--------|--------|
| 10.0.10.71 | spoolman | No longer used (Bambu printer incompatible) | Remove VM, reclaim IP |
| 10.0.10.112 | authelia | Failed experiment | Remove VM, reclaim IP |

---

## MAC Address Quick Reference

**Proxmox VMs/Containers:** All use `bc:24:11:xx:xx:xx` pattern
**Physical Proxmox Nodes:** `e4:54:e8:50:90:af` (pve-router)

---

## Status Legend

| Icon | Status | Meaning |
|------|--------|---------|
| ✅ | Active | Already configured and working |
| 🔄 | To Reserve/Update | Needs DHCP reservation or IP change |
| 📋 | Planned | New service, not yet deployed |
| - | Available | Reserved but unused |

---

## Implementation Phases

### Phase 1: UCG Ultra DHCP Configuration ✅ COMPLETED
- [x] DHCP range verified: 10.0.10.50-254 ✅

### Phase 2: Update Existing Reservations ✅ COMPLETED
- [x] homelab-command: .92 → .10 ✅
- [x] HP iLO: .53 → .13 ✅
- [x] ad5m: .189 → .30 ✅

### Phase 3: Create New Reservations for VMs ✅ COMPLETED
- [x] openmediavault: .178 → .5 ✅
- [x] homeassistant: .194 → .24 ✅
- [x] dockge: .104 → .27 ✅
- [x] ~~esphome: .113 → .28~~ (Removed - now HA add-on)
- [x] docker: .108 → .29 ✅
- [x] pve-scripts-local: .79 → .40 ✅

### Phase 4: Deploy New Services 📋
- [ ] PostgreSQL at .20
- [ ] Authentik at .21
- [ ] n8n at .22
- [ ] RustDesk at .23
- [ ] Prometheus/Grafana at .25

### Phase 5: Cleanup 🧹
- [ ] Remove spoolman VM (.71)
- [ ] Remove authelia VM (.112)

### Phase 6: Update Documentation ✍️
- [ ] Update Pangolin routes with new IPs
- [ ] Update CLAUDE.md
- [ ] Update SERVICES.md
- [ ] Update infrastructure-audit.md
