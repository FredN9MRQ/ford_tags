# Local HTTPS Quick Start Guide

Get all your homelab services running on HTTPS in ~30 minutes.

## What This Does

Converts all your internal services from HTTP to HTTPS:
- ✅ Home Assistant (bob.nianticbooks.home)
- ✅ AD5M 3D Printer (ad5m.nianticbooks.home)
- ✅ Dockge (dockge.nianticbooks.home)
- ✅ Proxmox Web UI (freddesk.nianticbooks.home)
- ✅ OpenMediaVault (omv.nianticbooks.home)

## Prerequisites

- SSH access to main-pve (10.0.10.3) as root
- DNS entries configured in UCG Ultra for all services
- ~2GB free space on main-pve

## Step-by-Step Instructions

### 1. Set Up Certificate Authority (10 min)

SSH into main-pve and run the setup script:

```bash
# From this computer
scp ~/projects/infrastructure/scripts/setup-local-ca.sh root@10.0.10.3:/root/

# SSH into main-pve
ssh root@10.0.10.3

# Run setup
cd /root
chmod +x setup-local-ca.sh
./setup-local-ca.sh
```

**What it does:**
- Creates LXC container at 10.0.10.15
- Installs step-ca (Certificate Authority software)
- Initializes CA with 10-year root certificate
- Starts CA service

**You'll be prompted for:**
- CA password (save this in your password manager!)
- Container root password

### 2. Issue Certificates for All Services (5 min)

Still on main-pve:

```bash
# Copy and run certificate generation script
scp ~/projects/infrastructure/scripts/issue-service-certs.sh root@10.0.10.3:/root/

# On main-pve
chmod +x issue-service-certs.sh
./issue-service-certs.sh
```

**What it does:**
- Generates SSL certificates for all services
- Saves them to `/tmp/certs/` on main-pve

**Output:**
```
/tmp/certs/
├── bob.nianticbooks.home.crt
├── bob.nianticbooks.home.key
├── ad5m.nianticbooks.home.crt
├── ad5m.nianticbooks.home.key
└── ... (other services)
```

### 3. Configure Each Service (15 min)

#### Home Assistant (bob.nianticbooks.home)

```bash
# On main-pve, copy certs to Home Assistant
scp /tmp/certs/bob.nianticbooks.home.* root@10.0.10.24:/config/ssl/

# SSH into Home Assistant
ssh root@10.0.10.24

# Edit configuration
nano /config/configuration.yaml
```

Add/update:
```yaml
http:
  ssl_certificate: /config/ssl/bob.nianticbooks.home.crt
  ssl_key: /config/ssl/bob.nianticbooks.home.key
  server_port: 8123
```

Restart Home Assistant:
```bash
# From HA CLI
ha core restart

# Or restart container/VM from Proxmox
```

Test: https://bob.nianticbooks.home:8123

#### AD5M Printer (Fluidd/Klipper)

```bash
# Copy certs to printer
scp /tmp/certs/ad5m.nianticbooks.home.* root@10.0.10.30:/etc/nginx/ssl/

# SSH into printer
ssh root@10.0.10.30

# Create nginx HTTPS config
cat > /etc/nginx/sites-available/fluidd-https <<'EOF'
server {
    listen 443 ssl http2;
    server_name ad5m.nianticbooks.home;

    ssl_certificate /etc/nginx/ssl/ad5m.nianticbooks.home.crt;
    ssl_certificate_key /etc/nginx/ssl/ad5m.nianticbooks.home.key;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support for Moonraker
    location /websocket {
        proxy_pass http://127.0.0.1:7125/websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name ad5m.nianticbooks.home;
    return 301 https://$server_name$request_uri;
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/fluidd-https /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

Test: https://ad5m.nianticbooks.home

Update printer UI setting to: `https://ad5m.nianticbooks.home/fluidd`

#### Dockge

```bash
# Copy certs
scp /tmp/certs/dockge.nianticbooks.home.* root@10.0.10.27:/opt/dockge/ssl/

# Edit docker-compose.yml to add SSL
```

Add environment variables:
```yaml
environment:
  - SSL_KEY=/app/ssl/dockge.nianticbooks.home.key
  - SSL_CERT=/app/ssl/dockge.nianticbooks.home.crt
```

Or use nginx reverse proxy (recommended).

#### Proxmox (freddesk.nianticbooks.home)

```bash
# On main-pve
cp /tmp/certs/freddesk.nianticbooks.home.crt /etc/pve/local/pveproxy-ssl.pem
cp /tmp/certs/freddesk.nianticbooks.home.key /etc/pve/local/pveproxy-ssl.key

# Restart Proxmox web service
systemctl restart pveproxy
```

Test: https://freddesk.nianticbooks.home:8006

#### OpenMediaVault

```bash
# Copy certs to OMV
scp /tmp/certs/omv.nianticbooks.home.* root@10.0.10.5:/etc/ssl/

# Configure via OMV Web UI:
# System → Certificates → SSL → Import
# Then: System → General Settings → Enable SSL/TLS, select certificate
```

### 4. Trust the CA on Your Devices (5 min)

#### This Computer (Linux)

```bash
cd ~/projects/infrastructure/scripts
./trust-ca-client.sh
```

#### Other Linux Computers

```bash
# Copy script and run
scp scripts/trust-ca-client.sh user@other-computer:/tmp/
ssh user@other-computer "bash /tmp/trust-ca-client.sh"
```

#### Windows

1. Copy root CA from main-pve:
   ```bash
   scp root@10.0.10.3:/tmp/homelab-root-ca.crt ~/Downloads/
   ```

2. On Windows:
   - Copy file to Windows machine
   - Right-click → Install Certificate
   - Store Location: **Local Machine**
   - Certificate Store: **Trusted Root Certification Authorities**
   - Click Finish

#### macOS

```bash
# Copy certificate
scp root@10.0.10.3:/tmp/homelab-root-ca.crt ~/Downloads/

# Install (will prompt for password)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/Downloads/homelab-root-ca.crt
```

#### iOS

1. Email the certificate to yourself or host on a web server
2. Open the certificate file on iOS device
3. Settings → General → VPN & Device Management → Install profile
4. Settings → General → About → Certificate Trust Settings
5. Enable full trust for "Homelab Internal CA"

#### Android

1. Transfer certificate to device
2. Settings → Security → Install from storage
3. Select the certificate file
4. Name it "Homelab CA"

## Verification

Test all services with HTTPS:

```bash
# From any trusted computer
curl -I https://bob.nianticbooks.home:8123
curl -I https://ad5m.nianticbooks.home
curl -I https://freddesk.nianticbooks.home:8006
curl -I https://omv.nianticbooks.home
```

Open in browser - you should see **no certificate warnings**.

## Troubleshooting

### Certificate not trusted

```bash
# Check if CA is installed
ls /usr/local/share/ca-certificates/ | grep homelab

# Re-run trust script
cd ~/projects/infrastructure/scripts
./trust-ca-client.sh
```

### Service won't start with HTTPS

```bash
# Check certificate files exist
ls -la /path/to/ssl/

# Check permissions
chmod 644 /path/to/cert.crt
chmod 600 /path/to/cert.key

# Check service logs
journalctl -u service-name -f
```

### Certificate expired (after 1 year)

```bash
# Re-run certificate issuance
ssh root@10.0.10.3
./issue-service-certs.sh

# Re-deploy to services
```

## Certificate Renewal

Certificates are valid for 1 year. Set a calendar reminder to renew them annually:

```bash
# On main-pve
./issue-service-certs.sh
# Then re-deploy to each service
```

Or set up auto-renewal (see full documentation in LOCAL-CA-SETUP.md).

## Next Steps

Once HTTPS is working:

1. Update Pangolin routes on VPS to use HTTPS backends
2. Configure HTTP → HTTPS redirects
3. Update bookmarks to use `https://`
4. Update Home Assistant app to use HTTPS URL

## Files Created

- `/tmp/homelab-root-ca.crt` - Root CA certificate (install on all devices)
- `/tmp/certs/*.crt` - Service certificates
- `/tmp/certs/*.key` - Private keys (keep secure!)

## Security Notes

- Root CA is valid for 10 years
- Service certificates valid for 1 year
- Private keys stored only on CA server and target services
- CA server only accessible from local network (10.0.10.0/24)

## Support

Full documentation: `LOCAL-CA-SETUP.md`
Troubleshooting: Check service logs and certificate validity

---

**Time Estimate:** 30-45 minutes for complete setup
**Difficulty:** Intermediate
**Impact:** All services accessible via trusted HTTPS
