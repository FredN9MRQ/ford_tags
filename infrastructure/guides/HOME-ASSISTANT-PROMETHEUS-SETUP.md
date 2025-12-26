# Home Assistant Prometheus Integration Setup

**Quick Guide: 5 Minutes**

---

## 🎯 What This Does

Exposes Home Assistant metrics to Prometheus for monitoring:
- Sensor states and values
- Device availability
- Automation execution
- System health

---

## 📋 Step-by-Step Setup

### Step 1: Enable Prometheus in Home Assistant (2 ways)

**Option A: Via Configuration File (Easier)**

1. Open File Editor in Home Assistant: http://10.0.10.24:8123
2. Click on the folder icon → `configuration.yaml`
3. Add this line anywhere in the file:
   ```yaml
   prometheus:
   ```
4. Save the file
5. Go to Developer Tools → YAML → "Check Configuration"
6. If valid, click "Restart Home Assistant"

**Option B: Via UI Integration**

1. Settings → Devices & Services
2. Click "+ Add Integration"
3. Search for "Prometheus"
4. Click to enable
5. Done!

### Step 2: Create Long-Lived Access Token

1. Click your profile icon (bottom left)
2. Scroll down to **"Long-Lived Access Tokens"**
3. Click **"Create Token"**
4. Name: `Prometheus`
5. Click **"OK"**
6. **IMPORTANT:** Copy the token NOW (you won't see it again!)
7. Save it somewhere safe

The token will look like:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIxMjM0NTY3ODkwIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

### Step 3: Update Prometheus Configuration

1. SSH to your Proxmox host:
   ```bash
   ssh root@10.0.10.3
   ```

2. Edit Prometheus config:
   ```bash
   pct exec 125 -- nano /etc/prometheus/prometheus.yml
   ```

3. Find the `homeassistant` job section (around line 138-147)

4. Replace `YOUR_LONG_LIVED_ACCESS_TOKEN` with your actual token:
   ```yaml
   - job_name: 'homeassistant'
     metrics_path: '/api/prometheus'
     bearer_token: 'your_actual_token_here'
     static_configs:
       - targets: ['10.0.10.24:8123']
         labels:
           app: 'homeassistant'
           role: 'automation'
   ```

5. Save and exit (Ctrl+X, then Y, then Enter)

6. Restart Prometheus:
   ```bash
   pct exec 125 -- systemctl restart prometheus
   ```

### Step 4: Verify It's Working

1. Go to Prometheus: http://10.0.10.25:9090
2. Click **Status → Targets**
3. Look for **homeassistant** in the list
4. Status should be **UP** (green)

**If it's DOWN:**
- Check the token is correct
- Verify Home Assistant restarted after enabling Prometheus
- Check HA is accessible: `curl http://10.0.10.24:8123/api/prometheus`

---

## 🎨 Grafana Dashboards for Home Assistant

Once working, import these dashboards:

**Popular HA Dashboards:**
- **11455** - Home Assistant Prometheus Dashboard
- **17310** - Home Assistant System Monitor
- **13630** - Home Assistant Overview

**To Import:**
1. Grafana: http://10.0.10.25:3000
2. Login as fred@nianticbooks.com
3. Dashboards → Import
4. Enter dashboard ID
5. Select "Prometheus" datasource
6. Click Import

---

## 📊 What Metrics You'll See

**Sensors:**
- Temperature sensors
- Humidity sensors
- Power usage
- Battery levels

**System:**
- CPU/Memory usage
- Disk space
- Uptime

**Automation:**
- Automation triggers
- Script executions
- Device states

**Devices:**
- Online/offline status
- Last seen timestamps
- Entity states

---

## 🔧 Troubleshooting

### "401 Unauthorized" Error

**Problem:** Prometheus can't authenticate to Home Assistant

**Fix:**
1. Verify token is correct in prometheus.yml
2. Check token hasn't expired (shouldn't for long-lived tokens)
3. Restart Prometheus after config changes

### "Connection Refused" Error

**Problem:** Prometheus can't reach Home Assistant

**Fix:**
1. Verify Home Assistant is running: `curl http://10.0.10.24:8123`
2. Check firewall isn't blocking port 8123
3. Verify IP address is correct

### No Metrics Showing

**Problem:** Prometheus connects but no data

**Fix:**
1. Check Prometheus integration is enabled in HA
2. Verify configuration.yaml has `prometheus:` line
3. Restart Home Assistant
4. Wait 1-2 minutes for first scrape

### "Prometheus not found" in HA

**Problem:** Integration doesn't appear

**Fix:**
- HA version might be too old (needs 2021.10+)
- Try manual config file method instead of UI

---

## 💡 Advanced: Filter What Gets Exported

By default, ALL entities are exported. To filter:

**In configuration.yaml:**
```yaml
prometheus:
  # Only export these domains
  filter:
    include_domains:
      - sensor
      - switch
      - light
    exclude_entities:
      - sensor.example_noisy_sensor
```

**Or include specific entities:**
```yaml
prometheus:
  filter:
    include_entities:
      - sensor.living_room_temperature
      - sensor.bedroom_humidity
      - switch.christmas_lights
```

---

## 🔒 Security Note

**Long-Lived Access Tokens:**
- Never commit to git
- Never share publicly
- Store in password manager
- Rotate if compromised

**To Revoke a Token:**
1. Profile → Long-Lived Access Tokens
2. Click trash icon next to token
3. Confirm deletion
4. Update Prometheus config with new token

---

## ✅ Quick Checklist

- [ ] Prometheus integration enabled in Home Assistant
- [ ] Home Assistant restarted
- [ ] Long-lived access token created
- [ ] Token saved securely
- [ ] prometheus.yml updated with token
- [ ] Prometheus restarted
- [ ] Target showing "UP" in Prometheus
- [ ] Metrics visible in Prometheus query
- [ ] Grafana dashboard imported (optional)

---

## 📚 Reference

**Docs:**
- https://www.home-assistant.io/integrations/prometheus/
- https://prometheus.io/docs/prometheus/latest/configuration/configuration/

**Prometheus Config Location:**
```
/etc/prometheus/prometheus.yml (on container 125 at 10.0.10.25)
```

**Metrics Endpoint:**
```
http://10.0.10.24:8123/api/prometheus
```

**Test Query in Prometheus:**
```
homeassistant_sensor_temperature_celsius
```

---

**Last Updated:** 2025-12-25
