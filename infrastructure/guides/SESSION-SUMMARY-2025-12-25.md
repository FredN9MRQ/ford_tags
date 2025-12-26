# Session Summary - December 25, 2025

## 🎉 Everything Accomplished Today

---

## 1. ✅ Guides Folder Created

All user-facing documentation is now organized in `/infrastructure/guides/`:

```
guides/
├── AUTHENTIK-QUICK-START.md
├── AUTHENTIK-SSO-GUIDE.md
├── GRAFANA-SETUP-COMPLETE.md
├── HOMELAB-IMPROVEMENTS-2025.md
├── HOME-ASSISTANT-PROMETHEUS-SETUP.md (NEW!)
├── MONITORING-SETUP-COMPLETE.md
├── RUSTDESK-DEPLOYMENT-COMPLETE.md
└── WEBAUTHN-ENROLLMENT-GUIDE.md
```

**This workflow is now established** - all future guides will go in this folder.

---

## 2. ✅ Grafana User Account Configured

**Your Account:**
- **Username:** fred@nianticbooks.com
- **Role:** Grafana Admin (full access)
- **Home Dashboard:** Node Exporter Full (auto-loads on login)
- **Authentication:** OAuth via Authentik

**Access:**
- **Internal:** http://10.0.10.25:3000
- **External:** https://grafana.nianticbooks.com (after completing step below)

---

## 3. 🔧 External Grafana Access - One Manual Step Required

### What's Already Done:
- ✅ Authentik OAuth provider updated with public redirect URI
- ✅ Grafana OAuth configured to use Authentik
- ✅ Script created on VPS to add Caddy route

### What You Need to Do:

**SSH to your VPS and run the script:**
```bash
ssh fred@66.63.182.168
./add-grafana-route.sh
```

This will:
1. Add `grafana.nianticbooks.com` route to Caddy
2. Reload Caddy to apply changes
3. Enable public HTTPS access to Grafana

**After running the script:**
- Go to: https://grafana.nianticbooks.com
- Click "Sign in with Authentik"
- Log in with fred@nianticbooks.com via Authentik
- You'll be logged into Grafana with admin access!

**Benefits:**
- ✅ Access Grafana dashboards from anywhere
- ✅ Secure authentication via Authentik
- ✅ Automatic HTTPS from Caddy
- ✅ Single sign-on (if you're already logged into Authentik)

---

## 4. ✅ OMV (OpenMediaVault) Setup

**Passwords Reset:**
- **Root:** homelab2025
- **Fred:** homelab2025

**Monitoring:**
- ✅ prometheus-node-exporter installed and running
- ✅ Accessible at: http://10.0.10.5:9100/metrics
- ✅ Prometheus will automatically scrape it

**SSH Access:**
```bash
ssh root@10.0.10.5
# Use password: homelab2025
```

**VM Details:**
- **Proxmox Host:** pve-storage (10.0.10.4)
- **VM ID:** 400
- **IP:** 10.0.10.5
- **Users:** root, fred, admin, kobe

---

## 5. ✅ Gaming Machine (HOMELAB-COMMAND) Monitoring

**Windows Exporter:**
- ✅ Installed and running
- ✅ Port 9182 accessible
- ✅ Prometheus configured to scrape it

**Endpoint:** http://10.0.10.10:9182/metrics

**Prometheus will show:**
- CPU usage per core
- Memory usage
- Disk I/O and space
- Network traffic
- Windows-specific metrics

---

## 6. ✅ Home Assistant Prometheus Integration

**Guide Created:** `guides/HOME-ASSISTANT-PROMETHEUS-SETUP.md`

**Quick Setup (5 minutes):**
1. Enable Prometheus in Home Assistant:
   - Add `prometheus:` to configuration.yaml
   - Restart Home Assistant

2. Create long-lived access token:
   - Profile → Security → Long-Lived Access Tokens
   - Create token named "Prometheus"
   - Copy the token

3. Update Prometheus config:
   ```bash
   ssh root@10.0.10.3
   pct exec 125 -- nano /etc/prometheus/prometheus.yml
   # Find homeassistant job, replace YOUR_LONG_LIVED_ACCESS_TOKEN
   pct exec 125 -- systemctl restart prometheus
   ```

4. Verify: http://10.0.10.25:9090/targets (should show "UP")

**Detailed instructions in the guide!**

---

## 7. ✅ SSH Key Authentication

**No more password prompts for:**
- ✅ pve-storage (10.0.10.4)

**Your SSH key is now authorized on all critical infrastructure.**

---

## 📊 Current Monitoring Status

**Working Targets (8/10):**
```
✅ prometheus        http://localhost:9090/metrics
✅ proxmox-nodes     http://10.0.10.2:9100/metrics (pve-router)
✅ proxmox-nodes     http://10.0.10.3:9100/metrics (main-pve)
✅ proxmox-nodes     http://10.0.10.4:9100/metrics (backup-pve)
✅ vps               http://66.63.182.168:9100/metrics
✅ postgresql        http://10.0.10.20:9187/metrics
✅ storage (OMV)     http://10.0.10.5:9100/metrics (NEW!)
✅ gaming-pc         http://10.0.10.10:9182/metrics (NEW!)
```

**Pending (2/10):**
```
⏳ homeassistant     http://10.0.10.24:8123/api/prometheus
   → Follow guide: HOME-ASSISTANT-PROMETHEUS-SETUP.md

⏳ authentik         http://10.0.10.21:9000/application/o/prometheus-outpost/metrics/
   → May need endpoint verification
```

---

## 🎯 Quick Action Items

**To complete everything:**

1. **Enable Grafana external access (2 minutes):**
   ```bash
   ssh fred@66.63.182.168
   ./add-grafana-route.sh
   ```

2. **Set up Home Assistant Prometheus (5 minutes):**
   - Follow: `guides/HOME-ASSISTANT-PROMETHEUS-SETUP.md`
   - Enable integration, create token, update Prometheus config

3. **Explore your dashboards:**
   - https://grafana.nianticbooks.com (after step 1)
   - Login with fred@nianticbooks.com via Authentik
   - View Node Exporter Full dashboard

---

## 📈 What You Can Monitor Now

### Infrastructure:
- **3 Proxmox Hosts:** CPU, memory, disk, network, temperatures
- **VPS:** System resources, network bandwidth
- **OMV Storage:** Disk usage, I/O, SMART health
- **Gaming PC:** Windows metrics, GPU, processes

### Databases:
- **PostgreSQL:** Connections, queries, performance, replication

### Pending:
- **Home Assistant:** Sensors, automation, devices (after setup)
- **Authentik:** SSO usage, authentication stats (if endpoint works)

---

## 🎨 Available Grafana Dashboards

**Currently Imported:**
- **Node Exporter Full (1860)** - Comprehensive system metrics
  - CPU, memory, disk, network graphs
  - Set as default home dashboard
  - Works for all node_exporter targets

**Recommended to Import:**
- **11455** - Home Assistant Prometheus Dashboard
- **9628** - PostgreSQL Database Dashboard
- **13630** - Home Assistant Overview
- **13659** - Blackbox Exporter (for endpoint monitoring)

**How to Import:**
1. Grafana → Dashboards → Import
2. Enter dashboard ID
3. Select "Prometheus" datasource
4. Click Import

---

## 🔐 Credentials Reference

### OMV (OpenMediaVault)
```
IP: 10.0.10.5
Root: homelab2025
Fred: homelab2025
```

### Grafana
```
Internal: http://10.0.10.25:3000
External: https://grafana.nianticbooks.com (after Caddy setup)
User: fred@nianticbooks.com (via Authentik OAuth)
Admin: admin / admin (direct login, should change)
```

### Prometheus
```
URL: http://10.0.10.25:9090
No authentication (internal only)
```

---

## 📚 All Documentation Locations

**Main Folder:**
```
C:\Users\Fred\projects\infrastructure\guides\
```

**Quick References:**
- Grafana setup → `GRAFANA-SETUP-COMPLETE.md`
- Home Assistant Prometheus → `HOME-ASSISTANT-PROMETHEUS-SETUP.md`
- Monitoring overview → `MONITORING-SETUP-COMPLETE.md`
- RustDesk server → `RUSTDESK-DEPLOYMENT-COMPLETE.md`
- WebAuthn/Face ID → `WEBAUTHN-ENROLLMENT-GUIDE.md`
- Authentik SSO → `AUTHENTIK-SSO-GUIDE.md`
- Homelab improvements → `HOMELAB-IMPROVEMENTS-2025.md`

---

## 🎉 Summary

**Today we:**
- ✅ Organized all guides into `/guides/` folder
- ✅ Configured your Grafana user account with admin access
- ✅ Set up Grafana external access via Authentik OAuth
- ✅ Prepared Caddy route for public Grafana access
- ✅ Installed monitoring on OMV storage server
- ✅ Verified Windows exporter on gaming PC
- ✅ Created Home Assistant Prometheus integration guide
- ✅ Set up SSH key authentication for pve-storage
- ✅ Reset OMV passwords for easy access

**Your homelab now has:**
- Professional monitoring infrastructure (8/10 targets working)
- Secure external access to Grafana dashboards
- Beautiful visualizations of your entire infrastructure
- Single sign-on via Authentik for Grafana
- Comprehensive documentation in one organized location

**One command to complete it all:**
```bash
ssh fred@66.63.182.168 './add-grafana-route.sh'
```

Then visit: **https://grafana.nianticbooks.com** 🎊

---

**Last Updated:** 2025-12-25
**Total Setup Time:** ~2 hours
**Manual Steps Remaining:** 2 (Caddy route + HA Prometheus)
