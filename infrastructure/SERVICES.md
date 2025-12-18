# Services Documentation

This document provides detailed information about all services running in your infrastructure. Fill this out based on your completed infrastructure audit.

## Table of Contents
- [Service Overview](#service-overview)
- [VPS Services](#vps-services)
- [Home Lab Services](#home-lab-services)
- [Service Dependencies](#service-dependencies)
- [Configuration Files](#configuration-files)
- [Monitoring & Health Checks](#monitoring--health-checks)

---

## Service Overview

### Service Inventory Summary

| Service Name | Location | Type | Status | Critical |
|--------------|----------|------|--------|----------|
| ____________ | VPS | ______ | ______ | Yes/No |
| ____________ | Home Lab | ______ | ______ | Yes/No |
| ____________ | Home Lab | ______ | ______ | Yes/No |

---

## VPS Services

### Pangolin Reverse Proxy

**Purpose**: Routes incoming HTTPS traffic to appropriate backend services via Gerbil tunnels

**Service Details**:
- **Host**: VPS (IP: _____________)
- **Service Name**: `pangolin` or `pangolin.service`
- **Port(s)**: 80 (HTTP), 443 (HTTPS)
- **Configuration**: `/etc/pangolin/config.yml` (or similar)
- **Logs**: `/var/log/pangolin/` or `journalctl -u pangolin`
- **User/Group**: `pangolin` / `pangolin`

**Configuration**:
```yaml
# Example Pangolin configuration structure
routes:
  - domain: service1.example.com
    backend: localhost:8001
    ssl: true

  - domain: service2.example.com
    backend: localhost:8002
    ssl: true
```

**Startup**:
```bash
sudo systemctl start pangolin
sudo systemctl enable pangolin
```

**Health Check**:
```bash
curl -I https://service.example.com
sudo systemctl status pangolin
```

**Dependencies**:
- SSL certificates (Let's Encrypt)
- Gerbil tunnel endpoints
- DNS resolution

**Restart Required When**:
- Configuration changes
- Certificate updates
- After system updates

---

### Gerbil Server

**Purpose**: Accepts tunnel connections from home lab, forwards traffic to tunneled services

**Service Details**:
- **Host**: VPS (IP: _____________)
- **Service Name**: `gerbil-server` or `gerbil.service`
- **Port(s)**: _____________ (tunnel port)
- **Configuration**: `/etc/gerbil/server.conf`
- **Logs**: `/var/log/gerbil/` or `journalctl -u gerbil-server`
- **User/Group**: `gerbil` / `gerbil`

**Configuration**:
```yaml
# Example Gerbil server configuration
listen: 0.0.0.0:TUNNEL_PORT
auth:
  method: key
  key_file: /etc/gerbil/auth.key

tunnels:
  - name: tunnel-1
    local_port: 8001
  - name: tunnel-2
    local_port: 8002
```

**Startup**:
```bash
sudo systemctl start gerbil-server
sudo systemctl enable gerbil-server
```

**Health Check**:
```bash
ss -tlnp | grep TUNNEL_PORT
sudo systemctl status gerbil-server
```

**Dependencies**:
- Network connectivity
- Authentication keys
- Firewall rules allowing tunnel port

---

### [Additional VPS Services]

**Service Name**: _____________

**Purpose**: _____________

**Service Details**:
- **Host**: VPS
- **Service Name**: _____________
- **Port(s)**: _____________
- **Configuration**: _____________
- **Logs**: _____________

**Startup/Health Check/Dependencies**: [Document as above]

---

## Home Lab Services

### Proxmox Cluster Management

**Purpose**: Virtualization platform hosting all home lab VMs and containers

**Service Details**:
- **Nodes**:
  - DL380p: _____________ (32 cores, 96GB RAM)
  - i5: _____________ (8 cores, 8GB RAM)
- **Web Interface**: https://NODE_IP:8006
- **Configuration**: `/etc/pve/`
- **Logs**: `journalctl -u pveproxy`, `/var/log/pve/`

**Critical Files**:
- `/etc/pve/storage.cfg` - Storage configuration
- `/etc/pve/datacenter.cfg` - Datacenter settings
- `/etc/pve/nodes/` - Node-specific configs

**Health Check**:
```bash
pvecm status    # Cluster status
pvesh get /cluster/resources    # Resource overview
```

**Backup Strategy**:
- Daily VM/container backups to OMV storage
- Configuration backup weekly

---

### OMV Storage Node

**Purpose**: Centralized storage for backups, shared data, and Proxmox storage

**Service Details**:
- **Host**: OMV (IP: _____________)
- **Capacity**: 12TB
- **Web Interface**: http://OMV_IP
- **Shares**:
  - Share 1: _____________ (NFS/CIFS) - Purpose: _____________
  - Share 2: _____________ (NFS/CIFS) - Purpose: _____________

**Mount Points** (on Proxmox nodes):
```bash
# /etc/fstab entries
OMV_IP:/export/proxmox-backup /mnt/backup nfs defaults 0 0
```

**Health Check**:
```bash
df -h /mnt/backup
showmount -e OMV_IP
```

---

### Gerbil Tunnels (Home Lab Side)

**Purpose**: Create secure tunnels from home lab services to VPS

**Active Tunnels**:

#### Tunnel 1: _____________
- **Service Name**: `gerbil-tunnel-1`
- **Local Endpoint**: localhost:_____________ (on host: _____________)
- **Remote Endpoint**: VPS:_____________
- **Purpose**: _____________
- **Configuration**: `/etc/gerbil/tunnel-1.conf`
- **Logs**: `journalctl -u gerbil-tunnel-1`

**Startup**:
```bash
sudo systemctl start gerbil-tunnel-1
sudo systemctl enable gerbil-tunnel-1
```

**Health Check**:
```bash
gerbil status tunnel-1
ss -tn | grep REMOTE_PORT
curl http://localhost:LOCAL_PORT    # Test local service
```

#### Tunnel 2: _____________
[Document additional tunnels similarly]

---

### VM/Container Services

#### VM/CT 1: _____________

**Purpose**: _____________

**Details**:
- **VMID/CTID**: _____________
- **Node**: DL380p / i5
- **IP Address**: _____________
- **OS**: _____________
- **Resources**: _____ cores, _____ GB RAM, _____ GB disk
- **Status**: Running / Stopped

**Running Services**:
- Service 1: _____________ (Port: _____)
- Service 2: _____________ (Port: _____)

**Dependencies**:
- Network connectivity
- OMV storage (if applicable)
- Other VMs/services: _____________

**Backup Schedule**: _____________

**Access**:
```bash
# From Proxmox node
pct enter CTID    # For containers
# OR
ssh user@VM_IP    # For VMs
```

**Health Checks**:
```bash
# On Proxmox
qm status VMID    # For VMs
pct status CTID   # For containers

# Inside VM/CT
sudo systemctl status service-name
curl http://localhost:PORT
```

**Notes**: _____________

---

#### VM/CT 2: _____________
[Document additional VMs/containers similarly]

---

## Service Dependencies

### Dependency Map

```
Internet
  └─> VPS
       ├─> Pangolin (reverse proxy)
       │    └─> Routes to Gerbil tunnel endpoints
       │
       └─> Gerbil Server
            └─> Accepts tunnels from home lab
                 │
                 ├─> Tunnel 1 -> VM/CT Service A
                 ├─> Tunnel 2 -> VM/CT Service B
                 └─> Tunnel 3 -> VM/CT Service C

Home Lab Network
  ├─> Proxmox Cluster
  │    ├─> DL380p (Primary node)
  │    │    ├─> VM 1 (Service A)
  │    │    └─> CT 1 (Service B)
  │    │
  │    └─> i5 (Secondary node)
  │         └─> VM 2 (Service C)
  │
  └─> OMV Storage
       └─> Provides storage to Proxmox nodes
```

### Critical Service Dependencies

| Service | Depends On | Impact if Dependency Fails |
|---------|------------|----------------------------|
| Pangolin | Gerbil tunnels, SSL certs, DNS | All public services unavailable |
| Gerbil Server | Network, auth keys | Tunnels disconnect, services unavailable |
| Gerbil Tunnels | VPS connectivity, local services | Specific service becomes unavailable |
| VM Services | Proxmox node, network, storage | Service unavailable |
| Proxmox | Network, storage (OMV) | All VMs on node unavailable |

---

## Configuration Files

### Important Configuration Locations

#### VPS
```
/etc/pangolin/
├── config.yml                 # Main Pangolin configuration
└── routes.d/                  # Individual route configs

/etc/gerbil/
├── server.conf                # Gerbil server configuration
└── auth.key                   # Authentication key

/etc/letsencrypt/
├── live/
│   └── domain.com/
│       ├── fullchain.pem      # SSL certificate
│       └── privkey.pem        # Private key
└── renewal/                   # Auto-renewal configs

/etc/nginx/ or /etc/apache2/   # If used alongside Pangolin
```

#### Home Lab
```
/etc/pve/                      # Proxmox configuration (node-specific)
├── storage.cfg
├── datacenter.cfg
└── nodes/
    ├── dl380p/
    └── i5/

/etc/gerbil/                   # On each machine with tunnels
├── tunnel-1.conf
└── tunnel-2.conf

/etc/network/interfaces        # Network configuration
/etc/hosts                     # Local DNS overrides
```

### Configuration Backup Script
```bash
#!/bin/bash
# Backup critical configurations

BACKUP_DIR="/mnt/backup/configs/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# VPS configurations (run on VPS)
tar -czf "$BACKUP_DIR/vps-config.tar.gz" \
  /etc/pangolin \
  /etc/gerbil \
  /etc/letsencrypt

# Home lab configurations (run on Proxmox node)
tar -czf "$BACKUP_DIR/proxmox-config.tar.gz" \
  /etc/pve \
  /etc/network \
  /etc/gerbil

# Keep last 30 days
find /mnt/backup/configs/ -type d -mtime +30 -exec rm -rf {} +
```

---

## Monitoring & Health Checks

### Service Health Check Matrix

| Service | Check Method | Expected Response | Alert Threshold |
|---------|--------------|-------------------|-----------------|
| Pangolin | `curl -I https://service.example.com` | HTTP 200 | > 30s response or error |
| Gerbil Server | `ss -tlnp \| grep PORT` | Listening on port | Process not running |
| Gerbil Tunnel | `gerbil status` | Connected | Disconnected > 5min |
| VPS SSH | `ssh user@vps` | Connected | Connection refused |
| Proxmox Web UI | `curl -k https://NODE:8006` | HTTP 200 | Unreachable |
| VM/CT | `qm/pct status ID` | Running | Stopped/paused |
| OMV Storage | `df -h /mnt/backup` | Mounted, space available | Not mounted or >90% full |

### Automated Health Check Script

```bash
#!/bin/bash
# health-check.sh - Run on monitoring host

# Check VPS services
ssh user@vps 'systemctl is-active pangolin gerbil-server' || echo "VPS service down"

# Check Gerbil tunnels
for tunnel in tunnel-1 tunnel-2; do
  gerbil status $tunnel | grep -q "Connected" || echo "$tunnel disconnected"
done

# Check Proxmox VMs/CTs
for id in VMID1 VMID2 CTID1; do
  status=$(qm status $id 2>/dev/null || pct status $id 2>/dev/null)
  echo "$status" | grep -q "running" || echo "VM/CT $id not running"
done

# Check storage
df -h /mnt/backup | tail -1 | awk '{if ($5+0 > 90) print "Storage critically low: " $5}'
```

### Monitoring Recommendations

See [MONITORING.md](MONITORING.md) for detailed monitoring setup instructions.

**Suggested Monitoring Stack**:
- **Uptime Monitoring**: Uptime Kuma, Healthchecks.io
- **Infrastructure Monitoring**: Prometheus + Grafana
- **Log Aggregation**: Loki, ELK stack
- **Alerting**: Alertmanager, email/SMS/Slack

---

## Service Update Procedures

### When to Restart Services

| Service | Restart Required For |
|---------|---------------------|
| Pangolin | Config changes, SSL cert updates, software updates |
| Gerbil Server | Config changes, software updates |
| Gerbil Tunnels | Config changes, connection issues |
| Proxmox | Kernel updates (requires reboot) |
| VMs/CTs | Per-service requirements |

### Safe Restart Order

When restarting multiple services:

1. **Prepare**: Notify users of planned maintenance
2. **Check backups**: Ensure recent backups exist
3. **Start with least critical**: Update/restart non-critical services first
4. **Restart order**:
   - Local services in VMs/CTs
   - Gerbil tunnels (home lab side)
   - Gerbil server (VPS)
   - Pangolin (VPS)
5. **Verify**: Test each service after restart
6. **Monitor**: Watch logs for errors

---

## Notes & TODO

- [ ] Complete all service details with actual values
- [ ] Document any custom scripts or automation
- [ ] Add any service-specific quirks or known issues
- [ ] Update this document when services are added/removed
- [ ] Review and update quarterly

**Last Updated**: _____________
**Updated By**: _____________
**Version**: 1.0
