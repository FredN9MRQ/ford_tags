# IP Migration Checklist

**Date Started:** _______________
**Estimated Completion:** _______________
**Status:** Not Started

---

## Pre-Migration Tasks

### Backup Current Configuration
- [ ] Export current DHCP leases from UCG Ultra (✅ Already done: dhcp-export-all-2025-11-14T22-55-18.871Z.csv)
- [ ] Screenshot current UCG Ultra network settings
- [ ] Backup Pangolin reverse proxy configuration on VPS
- [ ] Document current Proxmox VM network configs

### Testing Preparation
- [ ] Verify SSH access to all Proxmox nodes
- [ ] Verify access to UCG Ultra web UI
- [ ] Have physical access to at least one machine (if remote access breaks)
- [ ] Note current Pangolin routes and test URLs

---

## Phase 1: Update UCG Ultra DHCP Pool

**Estimated Time:** 5 minutes
**Risk Level:** Low (doesn't affect existing leases immediately)

### Steps:
1. [ ] Log into UCG Ultra web interface
2. [ ] Navigate to Settings → Networks → Default (LAN)
3. [ ] Find DHCP settings
4. [ ] Change DHCP range from `10.0.10.50-10.0.10.254` to `10.0.10.50-10.0.10.254`
   - Current: 10.0.10.50-10.0.10.254
   - New: 10.0.10.50-10.0.10.254 (same, just documenting)
5. [ ] Save changes
6. [ ] Verify no services lost connectivity

**Rollback:** Change DHCP range back to original settings

---

## Phase 2: Update Existing DHCP Reservations

**Estimated Time:** 15 minutes
**Risk Level:** Low (updating existing reservations)

### 2.1 Update HOMELAB-COMMAND
- [ ] Current IP: 10.0.10.92
- [ ] Target IP: 10.0.10.10
- [ ] MAC: 90:de:80:80:e7:04
- [ ] Update reservation in UCG Ultra
- [ ] Renew DHCP lease on machine: `ipconfig /release && ipconfig /renew` (Windows)
- [ ] Verify connectivity: `ping 10.0.10.10`
- [ ] Test: SSH or RDP access

### 2.2 Update HP iLO
- [ ] Current IP: 10.0.10.53
- [ ] Target IP: 10.0.10.13
- [ ] MAC: b4:b5:2f:ea:8c:30
- [ ] Update reservation in UCG Ultra
- [ ] Power cycle server OR wait for lease renewal
- [ ] Verify: Access iLO web interface at https://10.0.10.13
- [ ] Update DNS record: ilo.nianticbooks.home → 10.0.10.13

### 2.3 Update ad5m (3D Printer)
- [ ] Current IP: 10.0.10.189
- [ ] Target IP: 10.0.10.30
- [ ] MAC: 88:a9:a7:99:c3:64
- [ ] Update reservation in UCG Ultra
- [ ] Reboot printer OR wait for lease renewal
- [ ] Verify: Access printer web interface at http://10.0.10.30
- [ ] Update DNS record: AD5M.nianticbooks.home → 10.0.10.30
- [ ] Update Pangolin route: ad5m.nianticbooks.com → 10.0.10.30:80
- [ ] Test: https://ad5m.nianticbooks.com

**Rollback:** Revert reservations to original IPs in UCG Ultra

---

## Phase 3: Create New DHCP Reservations for VMs

**Estimated Time:** 30 minutes
**Risk Level:** Medium (services will briefly lose connectivity during IP change)

**IMPORTANT:** For each VM, you may need to:
1. Create reservation in UCG Ultra
2. Restart VM's networking OR reboot VM
3. Update any configs that reference the old IP
4. Update Pangolin routes if publicly exposed

### 3.1 OpenMediaVault
- [ ] Current IP: 10.0.10.178
- [ ] Target IP: 10.0.10.5
- [ ] MAC: bc:24:11:a8:ff:0b
- [ ] Create reservation in UCG Ultra
- [ ] SSH to OMV and restart networking: `systemctl restart networking`
- [ ] Verify new IP: `ip addr show`
- [ ] Update NFS/CIFS share paths in Proxmox (if referenced by IP)
- [ ] Test: Access OMV web interface at http://10.0.10.5

### 3.2 Home Assistant
- [ ] Current IP: 10.0.10.194
- [ ] Target IP: 10.0.10.24
- [ ] MAC: 02:f5:e9:54:36:28
- [ ] Create reservation in UCG Ultra
- [ ] Restart Home Assistant VM
- [ ] Verify: Access Home Assistant at http://10.0.10.24:8123
- [ ] Update Pangolin route: bob.nianticbooks.com → 10.0.10.24:8123
- [ ] Test: https://bob.nianticbooks.com
- [ ] Update mDNS reference to static IP in documentation

### 3.3 Dockge
- [ ] Current IP: 10.0.10.104
- [ ] Target IP: 10.0.10.27
- [ ] MAC: bc:24:11:4a:42:07
- [ ] Create reservation in UCG Ultra
- [ ] Restart Dockge VM
- [ ] Verify: Access Dockge web interface

### 3.4 ESPHome
- [ ] Current IP: 10.0.10.113
- [ ] Target IP: 10.0.10.28
- [ ] MAC: bc:24:11:8f:eb:eb
- [ ] Create reservation in UCG Ultra
- [ ] Restart ESPHome VM
- [ ] Verify: Access ESPHome web interface
- [ ] Update Home Assistant integration if it uses IP

### 3.5 Docker Host
- [ ] Current IP: 10.0.10.108
- [ ] Target IP: 10.0.10.29
- [ ] MAC: bc:24:11:a8:ff:0b
- [ ] Create reservation in UCG Ultra
- [ ] Restart Docker VM
- [ ] Verify all containers still running: `docker ps`
- [ ] Test container connectivity

### 3.6 pve-scripts-local
- [ ] Current IP: 10.0.10.79
- [ ] Target IP: 10.0.10.40
- [ ] MAC: bc:24:11:0f:78:84
- [ ] Create reservation in UCG Ultra
- [ ] Restart VM
- [ ] Verify scripts still functional

**Rollback:** Remove new reservations, reboot VMs to get old DHCP addresses back

---

## Phase 4: Update Pangolin Reverse Proxy Routes

**Estimated Time:** 10 minutes
**Risk Level:** Medium (public services will be down during update)

### 4.1 Backup Pangolin Configuration
- [ ] SSH to VPS: `ssh user@66.63.182.168`
- [ ] Backup config: `sudo cp /etc/pangolin/config.yml /etc/pangolin/config.yml.backup-$(date +%Y%m%d)`
- [ ] Note current route configuration

### 4.2 Update Routes
- [ ] Edit Pangolin config: `sudo nano /etc/pangolin/config.yml` (or appropriate path)
- [ ] Update routes:
  ```
  freddesk.nianticbooks.com → 10.0.10.3:8006 (main-pve Proxmox - verify IP)
  ad5m.nianticbooks.com → 10.0.10.30:80 (was .35 or .189)
  bob.nianticbooks.com → 10.0.10.24:8123 (was homeassistant.local or .194)
  ```
- [ ] Remove deprecated route:
  ```
  spools.nianticbooks.com (was 10.0.10.71 - being removed)
  ```
- [ ] Test configuration: `sudo pangolin config test` (or equivalent)
- [ ] Reload Pangolin: `sudo systemctl reload pangolin`

### 4.3 Verify Routes
- [ ] Test freddesk: https://freddesk.nianticbooks.com
- [ ] Test ad5m: https://ad5m.nianticbooks.com
- [ ] Test bob: https://bob.nianticbooks.com

**Rollback:** `sudo cp /etc/pangolin/config.yml.backup-YYYYMMDD /etc/pangolin/config.yml && sudo systemctl reload pangolin`

---

## Phase 5: Configure WireGuard Tunnel

**Estimated Time:** 45 minutes
**Risk Level:** High (new infrastructure component)

**PREREQUISITE:** All other IP migrations complete and tested

### 5.1 Install WireGuard on VPS
- [ ] SSH to VPS: `ssh user@66.63.182.168`
- [ ] Install WireGuard: `sudo apt update && sudo apt install wireguard -y`
- [ ] Enable IP forwarding: `sudo sysctl -w net.ipv4.ip_forward=1`
- [ ] Make persistent: `echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf`
- [ ] Generate server keys:
  ```bash
  wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key
  sudo chmod 600 /etc/wireguard/server_private.key
  ```
- [ ] Note public key: `cat /etc/wireguard/server_public.key`

### 5.2 Configure WireGuard on VPS
- [ ] Create config: `sudo nano /etc/wireguard/wg0.conf`
- [ ] Add configuration (see WireGuard setup guide)
- [ ] Start WireGuard: `sudo systemctl start wg-quick@wg0`
- [ ] Enable on boot: `sudo systemctl enable wg-quick@wg0`
- [ ] Verify: `sudo wg show`

### 5.3 Configure WireGuard on UCG Ultra
- [ ] Log into UCG Ultra web interface
- [ ] Navigate to VPN section
- [ ] Create new WireGuard tunnel
- [ ] Configure client settings (endpoint: 66.63.182.168:51820)
- [ ] Set allowed IPs: 10.0.10.0/24 (or specific routes)
- [ ] Enable persistent keepalive: 25 seconds
- [ ] Save and activate

### 5.4 Test WireGuard Connectivity
- [ ] From VPS, ping UCG Ultra tunnel IP
- [ ] From VPS, ping main-pve: `ping 10.0.10.3`
- [ ] From home network, verify VPS can reach services
- [ ] Test Pangolin can route through tunnel

### 5.5 Update Tunnel Monitoring
- [ ] Update `scripts/tunnel-monitor.sh` for WireGuard
- [ ] Deploy to VPS
- [ ] Test monitoring script

**Rollback:** Stop WireGuard on both ends, services return to "down" state (same as current)

---

## Phase 6: Deploy New Services (After WireGuard Active)

**Estimated Time:** Variable (each service 1-2 hours)
**Risk Level:** Low (new services, nothing to break)

### 6.1 PostgreSQL (10.0.10.20)
- [ ] Create VM/container on main-pve
- [ ] Assign static IP 10.0.10.20 in VM config
- [ ] Install PostgreSQL
- [ ] Configure databases for: Authentik, n8n, RustDesk, Grafana
- [ ] Test connectivity from other VMs

### 6.2 Authentik SSO (10.0.10.21)
- [ ] Create VM/container on main-pve
- [ ] Assign static IP 10.0.10.21
- [ ] Install Authentik
- [ ] Configure PostgreSQL connection
- [ ] Set up WebAuthn/FIDO2
- [ ] Add Pangolin route: auth.nianticbooks.com → 10.0.10.21:9000
- [ ] Test: https://auth.nianticbooks.com
- [ ] Configure OAuth2/OIDC providers

### 6.3 n8n (10.0.10.22)
- [ ] Create VM/container on main-pve
- [ ] Assign static IP 10.0.10.22
- [ ] Install n8n
- [ ] Configure PostgreSQL connection
- [ ] Integrate with Authentik for SSO
- [ ] Add Pangolin route (if public access needed)

### 6.4 RustDesk ID Server (10.0.10.23)
- [ ] Create VM/container on main-pve
- [ ] Assign static IP 10.0.10.23
- [ ] Install RustDesk hbbs (ID server)
- [ ] Configure relay server on VPS (hbbr)
- [ ] Test RustDesk client connections

### 6.5 Prometheus + Grafana (10.0.10.25)
- [ ] Create VM/container on main-pve
- [ ] Assign static IP 10.0.10.25
- [ ] Install Prometheus and Grafana
- [ ] Configure data sources
- [ ] Integrate with Authentik for SSO
- [ ] Set up monitoring targets
- [ ] Add Pangolin route (if public access needed)

---

## Phase 7: Cleanup & Decommission

**Estimated Time:** 15 minutes
**Risk Level:** Low (removing unused services)

### 7.1 Remove Spoolman
- [ ] Verify spoolman is not in use
- [ ] Backup any data (if needed): `vzdump CTID --storage backup`
- [ ] Stop VM/container: `pct stop CTID` or `qm stop VMID`
- [ ] Delete VM/container: `pct destroy CTID` or `qm destroy VMID`
- [ ] Remove Pangolin route (already done in Phase 4)
- [ ] Reclaim IP 10.0.10.71

### 7.2 Remove Authelia
- [ ] Verify authelia is not in use (replaced by Authentik)
- [ ] Backup configuration (if needed for migration reference)
- [ ] Stop VM/container
- [ ] Delete VM/container
- [ ] Reclaim IP 10.0.10.112

---

## Phase 8: Update All Documentation

**Estimated Time:** 30 minutes
**Risk Level:** None

- [ ] Update infrastructure-audit.md with final IP assignments
- [ ] Update CLAUDE.md with correct network (10.0.10.x)
- [ ] Update SERVICES.md with new service IPs
- [ ] Update RUNBOOK.md if procedures changed
- [ ] Update MONITORING.md with new service endpoints
- [ ] Git commit all documentation changes
- [ ] Git push to sync across machines

---

## Final Verification

- [ ] All critical services accessible via local IP
- [ ] All public services accessible via nianticbooks.com domains
- [ ] WireGuard tunnel stable and monitored
- [ ] No DHCP conflicts in range 10.0.10.50-254
- [ ] All reservations documented in IP-ALLOCATION.md
- [ ] Documentation updated and pushed to GitHub

---

## Notes & Issues Encountered

```
[Add any notes, problems encountered, or deviations from the plan]





```

---

**Completion Date:** _______________
**Completed By:** _______________
**Time Taken:** _______________
