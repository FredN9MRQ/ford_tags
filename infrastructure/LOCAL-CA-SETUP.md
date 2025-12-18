# Local Certificate Authority Setup

This document describes the setup of a local Certificate Authority (CA) for issuing HTTPS certificates to internal services.

## Overview

**Problem:** Internal services (Home Assistant, AD5M printer, Dockge, etc.) use HTTP, causing:
- Browser security warnings
- Some services refuse to work without HTTPS
- Insecure credential transmission

**Solution:** Local CA using `step-ca` that issues trusted certificates for `.nianticbooks.home` domain.

## Architecture

### CA Server Location
- **Host:** main-pve (10.0.10.3) - most reliable server
- **Container:** LXC container for isolation
- **IP:** 10.0.10.15 (reserved for ca-server)
- **Domain:** ca.nianticbooks.home

### Services Requiring Certificates

| Service | Current IP | Domain | Port |
|---------|-----------|---------|------|
| Home Assistant | 10.0.10.24 | bob.nianticbooks.home | 8123 |
| AD5M Printer | 10.0.10.30 | ad5m.nianticbooks.home | 80 |
| Dockge | 10.0.10.27 | dockge.nianticbooks.home | 5001 |
| Proxmox (main-pve) | 10.0.10.3 | freddesk.nianticbooks.home | 8006 |
| Proxmox (pve-router) | 10.0.10.2 | pve-router.nianticbooks.home | 8006 |
| OMV | 10.0.10.5 | omv.nianticbooks.home | 80 |

## Implementation Plan

### Phase 1: CA Server Setup

1. Create LXC container on main-pve
2. Install step-ca
3. Initialize CA with:
   - CA name: "Homelab Internal CA"
   - Domain: nianticbooks.home
   - Validity: 10 years (root), 1 year (leaf certificates)

### Phase 2: Certificate Generation

For each service, generate:
- Server certificate
- Private key
- Auto-renewal script

### Phase 3: Service Configuration

Configure each service to:
- Use generated certificate
- Listen on HTTPS port
- Optionally redirect HTTP → HTTPS

### Phase 4: Client Trust

Distribute root CA certificate to:
- Linux clients (this computer, servers)
- Windows clients
- macOS clients
- Mobile devices (iOS/Android)

## Step-by-Step Implementation

### 1. Create CA Server Container

```bash
# On main-pve (10.0.10.3)
pct create 115 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname ca-server \
  --cores 1 \
  --memory 512 \
  --swap 512 \
  --storage local-lvm \
  --rootfs 8 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.10.15/24,gw=10.0.10.1 \
  --unprivileged 1 \
  --features nesting=1 \
  --onboot 1

# Start container
pct start 115

# Enter container
pct enter 115
```

### 2. Install step-ca

```bash
# Inside container
apt update && apt install -y wget

# Download step-ca
wget https://dl.smallstep.com/gh-release/cli/gh-release-header/v0.25.0/step-cli_0.25.0_amd64.deb
wget https://dl.smallstep.com/gh-release/certificates/gh-release-header/v0.25.0/step-ca_0.25.0_amd64.deb

# Install
dpkg -i step-cli_0.25.0_amd64.deb step-ca_0.25.0_amd64.deb

# Verify
step version
step-ca version
```

### 3. Initialize CA

```bash
# Create CA user
useradd -r -s /bin/bash -m -d /etc/step-ca step

# Initialize CA (as step user)
su - step
step ca init

# Configuration prompts:
# Name: Homelab Internal CA
# DNS: ca.nianticbooks.home
# Address: :443
# Provisioner: admin@nianticbooks.home
# Password: [generate strong password, save to password manager]
```

### 4. Configure CA Service

```bash
# Create systemd service
cat > /etc/systemd/system/step-ca.service <<'EOF'
[Unit]
Description=step-ca Certificate Authority
After=network.target

[Service]
Type=simple
User=step
Group=step
WorkingDirectory=/etc/step-ca
ExecStart=/usr/bin/step-ca /etc/step-ca/config/ca.json --password-file=/etc/step-ca/password.txt
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Store CA password securely
echo "YOUR_CA_PASSWORD" > /etc/step-ca/password.txt
chown step:step /etc/step-ca/password.txt
chmod 600 /etc/step-ca/password.txt

# Enable and start
systemctl daemon-reload
systemctl enable step-ca
systemctl start step-ca
systemctl status step-ca
```

### 5. Issue Certificates for Services

#### Home Assistant (bob.nianticbooks.home)

```bash
# Generate certificate
step certificate create bob.nianticbooks.home \
  bob.crt bob.key \
  --profile leaf \
  --not-after 8760h \
  --ca /etc/step-ca/certs/intermediate_ca.crt \
  --ca-key /etc/step-ca/secrets/intermediate_ca_key \
  --bundle

# Copy to Home Assistant
scp bob.crt bob.key homeassistant.local:/ssl/
```

Configure Home Assistant (`configuration.yaml`):
```yaml
http:
  ssl_certificate: /ssl/bob.crt
  ssl_key: /ssl/bob.key
  server_port: 8123
```

#### AD5M Printer (Fluidd/Klipper)

```bash
step certificate create ad5m.nianticbooks.home \
  ad5m.crt ad5m.key \
  --profile leaf \
  --not-after 8760h \
  --ca /etc/step-ca/certs/intermediate_ca.crt \
  --ca-key /etc/step-ca/secrets/intermediate_ca_key \
  --bundle

# Copy to printer
scp ad5m.crt ad5m.key root@10.0.10.30:/etc/nginx/ssl/
```

Configure nginx for Fluidd:
```nginx
server {
    listen 443 ssl;
    server_name ad5m.nianticbooks.home;

    ssl_certificate /etc/nginx/ssl/ad5m.crt;
    ssl_certificate_key /etc/nginx/ssl/ad5m.key;

    location / {
        proxy_pass http://localhost:80;
    }
}
```

#### Dockge

```bash
step certificate create dockge.nianticbooks.home \
  dockge.crt dockge.key \
  --profile leaf \
  --not-after 8760h \
  --ca /etc/step-ca/certs/intermediate_ca.crt \
  --ca-key /etc/step-ca/secrets/intermediate_ca_key \
  --bundle

# Copy to Dockge host
```

#### Proxmox

```bash
# Main PVE
step certificate create freddesk.nianticbooks.home \
  freddesk.crt freddesk.key \
  --profile leaf \
  --not-after 8760h \
  --ca /etc/step-ca/certs/intermediate_ca.crt \
  --ca-key /etc/step-ca/secrets/intermediate_ca_key \
  --bundle

# Copy to Proxmox
scp freddesk.crt freddesk.key root@10.0.10.3:/etc/pve/local/pveproxy-ssl.pem
scp freddesk.key root@10.0.10.3:/etc/pve/local/pveproxy-ssl.key

# Restart Proxmox web service
ssh root@10.0.10.3 "systemctl restart pveproxy"
```

### 6. Certificate Auto-Renewal

Create renewal script on CA server:

```bash
cat > /usr/local/bin/renew-certs.sh <<'EOF'
#!/bin/bash
# Auto-renew certificates for homelab services

SERVICES=(
  "bob.nianticbooks.home:10.0.10.24:/ssl/"
  "ad5m.nianticbooks.home:10.0.10.30:/etc/nginx/ssl/"
  "dockge.nianticbooks.home:10.0.10.27:/etc/ssl/"
  "freddesk.nianticbooks.home:10.0.10.3:/etc/pve/local/"
)

for service in "${SERVICES[@]}"; do
  IFS=':' read -r domain ip path <<< "$service"

  echo "Renewing certificate for $domain..."

  # Check if certificate expires in < 30 days
  if step certificate needs-renewal "${domain}.crt"; then
    # Generate new certificate
    step certificate create "$domain" \
      "${domain}.crt" "${domain}.key" \
      --profile leaf \
      --not-after 8760h \
      --ca /etc/step-ca/certs/intermediate_ca.crt \
      --ca-key /etc/step-ca/secrets/intermediate_ca_key \
      --bundle --force

    # Deploy to service
    scp "${domain}.crt" "${domain}.key" "root@${ip}:${path}"

    # Restart service
    case "$domain" in
      bob.*)
        ssh root@${ip} "systemctl restart home-assistant@homeassistant"
        ;;
      ad5m.*)
        ssh root@${ip} "systemctl restart nginx"
        ;;
      freddesk.*)
        ssh root@${ip} "systemctl restart pveproxy"
        ;;
    esac

    echo "✓ Renewed $domain"
  fi
done
EOF

chmod +x /usr/local/bin/renew-certs.sh

# Add to crontab (weekly check)
echo "0 2 * * 0 /usr/local/bin/renew-certs.sh" >> /etc/crontab
```

### 7. Client Trust Configuration

#### Linux (Ubuntu/Debian)

```bash
# Copy root CA certificate
scp root@10.0.10.15:/etc/step-ca/certs/root_ca.crt /usr/local/share/ca-certificates/homelab-ca.crt

# Update trust store
update-ca-certificates

# Verify
curl https://bob.nianticbooks.home:8123
```

#### Windows

1. Copy `root_ca.crt` to Windows machine
2. Right-click → Install Certificate
3. Store Location: Local Machine
4. Certificate Store: Trusted Root Certification Authorities
5. Click Next → Finish

#### macOS

```bash
# Copy certificate
scp root@10.0.10.15:/etc/step-ca/certs/root_ca.crt ~/Downloads/

# Import to keychain
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/Downloads/root_ca.crt
```

#### iOS/Android

1. Email `root_ca.crt` to device or host on web server
2. Open certificate file on device
3. Install profile
4. iOS: Settings → General → About → Certificate Trust Settings → Enable
5. Android: Settings → Security → Install from storage

## DNS Configuration

Ensure UCG Ultra has DNS entries for all services:

```
bob.nianticbooks.home → 10.0.10.24
ad5m.nianticbooks.home → 10.0.10.30
dockge.nianticbooks.home → 10.0.10.27
freddesk.nianticbooks.home → 10.0.10.3
pve-router.nianticbooks.home → 10.0.10.2
omv.nianticbooks.home → 10.0.10.5
ca.nianticbooks.home → 10.0.10.15
```

## Verification

Test each service:

```bash
# Home Assistant
curl -I https://bob.nianticbooks.home:8123

# AD5M
curl -I https://ad5m.nianticbooks.home

# Dockge
curl -I https://dockge.nianticbooks.home:5001

# Proxmox
curl -I https://freddesk.nianticbooks.home:8006
```

## Troubleshooting

### Certificate Not Trusted

```bash
# Check if CA is in trust store
ls /usr/local/share/ca-certificates/

# Verify certificate chain
openssl s_client -connect bob.nianticbooks.home:8123 -showcerts

# Check certificate validity
openssl x509 -in bob.crt -text -noout
```

### Service Won't Start with HTTPS

```bash
# Check certificate permissions
ls -la /ssl/

# Check service logs
journalctl -u home-assistant@homeassistant -f

# Verify certificate matches key
openssl x509 -noout -modulus -in cert.crt | openssl md5
openssl rsa -noout -modulus -in cert.key | openssl md5
# Should match
```

## Maintenance

### Certificate Expiry Monitoring

```bash
# Check certificate expiration
for cert in *.crt; do
  echo "$cert:"
  openssl x509 -in "$cert" -noout -dates
done
```

### Renewing Root CA

Root CA expires in 10 years. To renew:

1. Generate new root CA
2. Issue new intermediate CA
3. Re-issue all service certificates
4. Update all client trust stores

## Security Considerations

- CA private key stored encrypted on CA server
- CA server only accessible from local network
- Certificate validity limited to 1 year
- Auto-renewal prevents expiry
- Root CA backed up to OMV storage

## Backup

```bash
# Backup CA configuration
rsync -av /etc/step-ca/ /mnt/omv-backup/ca-backup/$(date +%Y%m%d)/

# Store root CA password in password manager
```

## Next Steps

- [ ] Create CA server LXC container
- [ ] Install and configure step-ca
- [ ] Generate certificates for all services
- [ ] Configure services to use HTTPS
- [ ] Distribute root CA to all devices
- [ ] Set up auto-renewal
- [ ] Test all services with HTTPS
- [ ] Update Pangolin routes to use HTTPS backend
