# Twingate Resources Setup Guide

**Secure remote access to homelab infrastructure**

---

## Overview

This guide configures Twingate resources for secure zero-trust access to your homelab from anywhere.

**Benefits:**
- No VPN complexity
- Per-resource access control
- Automatic certificate handling
- Works from any device with Twingate client

---

## Prerequisites

- ✅ Twingate LXC connector deployed and connected
- ✅ Twingate account with admin access
- ✅ Twingate client installed on devices you want to access from

---

## Resource Configuration

### Priority 1: Management & Monitoring

#### 1. Proxmox - Main (DL380p)

**Purpose:** Primary Proxmox host management (32 cores, 96GB RAM)

**Settings:**
- **Name:** `Proxmox - Main (DL380p)`
- **Address:** `10.0.10.3`
- **Protocols:** HTTPS (443) or Custom Port (8006)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:**
  - User: fred@nianticbooks.com
  - Groups: Homelab Admins (if you create one)

**Usage:**
```
https://10.0.10.3:8006
Login: fred@authentik (via Authentik SSO)
```

---

#### 2. Proxmox - Router (i5)

**Purpose:** Secondary Proxmox host at office location

**Settings:**
- **Name:** `Proxmox - Router (i5)`
- **Address:** `10.0.10.2`
- **Protocols:** HTTPS (443) or Custom Port (8006)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** Same as above

**Usage:**
```
https://10.0.10.2:8006
Login: fred@authentik (via Authentik SSO)
```

---

#### 3. Proxmox - Storage

**Purpose:** Storage-focused Proxmox host (OMV VM host)

**Settings:**
- **Name:** `Proxmox - Storage`
- **Address:** `10.0.10.4`
- **Protocols:** HTTPS (443) or Custom Port (8006)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** Same as above

**Usage:**
```
https://10.0.10.4:8006
Login: fred@authentik (via Authentik SSO)
```

---

#### 4. Grafana Dashboards

**Purpose:** Infrastructure monitoring and metrics visualization

**Settings:**
- **Name:** `Grafana Monitoring`
- **Address:** `10.0.10.25`
- **Protocols:** HTTP (80) or Custom Port (3000)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** fred@nianticbooks.com

**Usage:**
```
http://10.0.10.25:3000
Login: fred@nianticbooks.com (via Authentik OAuth)
```

**Tip:** Once working via Twingate, you can remove the Caddy public route

---

#### 5. Authentik SSO Admin

**Purpose:** User authentication and SSO management

**Settings:**
- **Name:** `Authentik SSO`
- **Address:** `10.0.10.21`
- **Protocols:** HTTP (80) or Custom Port (9000)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** fred@nianticbooks.com (admin only)

**Usage:**
```
http://10.0.10.21:9000
Login: akadmin / [admin password]
```

---

### Priority 2: Home Automation & Apps

#### 6. Home Assistant

**Purpose:** Smart home control and automation

**Settings:**
- **Name:** `Home Assistant`
- **Address:** `10.0.10.24`
- **Protocols:** HTTP (80) or Custom Port (8123)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** fred@nianticbooks.com

**Usage:**
```
http://10.0.10.24:8123
Login: Home Assistant account
```

**Tip:** Can replace bob.nianticbooks.com Caddy route

---

#### 7. n8n Workflow Automation

**Purpose:** Automation workflows and integrations

**Settings:**
- **Name:** `n8n Workflows`
- **Address:** `10.0.10.22`
- **Protocols:** HTTP (80) or Custom Port (5678)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** fred@nianticbooks.com

**Usage:**
```
http://10.0.10.22:5678
Login: n8n account (no SSO available in free version)
```

---

### Priority 3: Storage & Infrastructure

#### 8. OpenMediaVault (OMV)

**Purpose:** 12TB storage management and backup monitoring

**Settings:**
- **Name:** `OMV Storage`
- **Address:** `10.0.10.5`
- **Protocols:** HTTP (80)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** fred@nianticbooks.com

**Usage:**
```
http://10.0.10.5
Login: admin / homelab2025
```

---

#### 9. Dockge - Docker Management

**Purpose:** Docker Compose stack management

**Settings:**
- **Name:** `Dockge`
- **Address:** `10.0.10.27`
- **Protocols:** HTTP (80) or Custom Port (5001)
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** fred@nianticbooks.com

**Usage:**
```
http://10.0.10.27:5001
Login: Dockge account
```

---

### Optional: SSH Access

#### 10. SSH to Proxmox Hosts

**Purpose:** Direct SSH terminal access

**Settings:**
- **Name:** `SSH - Proxmox Hosts`
- **Address:** `10.0.10.2,10.0.10.3,10.0.10.4` (comma-separated)
- **Protocols:** TCP Port 22
- **Connector:** Your Twingate LXC connector
- **Security Policy:** Require device authentication
- **Access:** fred@nianticbooks.com

**Usage:**
```bash
ssh root@10.0.10.3
# SSH key already configured
```

---

## Step-by-Step Resource Creation

### Via Twingate Admin Console

1. **Login to Twingate:**
   - Go to your Twingate admin console
   - Navigate to **Resources**

2. **Add Resource:**
   - Click **Add Resource**
   - Fill in settings from sections above

3. **Configure Access:**
   - **Who can access:** Select users/groups
   - **From where:** Select connector(s)
   - **Security policies:** Enable device authentication

4. **Save and Test:**
   - Save the resource
   - Install Twingate client on your device
   - Test access to the URL

---

## Security Best Practices

### 1. Device Authentication
- ✅ Enable "Require device authentication" for all resources
- ✅ Only allow registered devices

### 2. Access Groups
Create a "Homelab Admins" group in Twingate:
- Add fred@nianticbooks.com
- Assign group to all resources
- Easier to manage access for multiple users later

### 3. Connector Redundancy
- Deploy Twingate connector on multiple hosts
- If one LXC fails, others maintain access
- Recommended: Add connector to main-pve and pve-router

### 4. Resource Grouping
Use Twingate resource tags:
- `homelab`
- `proxmox`
- `monitoring`
- `automation`

Helps organize and find resources quickly.

---

## Testing Checklist

After creating resources, test each:

**From Windows (HOMELAB-COMMAND):**
```powershell
# Install Twingate client if not already installed
# Login to Twingate
# Test each resource:

# Proxmox
Start-Process "https://10.0.10.3:8006"

# Grafana
Start-Process "http://10.0.10.25:3000"

# Home Assistant
Start-Process "http://10.0.10.24:8123"

# SSH test
ssh root@10.0.10.3 "hostname"
```

**From Mobile/Remote:**
1. Install Twingate app
2. Login with your account
3. Enable Twingate connection
4. Access resources via IP addresses

---

## Twingate vs Caddy Routes - Complementary Access

Twingate provides **redundant/alternative** access to your homelab. Keep both methods for reliability:

### Caddy Routes (Keep All - Primary Public Access)
**Purpose:** Public access via WireGuard tunnel + Authentik SSO

- ✅ `freddesk.nianticbooks.com` → Proxmox main-pve (10.0.10.3:8006)
- ✅ `bob.nianticbooks.com` → Home Assistant (10.0.10.24:8123)
- ✅ `auth.nianticbooks.com` → Authentik SSO (required for OAuth)
- ✅ `ad5m.nianticbooks.com` → 3D Printer (10.0.10.30:80)

### Twingate Resources (New - Redundant Private Access)
**Purpose:** Direct zero-trust access (backup if WireGuard fails)

- All resources listed in this guide

### Use Cases for Each

**Use Caddy routes when:**
- Accessing from public/untrusted networks
- Want SSO authentication via Authentik
- Need to share access with others (they just need the URL)
- Prefer browser-based access

**Use Twingate when:**
- Need guaranteed access (redundancy)
- WireGuard tunnel is down
- Want per-resource access control
- Accessing from mobile devices with Twingate app
- Need direct network access (lower latency)

### Redundancy Benefits

If one method fails, you have the other:
- **WireGuard tunnel down?** → Use Twingate
- **Twingate connector down?** → Use Caddy routes
- **VPS issues?** → Use Twingate
- **Network path blocked?** → Try alternative method

---

## Troubleshooting

### Resource not accessible

**1. Check Connector Status:**
```bash
# On Twingate LXC
docker ps
docker logs <connector-container>
```

**2. Check Network Connectivity:**
```bash
# From connector, can it reach resource?
ping 10.0.10.3
curl -k https://10.0.10.3:8006
```

**3. Check Twingate Client:**
- Is Twingate connected (green icon)?
- Are you logged in with correct account?
- Is device registered?

**4. Check Firewall:**
```bash
# On Proxmox hosts, check if ports are open
ss -tlnp | grep 8006
```

### Slow performance

- Check connector resource usage
- Consider adding more connectors
- Use wired connection for connector LXC

### Can't login to services

- Authentik must be accessible for SSO
- Check Authentik redirect URIs include Twingate IPs
- Some services may need Authentik configuration updates

---

## Advanced: Multiple Connectors

For high availability, deploy connectors on multiple hosts:

**Recommended deployment:**
1. Twingate LXC on pve-router (existing)
2. Twingate LXC on main-pve (new)
3. Configure resources to use both connectors

**Benefits:**
- If one host goes down, still have access
- Load balancing across connectors
- Maintenance without downtime

---

## Next Steps

1. ✅ Create Priority 1 resources (Proxmox, Grafana, Authentik)
2. ✅ Test access from remote device
3. ✅ Create Priority 2 resources (Home Assistant, n8n)
4. ✅ Create Priority 3 resources (OMV, Dockge)
5. ✅ Remove redundant Caddy public routes
6. ✅ Document access procedures for mobile devices
7. ✅ Consider deploying second connector for redundancy

---

## Summary

**Total Resources to Create:** 9-10

**Estimated Setup Time:** 30-45 minutes

**Security Level:** High (zero-trust, device authentication)

**Maintenance:** Low (automatic connector updates)

---

**Last Updated:** 2025-12-26
