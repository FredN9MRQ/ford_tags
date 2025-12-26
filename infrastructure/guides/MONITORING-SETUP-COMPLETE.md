# Monitoring Setup - Session Complete

**Date:** 2025-12-25
**Status:** Core monitoring infrastructure deployed ✅

---

## ✅ Completed Today

### 1. Proxmox Fixes
- ✅ Fixed Proxmox OAuth redirect cert issue (Caddy headers)
- ✅ Set Authentik realm as default on all 3 Proxmox hosts
- ✅ WebAuthn configured for Face ID & Windows Hello

### 2. Monitoring Infrastructure
- ✅ Installed `prometheus-node-exporter` on all 3 Proxmox hosts
  - main-pve (10.0.10.3): ✅ RUNNING
  - pve-router (10.0.10.2): ✅ RUNNING
  - backup-pve (10.0.10.4): ✅ RUNNING

- ✅ Applied comprehensive Prometheus configuration
  - Config file: `infrastructure/prometheus-config.yml`
  - Backup: `/etc/prometheus/prometheus.yml.backup-<date>`

- ✅ Verified Prometheus scraping targets
  - Prometheus: http://10.0.10.25:9090 ✅ UP
  - Grafana: http://10.0.10.25:3000 ✅ RUNNING

---

## 📊 Current Monitoring Status

**Working (5/10 targets):**
```
✅ prometheus      http://localhost:9090/metrics
✅ proxmox-nodes   http://10.0.10.2:9100/metrics
✅ proxmox-nodes   http://10.0.10.3:9100/metrics
✅ proxmox-nodes   http://10.0.10.4:9100/metrics
```

**Needs Setup (5/10 targets):**
```
⏳ vps             http://66.63.182.168:9100/metrics
⏳ storage         http://10.0.10.5:9100/metrics
⏳ gaming-pc       http://10.0.10.10:9182/metrics
⏳ authentik       http://10.0.10.21:9000/...
⏳ homeassistant   http://10.0.10.24:8123/api/prometheus
⏳ postgresql      http://10.0.10.20:9187/metrics
```

---

## 📋 Next Steps

### Quick Wins (15 min total)

**1. Install node_exporter on VPS**
```bash
ssh 66.63.182.168
~/install-node-exporter.sh
```

**2. Install node_exporter on OMV (Storage)**
```bash
ssh root@10.0.10.5  # or whatever user you have
sudo apt update && sudo apt install -y prometheus-node-exporter
sudo systemctl enable prometheus-node-exporter
sudo systemctl start prometheus-node-exporter
```

**3. Set up Grafana Dashboards**
1. Go to http://10.0.10.25:3000
2. Login with your credentials (or reset admin password if needed)
3. Add Prometheus datasource:
   - Configuration → Data Sources → Add data source
   - Select "Prometheus"
   - URL: `http://localhost:9090`
   - Click "Save & Test"

4. Import dashboards:
   - Dashboards → Import
   - Enter Dashboard ID: `1860` (Node Exporter Full)
   - Select Prometheus datasource
   - Click Import

   Popular dashboard IDs:
   - `1860` - Node Exporter Full
   - `11074` - Node Exporter for Prometheus Dashboard
   - `3662` - Prometheus 2.0 Overview

### Optional Enhancements (30-60 min)

**4. Install Windows Exporter on Gaming PC**
- Download from: https://github.com/prometheus-community/windows_exporter/releases
- Install MSI package
- Verify at: http://localhost:9182/metrics

**5. Configure Home Assistant Prometheus Integration**
1. Settings → Devices & Services → Add Integration
2. Search "Prometheus"
3. Configure
4. Create long-lived access token
5. Update Prometheus config with token

**6. Install PostgreSQL Exporter**
```bash
ssh root@10.0.10.3
pct exec 102  # PostgreSQL container
apt install -y prometheus-postgres-exporter
# Configure connection string
```

**7. Fix Authentik Metrics**
- Check Authentik documentation for Prometheus metrics endpoint
- May need to enable metrics in Authentik settings

**8. Configure Grafana OAuth with Authentik**
- Create OAuth provider in Authentik
- Configure Grafana to use Authentik for SSO

---

## 🔍 Verify Everything

**Check Prometheus Targets:**
```bash
ssh root@10.0.10.3
pct exec 125 -- curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool
```

**Check node_exporter metrics:**
```bash
# On any Proxmox host
curl http://localhost:9100/metrics | head -20
```

**Access Grafana:**
- URL: http://10.0.10.25:3000
- Default login: admin / admin (change on first login)

**Access Prometheus:**
- URL: http://10.0.10.25:9090
- Status → Targets to see all monitoring targets

---

## 📚 Documentation References

**Prometheus Configuration:**
- File: `/etc/prometheus/prometheus.yml`
- Documentation: `infrastructure/prometheus-config.yml`
- Contains all configured targets and examples

**Installed Exporters:**
- Node Exporter docs: https://github.com/prometheus/node_exporter
- Windows Exporter: https://github.com/prometheus-community/windows_exporter
- PostgreSQL Exporter: https://github.com/prometheus-community/postgres_exporter

**Grafana Dashboards:**
- Official library: https://grafana.com/grafana/dashboards/
- Node Exporter dashboards: Search for "node exporter"

---

## 🎯 What You Can See Now

With the current setup, you can monitor:

**Proxmox Hosts (all 3):**
- CPU usage, load average
- Memory usage
- Disk I/O and space
- Network traffic
- System temperature (via ipmitool sensors)
- SMART drive health
- Running processes

**Prometheus Itself:**
- Scrape performance
- Time series database size
- Query performance

---

## 💡 Homelab Monitoring Best Practices

1. **Set up alerting** - Configure Alertmanager for critical alerts
2. **Retention policy** - Prometheus keeps 30 days (configured)
3. **Backup Grafana** - Export dashboards regularly
4. **Monitor the monitors** - Set up uptime checks for Prometheus/Grafana
5. **Security** - Enable authentication on Prometheus (currently open)

---

## 🚀 Future Enhancements

- [ ] Set up Alertmanager for email/Slack notifications
- [ ] Add blackbox exporter for HTTP endpoint monitoring
- [ ] Add SNMP exporter for UCG Ultra monitoring
- [ ] Set up Loki for log aggregation
- [ ] Create custom dashboards for your specific needs
- [ ] Add SSL certificate expiration monitoring

---

**Session Summary:**
- ✅ Core infrastructure monitoring operational
- ✅ 3/3 Proxmox hosts monitored
- ✅ Prometheus & Grafana running
- ✅ Foundation ready for additional targets
- 📊 Ready to visualize with Grafana dashboards!
