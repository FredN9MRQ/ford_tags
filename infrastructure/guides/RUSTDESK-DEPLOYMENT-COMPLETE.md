# RustDesk Self-Hosted Server - Deployment Complete

**Deployed:** 2025-12-25
**Status:** ✅ OPERATIONAL

---

## 🎉 Deployment Summary

Your self-hosted RustDesk remote desktop infrastructure is **LIVE**!

### Architecture

```
Internet
    │
    ├─> VPS (66.63.182.168)
    │   └─> hbbr (Relay Server) - Port 21117
    │       - Handles NAT traversal
    │       - Relays connections when direct P2P fails
    │
    └─> WireGuard Tunnel
        └─> Home Lab (10.0.10.0/24)
            └─> RustDesk Server (10.0.10.23)
                └─> hbbs (ID/Rendezvous Server)
                    - Port 21115: NAT type test
                    - Port 21116: ID/Rendezvous service
                    - Port 21117: Relay service (points to VPS)
                    - Port 21118: TCP hole punching
```

---

## ✅ Server Status

### ID Server (hbbs) - Home Lab
- **Location:** LXC Container 123 on main-pve
- **IP:** 10.0.10.23
- **Version:** 1.1.14
- **Status:** ✅ Active (running)
- **Ports:**
  - 21115/TCP - NAT type test
  - 21116/TCP+UDP - ID/Rendezvous
  - 21118/TCP - TCP hole punching

**Check status:**
```bash
ssh root@10.0.10.3
pct exec 123 -- systemctl status rustdesk-hbbs
```

### Relay Server (hbbr) - VPS
- **Location:** VPS (66.63.182.168)
- **Version:** 1.1.14
- **Status:** ✅ Active (running)
- **Port:** 21117/TCP - Relay service

**Check status:**
```bash
ssh 66.63.182.168
sudo systemctl status rustdesk-hbbr
```

---

## 🔑 Encryption Key

**Public Key (for clients):**
```
sfYuCTMHxrA22kukomb/RAKYyUgr8iaMfm/U4CFLfL0=
```

⚠️ **IMPORTANT:** Keep this key safe! You'll need it to configure every RustDesk client.

**Secret Key Location:** `/opt/rustdesk/` on both servers (automatically used)

---

## 💻 Client Configuration

### Step 1: Install RustDesk Client

**Download from:** https://rustdesk.com/

**Supported platforms:**
- Windows
- macOS
- Linux
- iOS
- Android

### Step 2: Configure Client

After installing, configure the client to use your server:

**Option A: GUI Configuration**

1. Open RustDesk
2. Click the **⚙️ Settings** icon (next to your ID)
3. Click **Network** tab
4. Click **ID Server** field
5. Enter: `66.63.182.168`
6. Click **Key** field
7. Paste: `sfYuCTMHxrA22kukomb/RAKYyUgr8iaMfm/U4CFLfL0=`
8. **Relay Server** should auto-fill, but verify it's: `66.63.182.168`
9. Click **Apply** or **OK**
10. Restart RustDesk

**Option B: Manual Config File** (Advanced)

**Windows:**
```
C:\Users\<username>\AppData\Roaming\RustDesk\config\RustDesk2.toml
```

**Linux:**
```
~/.config/rustdesk/RustDesk2.toml
```

**macOS:**
```
~/Library/Preferences/RustDesk2.toml
```

**Add these lines:**
```toml
relay-server = '66.63.182.168:21117'
id-server = '66.63.182.168'
key = 'sfYuCTMHxrA22kukomb/RAKYyUgr8iaMfm/U4CFLfL0='
```

### Step 3: Test Connection

1. Open RustDesk on two devices
2. Note the **RustDesk ID** on the controlled device
3. On the controlling device:
   - Enter the remote ID
   - Click **Connect**
   - Enter the password shown on the remote device
4. Connection should establish!

---

## 🌐 Access Methods

### From Inside Network (10.0.10.0/24)
- **ID Server:** 10.0.10.23
- **Relay:** 66.63.182.168 (via WireGuard)
- **Clients:** Use VPS IP (66.63.182.168)

### From Internet (Road Warrior)
- **Both:** 66.63.182.168
- **Requires:** VPS ports open (should be by default)

---

## 🔒 Security Considerations

### Current Security

✅ **Encryption:** End-to-end encrypted with your private key
✅ **Authentication:** Password required for each connection
✅ **Key-based:** Clients can only connect with your public key
✅ **Self-hosted:** No third-party relay servers

### Recommendations

**1. Firewall Rules (Optional - if you have strict firewall)**

**On VPS:**
```bash
# Allow RustDesk relay port
sudo ufw allow 21117/tcp comment 'RustDesk Relay'

# Check status
sudo ufw status
```

**On Proxmox host (if firewall enabled):**
```bash
# Allow RustDesk ports from your network
iptables -A INPUT -p tcp --dport 21115:21119 -s 10.0.10.0/24 -j ACCEPT
iptables -A INPUT -p udp --dport 21116 -s 10.0.10.0/24 -j ACCEPT
```

**2. Access Control**

- Use strong passwords on all devices
- Enable "Require click to accept" in RustDesk settings
- Disable unattended access if not needed
- Review RustDesk logs regularly

**3. Network Security**

- RustDesk uses P2P when possible (doesn't route through relay)
- Relay only used when direct connection fails
- All traffic is encrypted

---

## 🔧 Management & Maintenance

### View Logs

**ID Server:**
```bash
ssh root@10.0.10.3
pct exec 123 -- journalctl -u rustdesk-hbbs -f
```

**Relay Server:**
```bash
ssh 66.63.182.168
sudo journalctl -u rustdesk-hbbr -f
```

### Restart Services

**ID Server:**
```bash
ssh root@10.0.10.3
pct exec 123 -- systemctl restart rustdesk-hbbs
```

**Relay Server:**
```bash
ssh 66.63.182.168
sudo systemctl restart rustdesk-hbbr
```

### Update RustDesk Server

When a new version is released:

**ID Server:**
```bash
ssh root@10.0.10.3
pct exec 123 -- bash -c '
  cd /opt/rustdesk
  systemctl stop rustdesk-hbbs
  wget https://github.com/rustdesk/rustdesk-server/releases/latest/download/rustdesk-server-linux-amd64.zip
  unzip -o rustdesk-server-linux-amd64.zip
  mv amd64/hbbs .
  chmod +x hbbs
  systemctl start rustdesk-hbbs
  ./hbbs --version
'
```

**Relay Server:**
```bash
ssh 66.63.182.168
sudo bash -c '
  cd /opt/rustdesk
  systemctl stop rustdesk-hbbr
  cd /tmp
  wget https://github.com/rustdesk/rustdesk-server/releases/latest/download/rustdesk-server-linux-amd64.zip
  unzip -o rustdesk-server-linux-amd64.zip
  mv amd64/hbbr /opt/rustdesk/
  chmod +x /opt/rustdesk/hbbr
  systemctl start rustdesk-hbbr
  /opt/rustdesk/hbbr --version
'
```

---

## 📊 Monitoring

### Check Server Health

**Quick Status:**
```bash
# ID Server
ssh root@10.0.10.3 'pct exec 123 -- systemctl is-active rustdesk-hbbs'

# Relay Server
ssh 66.63.182.168 'sudo systemctl is-active rustdesk-hbbr'
```

### Monitor Connections

**ID Server Logs:**
```bash
ssh root@10.0.10.3
pct exec 123 -- journalctl -u rustdesk-hbbs --since "1 hour ago"
```

**Look for:**
- Client registrations
- Connection attempts
- Errors or warnings

### Add to Prometheus (Optional)

RustDesk doesn't expose metrics by default, but you can monitor:
- Process health (via node_exporter)
- Port availability (via blackbox_exporter)
- Log analysis (via Loki)

---

## 🚨 Troubleshooting

### Client can't connect to server

**Check:**
1. Server is running: `systemctl status rustdesk-hbbs`
2. Ports are open: `ss -tulnp | grep 211`
3. Client config is correct (ID server = 66.63.182.168)
4. Public key matches exactly (no extra spaces)
5. Internet connection on both client and server

**Test connectivity:**
```bash
# From client machine
nc -zv 66.63.182.168 21116
nc -zv 66.63.182.168 21117
```

### Connection works but is slow

**Likely cause:** Using relay instead of P2P

**Check:**
1. Both devices behind NAT? (Relay is necessary)
2. Firewall blocking UDP? (Needed for P2P)
3. Network conditions (high latency to VPS)

**Solution:**
- Enable UPnP on routers if possible
- Configure port forwarding for direct P2P
- Consider local-only mode if both devices on same network

### "Invalid ID Server" error

**Fix:**
1. Check ID server is running
2. Verify you're using IP, not domain
3. Try without port: `66.63.182.168` (not `66.63.182.168:21116`)
4. Restart RustDesk client after configuration

### Can't generate new key

**Error:** "Key already exists"

**Fix:**
```bash
ssh root@10.0.10.3
pct exec 123 -- bash -c 'cd /opt/rustdesk && rm -f id_ed25519* && ./rustdesk-utils genkeypair'
```

⚠️ **WARNING:** All clients must be reconfigured with new key!

---

## 📱 Mobile Setup

### iOS

1. Install RustDesk from App Store
2. Tap ⚙️ Settings
3. Tap **ID/Relay Server**
4. Enter ID Server: `66.63.182.168`
5. Paste Key: `sfYuCTMHxrA22kukomb/RAKYyUgr8iaMfm/U4CFLfL0=`
6. Tap Save
7. Restart app

### Android

1. Install RustDesk from Google Play
2. Tap ⚙️ Settings
3. Scroll to **ID Server**
4. Enter: `66.63.182.168`
5. Scroll to **Key**
6. Paste: `sfYuCTMHxrA22kukomb/RAKYyUgr8iaMfm/U4CFLfL0=`
7. Tap ✓ or Back
8. Restart app

---

## 💡 Advanced Features

### Unattended Access

1. On controlled device → Settings → Security
2. Enable **Enable Password**
3. Set a permanent password
4. Enable **Unattended Access**
5. On controlling device, save connection with password

### Address Book (Enterprise Feature)

RustDesk supports an address book server (requires paid version or self-hosted API server).

### File Transfer

- Enabled by default
- During session: Click **File Transfer** button
- Drag and drop or browse files
- Transfer is encrypted end-to-end

### Wake-on-LAN

- Configure WoL in target device's BIOS
- In RustDesk: Settings → Network → Wake-on-LAN
- Enter MAC address
- Click wake button before connecting

---

## 🔄 Backup & Recovery

### Backup Important Files

**ID Server:**
```bash
ssh root@10.0.10.3
pct exec 123 -- tar -czf /root/rustdesk-backup-$(date +%Y%m%d).tar.gz /opt/rustdesk/id_ed25519*
```

**Critical files:**
- `/opt/rustdesk/id_ed25519` - Private key
- `/opt/rustdesk/id_ed25519.pub` - Public key
- `/etc/systemd/system/rustdesk-hbbs.service` - Service config

### Disaster Recovery

**If ID server dies:**
1. Recreate container or VM
2. Reinstall RustDesk server
3. Restore `id_ed25519*` files to `/opt/rustdesk/`
4. Recreate systemd service
5. Start service

**If relay server dies:**
1. Reinstall on VPS (same process as initial setup)
2. No keys needed (hbbr doesn't use them)
3. Update hbbs to point to new relay IP (if changed)

**If you lose the keys:**
- ⚠️ Generate new keys
- Reconfigure ALL clients with new public key
- Old clients can't connect until updated

---

## 📈 Usage Statistics

**View connected clients:**
```bash
ssh root@10.0.10.3
pct exec 123 -- journalctl -u rustdesk-hbbs --since "today" | grep -i "new peer"
```

**Count connections today:**
```bash
ssh root@10.0.10.3
pct exec 123 -- journalctl -u rustdesk-hbbs --since "today" | grep -c "relay"
```

---

## 🎯 Next Steps (Optional)

### 1. Add Domain Name (Optional)

Instead of IP, use a domain:

**DNS:**
```
rustdesk.nianticbooks.com → 66.63.182.168
```

**Clients use:**
```
ID Server: rustdesk.nianticbooks.com
```

**Benefits:**
- Easier to remember
- Can change server IP without reconfiguring clients
- Looks more professional

### 2. Add to Caddy (Optional)

RustDesk doesn't use HTTP, but you can add health check endpoint:

```caddy
rustdesk.nianticbooks.com {
    respond /health 200 {
        body "RustDesk server running"
    }
}
```

### 3. Create Client Installer (Windows)

Pre-configure RustDesk for easy deployment:

1. Install RustDesk on a reference machine
2. Configure with your server settings
3. Copy configured files
4. Create installer script
5. Deploy to all machines

### 4. Integrate with Authentik (Future)

RustDesk supports OIDC authentication (Enterprise feature). Could integrate with your Authentik SSO!

---

## 📚 Resources

- **Official Docs:** https://rustdesk.com/docs/
- **GitHub:** https://github.com/rustdesk/rustdesk-server
- **Security:** https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/security/
- **FAQ:** https://github.com/rustdesk/rustdesk/wiki/FAQ

---

## 📋 Quick Reference Card

### Server Info
```
ID Server:     10.0.10.23 (internal) / 66.63.182.168 (public)
Relay Server:  66.63.182.168:21117
Public Key:    sfYuCTMHxrA22kukomb/RAKYyUgr8iaMfm/U4CFLfL0=
Version:       1.1.14
```

### Client Configuration
```
ID Server:     66.63.182.168
Key:           sfYuCTMHxrA22kukomb/RAKYyUgr8iaMfm/U4CFLfL0=
Relay:         66.63.182.168 (auto-configured)
```

### Common Commands
```bash
# Status
ssh root@10.0.10.3 'pct exec 123 -- systemctl status rustdesk-hbbs'

# Restart
ssh root@10.0.10.3 'pct exec 123 -- systemctl restart rustdesk-hbbs'

# Logs
ssh root@10.0.10.3 'pct exec 123 -- journalctl -u rustdesk-hbbs -f'

# Version
ssh root@10.0.10.3 'pct exec 123 -- /opt/rustdesk/hbbs --version'
```

---

**🎉 Your RustDesk server is ready!** Install clients and start remote controlling your devices!

**Last Updated:** 2025-12-25
