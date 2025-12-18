# Monitoring Setup Guide

This guide provides step-by-step instructions for setting up monitoring for your infrastructure.

## Table of Contents
- [Monitoring Strategy](#monitoring-strategy)
- [Quick Start: Uptime Kuma](#quick-start-uptime-kuma)
- [Comprehensive Stack: Prometheus + Grafana](#comprehensive-stack-prometheus--grafana)
- [Log Aggregation: Loki](#log-aggregation-loki)
- [Alerting Setup](#alerting-setup)
- [Dashboards](#dashboards)
- [Maintenance](#maintenance)

---

## Monitoring Strategy

### What to Monitor

**Infrastructure Level**:
- VPS: CPU, RAM, disk, network
- Proxmox nodes: CPU, RAM, disk, network
- OMV storage: Disk usage, SMART status
- Network: Bandwidth, connectivity

**Service Level**:
- Service uptime and response time
- HTTP/HTTPS endpoints
- Gerbil tunnel status
- SSL certificate expiration
- Backup job success/failure

**Application Level**:
- Application-specific metrics
- Error rates
- Request rates
- Database performance

### Monitoring Tiers

| Tier | Solution | Complexity | Setup Time | Cost |
|------|----------|------------|------------|------|
| Basic | Uptime Kuma | Low | 30 min | Free |
| Intermediate | Prometheus + Grafana | Medium | 2-4 hours | Free |
| Advanced | Full observability stack | High | 8+ hours | Free/Paid |

---

## Quick Start: Uptime Kuma

**Best for**: Simple uptime monitoring with alerts

### Installation

```bash
# On a Proxmox container or VM
# Create container with Ubuntu/Debian

# Install Docker
curl -fsSL https://get.docker.com | sh

# Run Uptime Kuma
docker run -d --restart=always \
  -p 3001:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma:1

# Access at http://HOST_IP:3001
```

### Configuration

1. **Create Admin Account**
   - First login creates admin user

2. **Add Monitors**

   **HTTP(S) Monitor**:
   - Monitor Type: HTTP(s)
   - Friendly Name: Service Name
   - URL: https://service.example.com
   - Heartbeat Interval: 60 seconds
   - Retries: 3

   **Ping Monitor**:
   - Monitor Type: Ping
   - Hostname: VPS or node IP
   - Interval: 60 seconds

   **Port Monitor**:
   - Monitor Type: Port
   - Hostname: IP address
   - Port: Service port

3. **Set Up Notifications**
   - Settings → Notifications
   - Add notification method (email, Slack, Discord, etc.)
   - Test notification

4. **Create Status Page** (Optional)
   - Status Pages → Add Status Page
   - Add monitors to display
   - Make public or private

### Monitors to Create

- [ ] VPS SSH (Port 22 or custom)
- [ ] VPS HTTP/HTTPS (Port 80/443)
- [ ] Each public service endpoint
- [ ] Proxmox web interface (each node)
- [ ] OMV web interface

---

## Comprehensive Stack: Prometheus + Grafana

**Best for**: Detailed metrics, trending, and advanced alerting

### Architecture

```
┌─────────────┐     ┌───────────┐     ┌─────────┐
│  Exporters  │────▶│ Prometheus│────▶│ Grafana │
│  (Metrics)  │     │ (Storage) │     │  (UI)   │
└─────────────┘     └───────────┘     └─────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │Alertmanager │
                    └─────────────┘
```

### Installation (Docker Compose)

```bash
# Create monitoring directory
mkdir -p ~/monitoring
cd ~/monitoring

# Create docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=changeme
      - GF_INSTALL_PLUGINS=grafana-piechart-panel

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro,rslave'

volumes:
  prometheus-data:
  grafana-data:
EOF

# Create Prometheus config
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node exporter (system metrics)
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
        labels:
          instance: 'monitoring-host'

  # Add more exporters here
  # - job_name: 'proxmox'
  #   static_configs:
  #     - targets: ['proxmox-node-1:9221']
EOF

# Start services
docker-compose up -d
```

### Access

- **Prometheus**: http://HOST_IP:9090
- **Grafana**: http://HOST_IP:3000 (admin/changeme)

### Configure Grafana

1. **Add Prometheus Data Source**
   - Configuration → Data Sources → Add data source
   - Select Prometheus
   - URL: http://prometheus:9090
   - Click "Save & Test"

2. **Import Dashboards**
   - Dashboard → Import
   - Import these popular dashboards:
     - 1860: Node Exporter Full
     - 10180: Proxmox via Prometheus
     - 763: Disk I/O performance

### Install Exporters

**Node Exporter** (on each host to monitor):
```bash
# Download
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/

# Create systemd service
sudo cat > /etc/systemd/system/node_exporter.service <<'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify
curl http://localhost:9100/metrics
```

**Proxmox VE Exporter**:
```bash
# On Proxmox node
wget https://github.com/prometheus-pve/prometheus-pve-exporter/releases/latest/download/pve_exporter
chmod +x pve_exporter
sudo mv pve_exporter /usr/local/bin/

# Create config
sudo mkdir -p /etc/prometheus
sudo cat > /etc/prometheus/pve.yml <<EOF
default:
  user: monitoring@pve
  password: your_password
  verify_ssl: false
EOF

# Create systemd service
sudo cat > /etc/systemd/system/pve_exporter.service <<'EOF'
[Unit]
Description=Proxmox VE Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pve_exporter /etc/prometheus/pve.yml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pve_exporter
sudo systemctl start pve_exporter
```

**Blackbox Exporter** (for HTTP/HTTPS probing):
```bash
# Add to docker-compose.yml
  blackbox:
    image: prom/blackbox-exporter:latest
    container_name: blackbox-exporter
    restart: unless-stopped
    ports:
      - "9115:9115"
    volumes:
      - ./blackbox.yml:/etc/blackbox_exporter/config.yml
```

```yaml
# blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []
      method: GET
  tcp_connect:
    prober: tcp
    timeout: 5s
```

### Add Scrape Targets

Add to `prometheus.yml`:
```yaml
  # VPS Node Exporter
  - job_name: 'vps'
    static_configs:
      - targets: ['VPS_IP:9100']

  # Proxmox Nodes
  - job_name: 'proxmox'
    static_configs:
      - targets: ['PROXMOX_IP_1:9221', 'PROXMOX_IP_2:9221']

  # HTTP Endpoints
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://service1.example.com
          - https://service2.example.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115
```

---

## Log Aggregation: Loki

**Best for**: Centralized logging from all services

### Installation

Add to `docker-compose.yml`:
```yaml
  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/local-config.yaml
      - loki-data:/loki

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    restart: unless-stopped
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/log:/var/log
    command: -config.file=/etc/promtail/config.yml

volumes:
  loki-data:
```

### Configure Loki in Grafana

1. Configuration → Data Sources → Add data source
2. Select Loki
3. URL: http://loki:3100
4. Save & Test

### Query Logs

In Grafana Explore:
```logql
# All logs
{job="varlogs"}

# Filter by service
{job="varlogs"} |= "pangolin"

# Error logs
{job="varlogs"} |= "error"
```

---

## Alerting Setup

### Prometheus Alerting Rules

Create `alerts.yml`:
```yaml
groups:
  - name: infrastructure
    interval: 30s
    rules:
      # Node down
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} has been down for more than 5 minutes"

      # High CPU
      - alert: HighCPU
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
          description: "CPU usage is above 80% for 10 minutes"

      # High Memory
      - alert: HighMemory
        expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low memory on {{ $labels.instance }}"
          description: "Available memory is below 10%"

      # Disk Space
      - alert: LowDiskSpace
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 10% on {{ $labels.mountpoint }}"

      # SSL Certificate Expiring
      - alert: SSLCertExpiringSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 30
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "SSL certificate expiring soon"
          description: "Certificate for {{ $labels.instance }} expires in less than 30 days"
```

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'

receivers:
  - name: 'default'
    email_configs:
      - to: 'your-email@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'username'
        auth_password: 'password'

  # Slack
  - name: 'slack'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

---

## Dashboards

### Essential Dashboards

1. **Infrastructure Overview**
   - All nodes status
   - Overall resource utilization
   - Service uptime

2. **VPS Dashboard**
   - CPU, RAM, disk, network
   - Running services
   - Firewall connections

3. **Proxmox Cluster**
   - Cluster health
   - VM/container count and status
   - Resource allocation vs usage

4. **Storage**
   - Disk space trends
   - I/O performance
   - SMART status

5. **Services**
   - Uptime percentage
   - Response times
   - Error rates

6. **Tunnels**
   - Gerbil tunnel status
   - Connection count
   - Bandwidth usage

### Creating Custom Dashboard

1. Grafana → Create → Dashboard
2. Add Panel → Select visualization
3. Write PromQL query
4. Configure thresholds and alerts
5. Save dashboard

---

## Maintenance

### Regular Tasks

**Daily**:
- Review alerts
- Check dashboard for anomalies

**Weekly**:
- Review resource trends
- Check for unused monitors
- Update dashboards

**Monthly**:
- Review and tune alert thresholds
- Clean up old metrics
- Update monitoring stack
- Test alerting

**Quarterly**:
- Review monitoring strategy
- Evaluate new monitoring tools
- Update documentation

### Troubleshooting

**Prometheus not scraping**:
```bash
# Check targets
curl http://localhost:9090/targets

# Check Prometheus logs
docker logs prometheus
```

**Grafana dashboard empty**:
- Verify data source connection
- Check time range
- Verify metrics exist in Prometheus

**No alerts firing**:
- Check alerting rules syntax
- Verify Alertmanager connection
- Test alert evaluation

---

## Monitoring Checklist

### Initial Setup
- [ ] Choose monitoring tier (Basic/Intermediate/Advanced)
- [ ] Deploy monitoring stack
- [ ] Install exporters on all hosts
- [ ] Configure Grafana data sources
- [ ] Import/create dashboards
- [ ] Set up alerting
- [ ] Configure notification channels
- [ ] Test alerts

### Monitors to Configure
- [ ] VPS uptime and resources
- [ ] Proxmox node resources
- [ ] OMV storage capacity
- [ ] All public HTTP(S) endpoints
- [ ] Gerbil tunnel status
- [ ] SSL certificate expiration
- [ ] Backup job success
- [ ] Network connectivity
- [ ] Service-specific metrics

### Alerts to Configure
- [ ] Service down (>5 min)
- [ ] High CPU (>80% for 10 min)
- [ ] High memory (>90% for 5 min)
- [ ] Low disk space (<10%)
- [ ] SSL cert expiring (<30 days)
- [ ] Backup failure
- [ ] Tunnel disconnected

---

## Cost Considerations

### Free Tier Options
- **Uptime Kuma**: Fully free, self-hosted
- **Prometheus + Grafana**: Free, self-hosted
- **Grafana Cloud**: Free tier available (limited)

### Paid Options (if needed)
- **Datadog**: $15/host/month
- **New Relic**: $99/month+
- **Better Uptime**: $10/month+

**Recommendation**: Start with free self-hosted tools, upgrade only if needed.

---

**Last Updated**: _____________
**Next Review**: _____________
**Version**: 1.0
