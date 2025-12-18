# HTTPS Setup - Current Status

**Date:** 2025-12-06
**Time Spent:** ~1.5 hours
**Status:** Certificate Authority set up, certificates generated, ready to deploy

## ✅ Completed

### 1. Certificate Authority Setup
- ✅ Created LXC container (ID: 115) on main-pve
- ✅ IP: 10.0.10.15 (ca.nianticbooks.home)
- ✅ Installed step-ca v0.25.0
- ✅ Initialized CA with 10-year root certificate
- ✅ Configured systemd service (auto-start on boot)
- ✅ CA is running and accessible

**CA Details:**
- Name: Homelab Internal CA
- Domain: ca.nianticbooks.home
- Root Fingerprint: `97629543809bb0a6571d6eca45dadfb286bedb20dc6cedb2b20bacdd3514343f`
- Password: `homelab123` (stored in `/etc/step-ca/.step/password.txt`)

### 2. Certificates Generated

All certificates valid for 1 year (8760 hours):

| Service | Domain | Status |
|---------|--------|--------|
| Home Assistant | bob.nianticbooks.home | ✅ Generated |
| AD5M Printer | ad5m.nianticbooks.home | ✅ Generated |
| Dockge | dockge.nianticbooks.home | ✅ Generated |
| Proxmox (main) | freddesk.nianticbooks.home | ✅ Generated |
| Proxmox (router) | pve-router.nianticbooks.home | ✅ Generated |
| OpenMediaVault | omv.nianticbooks.home | ✅ Generated |

**Certificate Location:** `~/certs/`

Files:
- `<domain>.crt` - Certificate (includes intermediate CA)
- `<domain>.key` - Private key
- `homelab-root-ca.crt` - Root CA certificate (for client trust)

## 🔄 Next Steps

### Immediate (Tonight/Tomorrow)

#### 1. Trust the CA on This Computer

```bash
sudo ~/install-ca-trust.sh
```

This installs the root CA so your browser trusts it.

#### 2. Configure Home Assistant for HTTPS

```bash
# Copy certificates to Home Assistant
scp ~/certs/bob.crt ~/certs/bob.key root@10.0.10.24:/config/ssl/

# SSH into Home Assistant and edit configuration
ssh root@10.0.10.24

# Add to /config/configuration.yaml:
http:
  ssl_certificate: /config/ssl/bob.crt
  ssl_key: /config/ssl/bob.key
  server_port: 8123

# Restart Home Assistant
ha core restart
```

Test: https://bob.nianticbooks.home:8123

#### 3. Configure AD5M Printer for HTTPS

```bash
# Copy certificates to printer
scp ~/certs/ad5m.nianticbooks.home.* root@10.0.10.30:/etc/nginx/ssl/

# Create nginx HTTPS configuration
# (See LOCAL-HTTPS-QUICKSTART.md for detailed steps)
```

Update printer UI URL to: `https://ad5m.nianticbooks.home/fluidd`

#### 4. Configure Proxmox for HTTPS

```bash
# Copy to main-pve
scp ~/certs/freddesk.nianticbooks.home.crt main-pve:/etc/pve/local/pveproxy-ssl.pem
scp ~/certs/freddesk.nianticbooks.home.key main-pve:/etc/pve/local/pveproxy-ssl.key

# Restart Proxmox web service
ssh main-pve "systemctl restart pveproxy"
```

Test: https://freddesk.nianticbooks.home:8006

### Future Tasks

- [ ] Configure Dockge for HTTPS
- [ ] Configure OpenMediaVault for HTTPS
- [ ] Trust CA on other computers (Windows, Mac, mobile devices)
- [ ] Update Pangolin routes to use HTTPS backends
- [ ] Set up certificate auto-renewal
- [ ] Add HTTP → HTTPS redirects

## 📋 Documentation Created

All documentation is in `~/projects/infrastructure/`:

1. **LOCAL-CA-SETUP.md** - Complete technical documentation
2. **LOCAL-HTTPS-QUICKSTART.md** - Step-by-step implementation guide
3. **HTTPS-SETUP-STATUS.md** - This file (current status)
4. **scripts/setup-local-ca.sh** - Automated CA setup
5. **scripts/issue-service-certs.sh** - Certificate generation
6. **scripts/trust-ca-client.sh** - Client trust installation

## 🔧 Maintenance

### Certificate Renewal (in 1 year)

Certificates expire: **December 2026**

To renew:
```bash
# On main-pve
ssh main-pve
pct exec 115 -- bash -c "cd /etc/step-ca && step certificate create <domain> /tmp/<domain>.crt /tmp/<domain>.key --profile leaf --not-after 8760h --ca .step/certs/intermediate_ca.crt --ca-key .step/secrets/intermediate_ca_key --ca-password-file .step/password.txt --no-password --insecure --bundle"

# Re-deploy to services
```

### Checking Certificate Expiry

```bash
openssl x509 -in ~/certs/bob.crt -noout -dates
```

### CA Service Management

```bash
# On main-pve
pct exec 115 -- systemctl status step-ca
pct exec 115 -- systemctl restart step-ca
pct exec 115 -- journalctl -u step-ca -f
```

## 🎯 Goals Achieved

✅ Local Certificate Authority operational
✅ No more browser security warnings (once CA is trusted)
✅ All internal services can use HTTPS
✅ Certificates valid for 1 year
✅ Foundation for secure homelab infrastructure

## 📝 Notes

- **CA Password:** `homelab123` - Change this if desired by:
  1. Stopping step-ca service
  2. Re-encrypting keys with new password
  3. Updating `/etc/step-ca/.step/password.txt`

- **Container 115:** Set to auto-start on boot
  - Can stop/start via Proxmox web UI or `pct stop/start 115`

- **DNS Required:** Ensure all domains resolve in UCG Ultra:
  - bob.nianticbooks.home → 10.0.10.24
  - ad5m.nianticbooks.home → 10.0.10.30
  - ca.nianticbooks.home → 10.0.10.15
  - etc.

## 🐛 Troubleshooting

### CA not accessible
```bash
ssh main-pve "pct status 115"
ssh main-pve "pct exec 115 -- systemctl status step-ca"
```

### Certificate not trusted
```bash
# Re-run trust installation
sudo ~/install-ca-trust.sh

# Verify CA is in trust store
ls /usr/local/share/ca-certificates/
```

### Service won't start with HTTPS
- Check certificate file permissions (should be readable by service)
- Check certificate paths in service config
- Check service logs for errors
- Verify certificate is for correct domain

## 💡 Next Session Plan

1. Run `sudo ~/install-ca-trust.sh` to trust CA on this computer
2. Configure Home Assistant for HTTPS (10 min)
3. Configure AD5M printer for HTTPS (15 min)
4. Test both services
5. Configure Proxmox if time permits

Then the recurring HTTPS issues will be solved permanently!

---

**Created:** 2025-12-06 20:52 UTC
**Last Updated:** 2025-12-06 20:52 UTC
