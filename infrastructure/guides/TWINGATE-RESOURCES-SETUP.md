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

## Quick Reference - UI Field Mapping

**What you'll see in the Twingate resource creation form:**

| UI Field | What to Enter | Example |
|----------|---------------|---------|
| **Name** | Service name | "Proxmox - Main (DL380p)" |
| **IP Address** | Internal homelab IP | 10.0.10.3 |
| **Alias** | (Optional) Leave blank | - |
| **Port Restrictions - TCP** | "All Ports" or specific port | 8006 for Proxmox, 3000 for Grafana |
| **Port Restrictions - UDP** | Usually "All Ports" | All Ports |
| **Port Restrictions - ICMP** | Toggle to "Allow" | Allow |
| **Connector** | Auto-selected | alluring-agouti (your connector) |

**After clicking "Create Resource":**
- Configure who can access (users/groups)
- Enable security policies (device authentication)

---

## Resource Configuration

### Priority 1: Management & Monitoring

#### 1. Proxmox - Main (DL380p)

**Purpose:** Primary Proxmox host management (32 cores, 96GB RAM)

**Initial Configuration:**
- **Name:** `Proxmox - Main (DL380p)`
- **IP Address:** `10.0.10.3`
- **Port Restrictions:**
  - TCP: Specific port → `8006` (or "All Ports" for simplicity)
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected (alluring-agouti or your connector name)

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com or "Homelab Admins" group
- **Security Policy:** Enable device authentication (recommended)

**Usage:**
```
https://10.0.10.3:8006
Login: fred@authentik (via Authentik SSO)
```

---

#### 2. Proxmox - Router (i5)

**Purpose:** Secondary Proxmox host at office location

**Initial Configuration:**
- **Name:** `Proxmox - Router (i5)`
- **IP Address:** `10.0.10.2`
- **Port Restrictions:**
  - TCP: Specific port → `8006` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com or "Homelab Admins" group
- **Security Policy:** Enable device authentication

**Usage:**
```
https://10.0.10.2:8006
Login: fred@authentik (via Authentik SSO)
```

---

#### 3. Proxmox - Storage

**Purpose:** Storage-focused Proxmox host (OMV VM host)

**Initial Configuration:**
- **Name:** `Proxmox - Storage`
- **IP Address:** `10.0.10.4`
- **Port Restrictions:**
  - TCP: Specific port → `8006` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com or "Homelab Admins" group
- **Security Policy:** Enable device authentication

**Usage:**
```
https://10.0.10.4:8006
Login: fred@authentik (via Authentik SSO)
```

---

#### 4. Grafana Dashboards

**Purpose:** Infrastructure monitoring and metrics visualization

**Initial Configuration:**
- **Name:** `Grafana Monitoring`
- **IP Address:** `10.0.10.25`
- **Port Restrictions:**
  - TCP: Specific port → `3000` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com
- **Security Policy:** Enable device authentication

**Usage:**
```
http://10.0.10.25:3000
Login: fred@nianticbooks.com (via Authentik OAuth)
```

**Tip:** Once working via Twingate, you can keep Caddy route for redundancy

---

#### 5. Authentik SSO Admin

**Purpose:** User authentication and SSO management

**Initial Configuration:**
- **Name:** `Authentik SSO`
- **IP Address:** `10.0.10.21`
- **Port Restrictions:**
  - TCP: Specific port → `9000` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com (admin only)
- **Security Policy:** Enable device authentication

**Usage:**
```
http://10.0.10.21:9000
Login: akadmin / [admin password]
```

---

### Priority 2: Home Automation & Apps

#### 6. Home Assistant

**Purpose:** Smart home control and automation

**Initial Configuration:**
- **Name:** `Home Assistant`
- **IP Address:** `10.0.10.24`
- **Port Restrictions:**
  - TCP: Specific port → `8123` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com
- **Security Policy:** Enable device authentication

**Usage:**
```
http://10.0.10.24:8123
Login: Home Assistant account
```

**Tip:** Keep bob.nianticbooks.com Caddy route for redundancy

---

#### 7. n8n Workflow Automation

**Purpose:** Automation workflows and integrations

**Initial Configuration:**
- **Name:** `n8n Workflows`
- **IP Address:** `10.0.10.22`
- **Port Restrictions:**
  - TCP: Specific port → `5678` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com
- **Security Policy:** Enable device authentication

**Usage:**
```
http://10.0.10.22:5678
Login: n8n account (no SSO available in free version)
```

---

### Priority 3: Storage & Infrastructure

#### 8. OpenMediaVault (OMV)

**Purpose:** 12TB storage management and backup monitoring

**Initial Configuration:**
- **Name:** `OMV Storage`
- **IP Address:** `10.0.10.5`
- **Port Restrictions:**
  - TCP: Specific port → `80` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com
- **Security Policy:** Enable device authentication

**Usage:**
```
http://10.0.10.5
Login: admin / homelab2025
```

---

#### 9. Dockge - Docker Management

**Purpose:** Docker Compose stack management

**Initial Configuration:**
- **Name:** `Dockge`
- **IP Address:** `10.0.10.27`
- **Port Restrictions:**
  - TCP: Specific port → `5001` (or "All Ports")
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com
- **Security Policy:** Enable device authentication

**Usage:**
```
http://10.0.10.27:5001
Login: Dockge account
```

---

### Optional: SSH Access

#### 10. SSH to Proxmox Hosts

**Purpose:** Direct SSH terminal access

**Initial Configuration:**
- **Name:** `SSH - Proxmox Main`
- **IP Address:** `10.0.10.3` (create separate resource for each host)
- **Port Restrictions:**
  - TCP: Specific port → `22`
  - UDP: All Ports
  - ICMP: Allow
- **Connector:** Auto-selected

**Post-Creation (Access & Security):**
- **Access:** Grant to fred@nianticbooks.com
- **Security Policy:** Enable device authentication

**Note:** Create 3 separate resources (one for each Proxmox host: 10.0.10.2, 10.0.10.3, 10.0.10.4)

**Usage:**
```bash
ssh root@10.0.10.3
# SSH key already configured
```

---

## Step-by-Step Resource Creation

### Via Twingate Admin Console

#### Step 1: Navigate to Resources

1. Login to your Twingate admin console
2. Click **Network** tab at the top
3. Select your remote network (e.g., "routerpve-ct")
4. Click **Create Resource** button

#### Step 2: Configure Basic Settings

**Fill in the following fields:**

1. **Name:** Enter resource name (e.g., "Proxmox - Main (DL380p)")

2. **IP Address:** Enter the internal IP (e.g., "10.0.10.3")
   - This is the IP address of the service on your homelab network

3. **Alias (Optional):** Leave blank or add a friendly name

4. **Port Restrictions:**

   **Option A: Allow All Ports (Recommended for initial setup)**
   - TCP: Select "All Ports" from dropdown
   - UDP: Select "All Ports" from dropdown
   - ICMP: Toggle to "Allow"

   **Option B: Specific Ports (More secure)**
   - For Proxmox (port 8006):
     - TCP: Select specific port → Enter "8006"
     - UDP: Can leave "All Ports"
     - ICMP: Toggle to "Allow"

   - For Grafana (port 3000):
     - TCP: Select specific port → Enter "3000"

   - For Home Assistant (port 8123):
     - TCP: Select specific port → Enter "8123"

5. **Connector:** Should auto-select your connected connector (e.g., "alluring-agouti")

#### Step 3: Create Resource

Click the **Create Resource** button at the bottom

#### Step 4: Configure Access and Security (Post-Creation)

After creating the resource, you'll need to configure who can access it:

1. **Find your newly created resource** in the resource list

2. **Click on the resource** to open its settings

3. **Configure Access:**
   - Look for "Access" or "Principals" section
   - Click **Add Principal** or **Grant Access**
   - Select your user (fred@nianticbooks.com) or create a group
   - Set permissions

4. **Configure Security Policy:**
   - Look for "Security Policy" or "Policies" section
   - Enable "Require device authentication" (recommended)
   - Set any additional security requirements

5. **Save Changes**

#### Step 5: Test Access

1. Install Twingate client on your device (if not already installed)
2. Login to Twingate and connect
3. Try accessing the resource via its IP address and port
4. Example: https://10.0.10.3:8006 for Proxmox

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

**Last Updated:** 2025-12-27 (Updated for actual Twingate UI)
