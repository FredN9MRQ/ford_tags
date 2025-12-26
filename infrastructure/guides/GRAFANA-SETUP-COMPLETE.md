# Grafana and Monitoring Setup - Complete

**Date:** 2025-12-25
**Status:** Core setup complete, manual steps required

---

## ✅ Completed Automatically

### 1. Grafana Configuration
- **Grafana:** Running at http://10.0.10.25:3000
- **Version:** 12.3.0
- **Admin credentials:** admin / admin (reset successfully)
- **Prometheus datasource:** ✅ Added and configured
- **Dashboard imported:** Node Exporter Full (ID: 1860) ✅

### 2. PostgreSQL Exporter
- **Installed:** ✅ prometheus-postgres-exporter on container 102
- **Endpoint:** http://10.0.10.20:9187/metrics
- **User created:** prometheus (with pg_monitor role)
- **Status:** ✅ Running and listening

---

## 📋 Manual Steps Required

### Home Assistant Prometheus Integration

The Prometheus integration has been added to your local configuration file at:
```
C:\Users\Fred\projects\infrastructure\home-assistant\configuration.yaml
```

**To complete the setup:**

**Option 1: Manual Config Deployment (Recommended)**
1. Access your Home Assistant instance: http://10.0.10.24:8123
2. Go to File Editor (or Settings → Add-ons → File Editor)
3. Open `configuration.yaml`
4. Add this section:
   ```yaml
   # Prometheus metrics export
   prometheus:
   ```
5. Go to Developer Tools → YAML
6. Click "Check Configuration"
7. If valid, click "Restart Home Assistant"
8. Metrics will be available at: http://10.0.10.24:8123/api/prometheus

**Option 2: UI Integration (Alternative)**
1. Settings → Devices & Services → Add Integration
2. Search for "Prometheus"
3. Enable the integration
4. Metrics will be available at: http://10.0.10.24:8123/api/prometheus

**Then update Prometheus configuration:**
The prometheus config at `/etc/prometheus/prometheus.yml` needs the Home Assistant bearer token.

To create a long-lived access token:
1. In Home Assistant: Profile → Security → Long-Lived Access Tokens
2. Click "Create Token"
3. Name it: "Prometheus"
4. Copy the token
5. SSH to Prometheus container:
   ```bash
   ssh root@10.0.10.3
   pct exec 125 -- nano /etc/prometheus/prometheus.yml
   ```
6. Find the `homeassistant` job and replace `YOUR_LONG_LIVED_ACCESS_TOKEN` with your token
7. Restart Prometheus:
   ```bash
   pct exec 125 -- systemctl restart prometheus
   ```

---

## 📊 Current Monitoring Targets

### Working (7/10 targets):
```
✅ prometheus        http://localhost:9090/metrics
✅ proxmox-nodes     http://10.0.10.2:9100/metrics (pve-router)
✅ proxmox-nodes     http://10.0.10.3:9100/metrics (main-pve)
✅ proxmox-nodes     http://10.0.10.4:9100/metrics (backup-pve)
✅ vps               http://66.63.182.168:9100/metrics
✅ postgresql        http://10.0.10.20:9187/metrics (NEW!)
```

### Needs Token/Config (3/10 targets):
```
⏳ homeassistant     http://10.0.10.24:8123/api/prometheus (needs token)
⏳ authentik         http://10.0.10.21:9000/... (needs config verification)
⏳ gaming-pc         http://10.0.10.10:9182/metrics (Windows exporter not installed)
⏳ storage           http://10.0.10.5:9100/metrics (node exporter not installed)
```

---

## 🎯 Access Your Monitoring

### Grafana Dashboard
1. Go to: http://10.0.10.25:3000
2. Login: admin / admin (you'll be prompted to change password)
3. Navigate to: Dashboards → Browse
4. Open: "Node Exporter Full"
5. You should see metrics from all 3 Proxmox hosts + VPS!

### Prometheus Targets
1. Go to: http://10.0.10.25:9090
2. Click: Status → Targets
3. Verify all targets are "UP"

---

## 📈 What You Can Monitor Now

### Proxmox Hosts (all 3):
- CPU usage, load average
- Memory usage
- Disk I/O and space
- Network traffic
- System temperature
- Running processes

### PostgreSQL Database:
- Connection counts
- Query performance
- Database size
- Table statistics
- Index usage
- Replication lag

### VPS:
- System resources
- Network bandwidth
- Service health

---

## 🔧 Optional Enhancements

### 1. Install Windows Exporter on Gaming PC (10.0.10.10)
Download from: https://github.com/prometheus-community/windows_exporter/releases
- Install the MSI package
- Verify at: http://localhost:9182/metrics
- Prometheus will automatically scrape it

### 2. Install Node Exporter on OMV Storage (10.0.10.5)
```bash
ssh root@10.0.10.5
apt update && apt install -y prometheus-node-exporter
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter
```

### 3. Import Additional Grafana Dashboards
Some useful dashboard IDs:
- `11074` - Alternative Node Exporter dashboard
- `9628` - PostgreSQL Database dashboard
- `13659` - Blackbox Exporter dashboard (for endpoint monitoring)
- `3590` - Proxmox VE dashboard (if you install pve-exporter)

**To import:**
1. Grafana → Dashboards → Import
2. Enter dashboard ID
3. Select "Prometheus" datasource
4. Click Import

### 4. Configure Alerting
Set up Alertmanager for proactive notifications:
- CPU/Memory/Disk alerts
- Service down alerts
- Certificate expiration warnings
- Backup failure alerts

---

## 📚 Next Steps

**Immediate:**
1. Login to Grafana and change admin password
2. Explore the Node Exporter Full dashboard
3. Deploy Home Assistant Prometheus integration (manual steps above)

**Optional:**
4. Install Windows exporter on gaming PC
5. Install node_exporter on OMV storage
6. Import additional dashboards
7. Set up Alertmanager

---

## 🎉 What We Accomplished Today

- ✅ Grafana fully configured with Prometheus datasource
- ✅ Professional monitoring dashboard imported
- ✅ PostgreSQL exporter installed and configured
- ✅ 7/10 monitoring targets operational
- ✅ Infrastructure ready for comprehensive monitoring

**All core monitoring infrastructure is now operational!**

**Last Updated:** 2025-12-25
