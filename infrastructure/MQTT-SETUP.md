# MQTT Broker Setup Guide (Mosquitto)

This guide covers deploying a Mosquitto MQTT broker for Home Assistant and other IoT integrations on your Proxmox infrastructure.

## What is MQTT?

MQTT (Message Queuing Telemetry Transport) is a lightweight messaging protocol designed for IoT devices. It enables efficient publish/subscribe communication between devices and services like Home Assistant.

**Common Uses:**
- Smart home device communication (sensors, switches, lights)
- ESP8266/ESP32 devices via ESPHome
- Zigbee2MQTT and Z-Wave integration
- Custom automation scripts
- Inter-service messaging

## Deployment Overview

**Service:** Mosquitto MQTT Broker
**Location:** pve-router (i5 Proxmox node at 10.0.10.2)
**IP Address:** 10.0.10.26
**Deployment Method:** LXC Container (lightweight, efficient)

## Prerequisites

- Access to Proxmox web interface (https://10.0.10.2:8006)
- Ubuntu/Debian LXC template downloaded on Proxmox
- DHCP reservation configured on UCG Ultra for 10.0.10.26

## Part 1: Create LXC Container

### 1.1 Download Container Template

In Proxmox web interface on pve-router:

1. Select **pve-router** node
2. Click **local (pve-router)** storage
3. Click **CT Templates**
4. Click **Templates** button
5. Search for and download: **ubuntu-22.04-standard** or **debian-12-standard**

### 1.2 Create Container

1. Click **Create CT** (top right)
2. Configure as follows:

**General Tab:**
- Node: `pve-router`
- CT ID: (next available, e.g., 105)
- Hostname: `mosquitto`
- Password: (set a strong root password)
- SSH public key: (optional, recommended)

**Template Tab:**
- Storage: `local`
- Template: `ubuntu-22.04-standard` (or debian-12)

**Disks Tab:**
- Storage: `local-lvm` (or your preferred storage)
- Disk size: `2 GiB` (plenty for MQTT logs and config)

**CPU Tab:**
- Cores: `1`

**Memory Tab:**
- Memory (MiB): `512`
- Swap (MiB): `512`

**Network Tab:**
- Bridge: `vmbr0`
- IPv4: `Static`
- IPv4/CIDR: `10.0.10.26/24`
- Gateway: `10.0.10.1`
- IPv6: `SLAAC` (or disable if not using IPv6)

**DNS Tab:**
- DNS domain: `home` (or leave blank)
- DNS servers: `10.0.10.1` (UCG Ultra)

3. Click **Finish** (uncheck "Start after created" - we'll configure first)

### 1.3 Configure UCG Ultra DHCP Reservation (Optional Backup)

Even though we're using static IP, create a DHCP reservation as backup:

1. Access UCG Ultra at https://10.0.10.1
2. Settings → Networks → LAN → DHCP
3. Add reservation:
   - **IP Address:** 10.0.10.26
   - **MAC Address:** (get from Proxmox container network tab after first start)
   - **Hostname:** mosquitto
   - **Description:** MQTT Broker (Mosquitto)

## Part 2: Install and Configure Mosquitto

### 2.1 Start Container and Login

In Proxmox:
1. Select the mosquitto container
2. Click **Start**
3. Click **Console** (or SSH via `ssh root@10.0.10.26`)

### 2.2 Update System

```bash
# Update package lists
apt update

# Upgrade existing packages
apt upgrade -y

# Install basic utilities
apt install -y curl wget nano htop
```

### 2.3 Install Mosquitto

```bash
# Install Mosquitto broker and clients
apt install -y mosquitto mosquitto-clients

# Enable and start service
systemctl enable mosquitto
systemctl start mosquitto

# Verify it's running
systemctl status mosquitto
```

### 2.4 Configure Mosquitto

**Create configuration file:**

```bash
# Backup original config
cp /etc/mosquitto/mosquitto.conf /etc/mosquitto/mosquitto.conf.bak

# Create new configuration
nano /etc/mosquitto/mosquitto.conf
```

**Basic Configuration:**

```conf
# /etc/mosquitto/mosquitto.conf
# Basic MQTT broker configuration

# Listener settings
listener 1883
protocol mqtt

# Allow anonymous connections (for initial testing only)
allow_anonymous true

# Persistence settings
persistence true
persistence_location /var/lib/mosquitto/

# Logging
log_dest file /var/log/mosquitto/mosquitto.log
log_dest stdout
log_type error
log_type warning
log_type notice
log_type information

# Connection, protocol, and logging settings
connection_messages true
log_timestamp true
```

**Save and exit** (Ctrl+X, Y, Enter)

### 2.5 Restart Mosquitto

```bash
systemctl restart mosquitto
systemctl status mosquitto
```

## Part 3: Secure MQTT with Authentication

### 3.1 Create MQTT User

```bash
# Create password file for user 'homeassistant'
mosquitto_passwd -c /etc/mosquitto/passwd homeassistant

# You'll be prompted to enter a password twice
# Save this password - you'll need it for Home Assistant
```

**Add additional users:**

```bash
# Add more users (without -c flag to avoid overwriting)
mosquitto_passwd /etc/mosquitto/passwd esphome
mosquitto_passwd /etc/mosquitto/passwd automation
```

### 3.2 Update Configuration for Authentication

Edit config:

```bash
nano /etc/mosquitto/mosquitto.conf
```

**Change this line:**
```conf
allow_anonymous true
```

**To:**
```conf
allow_anonymous false
password_file /etc/mosquitto/passwd
```

**Save and restart:**

```bash
systemctl restart mosquitto
systemctl status mosquitto
```

## Part 4: Testing MQTT

### 4.1 Test Locally on Container

**Terminal 1 - Subscribe to test topic:**

```bash
mosquitto_sub -h localhost -t test/topic -u homeassistant -P YOUR_PASSWORD
```

**Terminal 2 - Publish message:**

```bash
mosquitto_pub -h localhost -t test/topic -m "Hello MQTT!" -u homeassistant -P YOUR_PASSWORD
```

You should see "Hello MQTT!" appear in Terminal 1.

### 4.2 Test from Another Machine

From any computer on your network:

```bash
# Subscribe
mosquitto_sub -h 10.0.10.26 -t test/topic -u homeassistant -P YOUR_PASSWORD

# Publish (from another terminal)
mosquitto_pub -h 10.0.10.26 -t test/topic -m "Remote test" -u homeassistant -P YOUR_PASSWORD
```

## Part 5: Integrate with Home Assistant

### 5.1 Add MQTT Integration

1. Open Home Assistant at http://10.0.10.24:8123
2. Go to **Settings → Devices & Services**
3. Click **Add Integration**
4. Search for **MQTT**
5. Configure:
   - **Broker:** `10.0.10.26`
   - **Port:** `1883`
   - **Username:** `homeassistant`
   - **Password:** (password you set earlier)
   - Leave other settings as default
6. Click **Submit**

### 5.2 Verify Connection

In Home Assistant:
1. Go to **Settings → Devices & Services**
2. Click on **MQTT**
3. You should see "Connected"

### 5.3 Test MQTT in Home Assistant

1. Developer Tools → **MQTT**
2. **Listen to topic:** `homeassistant/#`
3. Click **Start Listening**
4. In **Publish** section:
   - **Topic:** `homeassistant/test`
   - **Payload:** `{"message": "Hello from HA"}`
   - Click **Publish**
5. You should see the message appear in the listen section

## Part 6: ESPHome Integration

If you're using ESPHome (10.0.10.28):

**Add to your ESPHome device YAML:**

```yaml
mqtt:
  broker: 10.0.10.26
  port: 1883
  username: esphome
  password: YOUR_ESPHOME_PASSWORD
  discovery: true
  discovery_prefix: homeassistant
```

This enables ESPHome devices to publish data to Home Assistant via MQTT.

## Part 7: Advanced Configuration (Optional)

### 7.1 Enable TLS/SSL Encryption

**Generate self-signed certificate (for internal use):**

```bash
# Install certbot or use openssl
apt install -y openssl

# Create directory for certificates
mkdir -p /etc/mosquitto/certs
cd /etc/mosquitto/certs

# Generate CA key and certificate
openssl req -new -x509 -days 3650 -extensions v3_ca -keyout ca.key -out ca.crt

# Generate server key and certificate
openssl genrsa -out server.key 2048
openssl req -new -out server.csr -key server.key
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 3650

# Set permissions
chmod 600 /etc/mosquitto/certs/*.key
chown mosquitto:mosquitto /etc/mosquitto/certs/*
```

**Update mosquitto.conf:**

```conf
# Add TLS listener
listener 8883
protocol mqtt
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
```

Restart: `systemctl restart mosquitto`

### 7.2 WebSocket Support (for Browser Clients)

**Add to mosquitto.conf:**

```conf
# WebSocket listener
listener 9001
protocol websockets
```

Useful for web-based MQTT clients or browser automation.

### 7.3 Access Control Lists (ACLs)

**Create ACL file:**

```bash
nano /etc/mosquitto/acl
```

**Example ACL:**

```conf
# homeassistant can access everything
user homeassistant
topic readwrite #

# esphome can only publish sensor data
user esphome
topic write sensors/#
topic read homeassistant/status

# automation user for scripts
user automation
topic readwrite automation/#
```

**Update mosquitto.conf:**

```conf
acl_file /etc/mosquitto/acl
```

Restart: `systemctl restart mosquitto`

## Part 8: Monitoring and Maintenance

### 8.1 Check Logs

```bash
# Real-time log monitoring
tail -f /var/log/mosquitto/mosquitto.log

# Check systemd logs
journalctl -u mosquitto -f

# Last 100 lines
journalctl -u mosquitto -n 100
```

### 8.2 Monitor MQTT Traffic

```bash
# Subscribe to all topics (careful in production!)
mosquitto_sub -h localhost -t '#' -u homeassistant -P YOUR_PASSWORD -v

# Monitor specific namespace
mosquitto_sub -h localhost -t 'homeassistant/#' -u homeassistant -P YOUR_PASSWORD -v
```

### 8.3 Container Resource Monitoring

```bash
# Check CPU/memory usage
htop

# Check disk usage
df -h

# Check mosquitto process
ps aux | grep mosquitto
```

### 8.4 Backup Configuration

```bash
# Create backup script
nano /root/backup-mqtt.sh
```

**Backup script:**

```bash
#!/bin/bash
# MQTT configuration backup

BACKUP_DIR="/root/mqtt-backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup config, passwords, ACLs
tar -czf "$BACKUP_DIR/mqtt-config-$DATE.tar.gz" \
    /etc/mosquitto/mosquitto.conf \
    /etc/mosquitto/passwd \
    /etc/mosquitto/acl \
    /etc/mosquitto/certs/ 2>/dev/null

# Keep only last 10 backups
ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +11 | xargs -r rm

echo "Backup completed: mqtt-config-$DATE.tar.gz"
```

Make executable: `chmod +x /root/backup-mqtt.sh`

**Add to crontab:**

```bash
crontab -e
```

Add: `0 2 * * 0 /root/backup-mqtt.sh` (weekly at 2 AM Sunday)

## Part 9: Firewall Configuration

### 9.1 UFW Firewall (Optional but Recommended)

```bash
# Install UFW
apt install -y ufw

# Allow SSH (IMPORTANT - don't lock yourself out!)
ufw allow 22/tcp

# Allow MQTT
ufw allow 1883/tcp comment 'MQTT'

# If using TLS
ufw allow 8883/tcp comment 'MQTT TLS'

# If using WebSockets
ufw allow 9001/tcp comment 'MQTT WebSocket'

# Enable firewall
ufw enable

# Check status
ufw status
```

### 9.2 UCG Ultra Firewall

The UCG Ultra should allow internal LAN traffic by default. No additional rules needed for 10.0.10.0/24 communication.

## Part 10: Troubleshooting

### MQTT Service Won't Start

```bash
# Check for syntax errors in config
mosquitto -c /etc/mosquitto/mosquitto.conf -v

# Check permissions
ls -la /etc/mosquitto/
ls -la /var/lib/mosquitto/
```

### Cannot Connect from Home Assistant

**Check network connectivity:**

```bash
# From Home Assistant container/VM
ping 10.0.10.26

# Check if port is open
nc -zv 10.0.10.26 1883
```

**Verify Mosquitto is listening:**

```bash
# On MQTT container
ss -tlnp | grep 1883
```

### Authentication Failures

```bash
# Check password file exists and has correct permissions
ls -la /etc/mosquitto/passwd

# Test credentials locally
mosquitto_sub -h localhost -t test -u homeassistant -P YOUR_PASSWORD -d
```

**Check logs for specific error:**

```bash
tail -f /var/log/mosquitto/mosquitto.log
```

### High Resource Usage

MQTT is very lightweight. If seeing high CPU/RAM:

```bash
# Check for message loops or excessive traffic
mosquitto_sub -h localhost -t '#' -u homeassistant -P YOUR_PASSWORD -v | head -100

# Check connection count
ss -tn | grep :1883 | wc -l
```

## Part 11: Integration Examples

### 11.1 Basic Sensor in Home Assistant

```yaml
# configuration.yaml
mqtt:
  sensor:
    - name: "Temperature Sensor"
      state_topic: "home/sensor/temperature"
      unit_of_measurement: "°F"
      value_template: "{{ value_json.temperature }}"
```

**Publish test data:**

```bash
mosquitto_pub -h 10.0.10.26 -t home/sensor/temperature -m '{"temperature":72.5}' -u homeassistant -P YOUR_PASSWORD
```

### 11.2 MQTT Switch in Home Assistant

```yaml
# configuration.yaml
mqtt:
  switch:
    - name: "Test Switch"
      state_topic: "home/switch/test"
      command_topic: "home/switch/test/set"
      payload_on: "ON"
      payload_off: "OFF"
```

### 11.3 ESP8266/ESP32 Example (Arduino)

```cpp
#include <ESP8266WiFi.h>
#include <PubSubClient.h>

const char* ssid = "YourWiFi";
const char* password = "YourPassword";
const char* mqtt_server = "10.0.10.26";
const char* mqtt_user = "esphome";
const char* mqtt_password = "YOUR_PASSWORD";

WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
  client.setServer(mqtt_server, 1883);
}

void loop() {
  if (!client.connected()) {
    client.connect("ESP8266Client", mqtt_user, mqtt_password);
  }
  client.publish("home/sensor/esp", "Hello from ESP8266");
  delay(5000);
}
```

## Part 12: Performance Tuning

### 12.1 Connection Limits

Edit `/etc/mosquitto/mosquitto.conf`:

```conf
# Maximum simultaneous client connections
max_connections 100

# Maximum QoS 1 and 2 messages in flight
max_inflight_messages 20

# Maximum queued messages
max_queued_messages 1000
```

### 12.2 Memory Optimization

```conf
# Limit memory usage
memory_limit 256M

# Message size limit (bytes)
message_size_limit 1024000
```

## Network Diagram

```
┌─────────────────────────────────────────────┐
│         UCG Ultra (10.0.10.1)               │
│         Gateway / DNS / DHCP                │
└─────────────────┬───────────────────────────┘
                  │
      ┌───────────┼───────────────┬─────────────┐
      │           │               │             │
┌─────▼─────┐ ┌──▼──────────┐ ┌──▼──────┐ ┌───▼─────────┐
│ Home      │ │ MQTT Broker │ │ ESPHome │ │ Proxmox     │
│ Assistant │ │ 10.0.10.26  │ │.28      │ │ Nodes       │
│ .24       │ │ Mosquitto   │ │         │ │ .2, .3, .4  │
└───────────┘ └─────────────┘ └─────────┘ └─────────────┘
      │              │              │
      └──────────────┴──────────────┘
         MQTT Protocol (Port 1883)
     Topics: homeassistant/*, sensors/*
```

## Quick Reference

### Common Commands

```bash
# Service management
systemctl status mosquitto
systemctl restart mosquitto
systemctl stop mosquitto
systemctl start mosquitto

# View logs
journalctl -u mosquitto -f
tail -f /var/log/mosquitto/mosquitto.log

# User management
mosquitto_passwd /etc/mosquitto/passwd USERNAME

# Testing
mosquitto_sub -h 10.0.10.26 -t '#' -u USER -P PASS -v
mosquitto_pub -h 10.0.10.26 -t test -m "message" -u USER -P PASS
```

### Configuration Files

- **Main config:** `/etc/mosquitto/mosquitto.conf`
- **Passwords:** `/etc/mosquitto/passwd`
- **ACLs:** `/etc/mosquitto/acl`
- **Logs:** `/var/log/mosquitto/mosquitto.log`
- **Data:** `/var/lib/mosquitto/`

### Network Details

- **IP:** 10.0.10.26
- **Hostname:** mosquitto
- **MQTT Port:** 1883 (standard)
- **MQTT TLS Port:** 8883 (if configured)
- **WebSocket Port:** 9001 (if configured)

## Related Documentation

- [IP-ALLOCATION.md](IP-ALLOCATION.md) - Network IP plan (MQTT at .26)
- [SERVICES.md](SERVICES.md) - Service inventory
- [infrastructure-audit.md](infrastructure-audit.md) - Current infrastructure state
- [Home Assistant Documentation](https://www.home-assistant.io/integrations/mqtt/)
- [Mosquitto Documentation](https://mosquitto.org/documentation/)

## Security Best Practices

1. **Never use `allow_anonymous true` in production**
2. **Use strong passwords** for MQTT users (16+ characters)
3. **Enable TLS/SSL** if accessing over internet or untrusted networks
4. **Use ACLs** to limit user permissions
5. **Regular backups** of configuration and password files
6. **Monitor logs** for suspicious connection attempts
7. **Keep Mosquitto updated:** `apt update && apt upgrade mosquitto`

## Future Enhancements

- [ ] Configure TLS encryption for external access
- [ ] Set up Mosquitto bridge to cloud MQTT broker (if needed)
- [ ] Integrate with Authentik SSO (when deployed at 10.0.10.21)
- [ ] Add to Prometheus/Grafana monitoring (when deployed at 10.0.10.25)
- [ ] Configure message retention policies
- [ ] Set up MQTT-based automation scripts

---

**Last Updated:** 2025-11-18
**Status:** Ready for deployment
**Priority:** Medium (required for Home Assistant IoT integrations)
**Deployment Location:** pve-router (10.0.10.2)
**Resource Requirements:** 1 CPU core, 512MB RAM, 2GB storage
