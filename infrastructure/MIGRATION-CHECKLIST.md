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

## Phase 1: Update UCG Ultra DHCP Pool ✅ COMPLETED

**Completion Date:** 2025-12-11
**Status:** ✅ Verified correct configuration

### Steps:
1. [x] Log into UCG Ultra web interface
2. [x] Navigate to Settings → Networks → Default (LAN)
3. [x] Find DHCP settings
4. [x] DHCP range verified: `10.0.10.50-10.0.10.254` ✅
   - Static/Reserved range: 10.0.10.1-49 (infrastructure)
   - Dynamic DHCP pool: 10.0.10.50-254 (clients/devices)
5. [x] Configuration correct - no changes needed
6. [x] Verified: All services functioning, no connectivity issues

**Notes:** DHCP range was already correctly configured. All static reservations in 10.0.10.1-49 range working as expected.

---

## Phase 2: Update Existing DHCP Reservations ✅ COMPLETED

**Completion Date:** 2025-12-11
**Actual Time:** 15 minutes
**Status:** ✅ All devices responding at new IPs

### 2.1 Update HOMELAB-COMMAND ✅
- [x] Current IP: 10.0.10.92
- [x] Target IP: 10.0.10.10
- [x] MAC: 90:de:80:80:e7:04
- [x] Updated reservation in UCG Ultra
- [x] Renewed DHCP lease
- [x] Verified connectivity: Responding at 10.0.10.10 ✅

### 2.2 Update HP iLO ✅
- [x] Current IP: 10.0.10.53
- [x] Target IP: 10.0.10.13
- [x] MAC: b4:b5:2f:ea:8c:30
- [x] Updated reservation in UCG Ultra
- [x] Device responded to lease renewal
- [x] Verified: Accessible at https://10.0.10.13 ✅

### 2.3 Update ad5m (3D Printer) ✅
- [x] Current IP: 10.0.10.189
- [x] Target IP: 10.0.10.30
- [x] MAC: 88:a9:a7:99:c3:64
- [x] Updated reservation in UCG Ultra
- [x] Printer rebooted
- [x] Verified: Accessible at http://10.0.10.30 ✅
- [x] Updated Caddy route: ad5m.nianticbooks.com → 10.0.10.30:80
- [x] Tested: https://ad5m.nianticbooks.com working ✅

---

## Phase 3: Create New DHCP Reservations for VMs ✅ COMPLETED

**Completion Date:** 2025-12-11
**Actual Time:** 30 minutes
**Status:** ✅ All VMs responding at new IPs

### 3.1 OpenMediaVault ✅
- [x] Current IP: 10.0.10.178
- [x] Target IP: 10.0.10.5
- [x] MAC: bc:24:11:a8:ff:0b
- [x] Created reservation in UCG Ultra
- [x] Networking restarted
- [x] Verified: Accessible at http://10.0.10.5 ✅

### 3.2 Home Assistant ✅
- [x] Current IP: 10.0.10.194
- [x] Target IP: 10.0.10.24
- [x] MAC: 02:f5:e9:54:36:28
- [x] Created reservation in UCG Ultra
- [x] VM restarted
- [x] Verified: Accessible at http://10.0.10.24:8123 ✅
- [x] Updated Caddy route: bob.nianticbooks.com → 10.0.10.24:8123
- [x] Tested: https://bob.nianticbooks.com working ✅

### 3.3 Dockge ✅
- [x] Current IP: 10.0.10.104
- [x] Target IP: 10.0.10.27
- [x] MAC: bc:24:11:4a:42:07
- [x] Created reservation in UCG Ultra
- [x] VM restarted
- [x] Verified: Accessible at 10.0.10.27 ✅

### 3.4 ESPHome ✅
- [x] ~~Removed~~ - ESPHome now runs as Home Assistant add-on (no separate VM needed)
- [x] Container 102 deleted from pve-router
- [x] IP 10.0.10.28 released (available for other use)

### 3.5 Docker Host ✅
- [x] Current IP: 10.0.10.108
- [x] Target IP: 10.0.10.29
- [x] MAC: bc:24:11:a8:ff:0b
- [x] Created reservation in UCG Ultra
- [x] VM restarted
- [x] Verified: All containers running at 10.0.10.29 ✅

### 3.6 pve-scripts-local ✅
- [x] Current IP: 10.0.10.79
- [x] Target IP: 10.0.10.40
- [x] MAC: bc:24:11:0f:78:84
- [x] Created reservation in UCG Ultra
- [x] VM restarted
- [x] Verified: Scripts functional at 10.0.10.40 ✅

---

## Phase 4: Update Pangolin Reverse Proxy Routes ✅ COMPLETED

**Completion Date:** 2025-12-13
**Actual Time:** ~20 minutes
**Status:** ✅ All routes operational (Note: Completed as part of Phase 5 with Caddy)

### 4.1 Backup Pangolin Configuration
- [x] Pangolin replaced with Caddy reverse proxy (simpler configuration)
- [x] Caddy configuration at /etc/caddy/Caddyfile on VPS

### 4.2 Update Routes ✅
- [x] Caddy routes configured:
  ```
  freddesk.nianticbooks.com → 10.0.10.3:8006 (main-pve Proxmox)
  ad5m.nianticbooks.com → 10.0.10.30:80 (Prusa 3D printer)
  bob.nianticbooks.com → 10.0.10.24:8123 (Home Assistant)
  ```
- [x] Deprecated spools.nianticbooks.com route not included
- [x] Caddy service running and enabled

### 4.3 Verify Routes ✅
- [x] Test freddesk: https://freddesk.nianticbooks.com ✅ Working
- [x] Test ad5m: https://ad5m.nianticbooks.com ✅ Working
- [x] Test bob: https://bob.nianticbooks.com ✅ Working (after HA config fix)

### 4.4 Additional Configuration ✅
- [x] Fixed Home Assistant trusted_proxies configuration
- [x] Added 10.0.8.1 (VPS WireGuard IP) to Home Assistant trusted_proxies
- [x] Home Assistant now accepts requests from bob.nianticbooks.com

**Notes:**
- Switched from Pangolin (Gerbil-based) to Caddy for simpler configuration
- Caddy provides automatic HTTPS via Let's Encrypt
- Home Assistant required `trusted_proxies` configuration to accept external domain
- All public services verified functional on 2025-12-13

---

## Phase 5: Configure WireGuard Tunnel ✅ COMPLETED

**Completion Date:** 2025-12-11
**Actual Time:** ~2 hours
**Status:** ✅ Operational

### 5.1 Install WireGuard on VPS ✅
- [x] SSH to VPS: `ssh fred@66.63.182.168`
- [x] Install WireGuard: Already installed (wireguard-tools v1.0.20210914)
- [x] Enable IP forwarding: `sudo sysctl -w net.ipv4.ip_forward=1`
- [x] Make persistent: Added to /etc/sysctl.conf
- [x] Generate server keys: Created successfully
- [x] VPS Server Public Key: `8jcW7SyId/79Jg4+t0Qd0DaDA+4B+GQf14FRR2TXFRE=`

### 5.2 Configure WireGuard on VPS ✅
- [x] Created config: /etc/wireguard/wg0.conf
- [x] Tunnel subnet: 10.0.8.0/24 (VPS: 10.0.8.1, UCG Ultra: 10.0.8.2)
- [x] Configured NAT and forwarding rules
- [x] Started WireGuard: `sudo systemctl start wg-quick@wg0`
- [x] Enabled on boot: `sudo systemctl enable wg-quick@wg0`
- [x] Verified: `sudo wg show` - peer connected with active handshake

### 5.3 Configure WireGuard on UCG Ultra ✅
- [x] Logged into UCG Ultra web interface (10.0.10.1)
- [x] Navigated to: Settings → Teleport & VPN → VPN Client
- [x] Created WireGuard VPN Client
- [x] Configured client settings:
  - Server: 66.63.182.168:51820
  - VPS Public Key: 8jcW7SyId/79Jg4+t0Qd0DaDA+4B+GQf14FRR2TXFRE=
  - Client Address: 10.0.8.2/24
  - Persistent Keepalive: 25 seconds
- [x] UCG Ultra Client Public Key: `KJOj35HdntdLHQTU0tfNPJ/x1GD9SlNy78GuMhMyzTg=`
- [x] Enabled and activated

### 5.4 Test WireGuard Connectivity ✅
- [x] From VPS, ping main-pve: ✅ Working (3/4 packets, ~12ms latency)
- [x] From VPS, HTTP to Home Assistant: ✅ Working (HTTP 405 response)
- [x] From VPS, ping 3D printer (10.0.10.30): ✅ Working
- [x] Tunnel stable with active handshake and data transfer

### 5.5 Reverse Proxy Configuration ✅
**Note:** Replaced Pangolin (Gerbil-based) with Caddy for simplicity

- [x] Removed Pangolin and Traefik Docker containers
- [x] Installed Caddy reverse proxy
- [x] Created /etc/caddy/Caddyfile with routes:
  - bob.nianticbooks.com → 10.0.10.24:8123 (Home Assistant)
  - freddesk.nianticbooks.com → 10.0.10.3:8006 (Proxmox)
  - ad5m.nianticbooks.com → 10.0.10.30:80 (Prusa 3D Printer)
- [x] Automatic HTTPS certificates obtained via Let's Encrypt
- [x] All public services verified working

### 5.6 Public Service Verification ✅
- [x] https://bob.nianticbooks.com - ✅ Working (Home Assistant)
- [x] https://freddesk.nianticbooks.com - ✅ Working (Proxmox)
- [x] https://ad5m.nianticbooks.com - ✅ Working (3D Printer)

**Notes:**
- Tunnel endpoint: VPS 66.63.182.168:51820 ↔ UCG Ultra (home public IP)
- VPS can now reach all 10.0.10.0/24 services through tunnel
- Caddy provides automatic HTTPS and simpler configuration than Pangolin
- No rollback needed - system is stable and operational

---

## Phase 6: Deploy New Services (After WireGuard Active)

**Estimated Time:** Variable (each service 1-2 hours)
**Risk Level:** Low (new services, nothing to break)

### 6.1 PostgreSQL (10.0.10.20) ✅ COMPLETED
- [x] Create VM/container on main-pve
- [x] Assign static IP 10.0.10.20 in VM config
- [x] Install PostgreSQL (PostgreSQL 16)
- [x] Configure databases for: Authentik, n8n, RustDesk, Grafana
- [x] Test connectivity from other VMs
- [x] Verified: Responding at 10.0.10.20 ✅

### 6.2 Authentik SSO (10.0.10.21) ✅ COMPLETED
**Completion Date:** 2025-12-14
**Actual Time:** ~3 hours
**Status:** ✅ Deployed and operational with Proxmox SSO

- [x] Create VM/container on main-pve (Container ID: 121)
- [x] Assign static IP 10.0.10.21 (MAC: bc:24:11:de:18:41)
- [x] Install Authentik (via Docker Compose)
- [x] Configure PostgreSQL connection (using external DB at 10.0.10.20)
- [x] Add Caddy route: auth.nianticbooks.com → 10.0.10.21:9000
- [x] Test: https://auth.nianticbooks.com ✅ Working
- [x] Complete initial setup and password change
- [x] Configure Proxmox OAuth2/OpenID integration ✅
- [ ] Set up WebAuthn/FIDO2 (optional, future enhancement)
- [ ] Configure additional service integrations (n8n, Home Assistant, etc.)

**Configuration Details:**
- Container: Debian 12 LXC (2 vCPUs, 4GB RAM, 20GB disk)
- Database: PostgreSQL on 10.0.10.20 (database: authentik, user: authentik)
- Secret Key: ZsJQbVLiCRtg23rEkXPuxIDJL5MxOxdQsf8ZJ+JHB9U=
- DB Password: authentik_password_8caaff5a73f9c66b
- Version: 2025.10.2
- Automatic HTTPS via Let's Encrypt through Caddy
- Admin User: akadmin
- API Token: f7AsYT6FLZEWVvmN59lC0IQZfMLdgMniVPYhVwmYAFSKHez4aGxyn4Esm86r

**Proxmox SSO Integration:**
- OAuth2 Provider: "Proxmox OpenID" (Client ID: proxmox)
- Client Secret: OAfAcjzzPDUnjEhaLVNIeNu1KR0Io06fB8kA8Np9DTgfgXcsLnN5DogrAfhk5zteazonVGcXfaESvf8viCQFVzq8wNVcp60Bo5D3xvfJ9ZjCzEMCQIljssbfr29zjsap
- Configured on all 3 Proxmox hosts:
  - main-pve (10.0.10.3) ✅
  - gaming-pve (10.0.10.2) ✅
  - backup-pve (10.0.10.4) ✅
- Scope mappings: openid, email, profile
- Login method: Click "Login with authentik" button on Proxmox login page
- Status: ✅ Working - seamless SSO authentication

**Notes:**
- Using external PostgreSQL instead of bundled container for centralized database management
- Authentik SSO successfully integrated with all Proxmox hosts
- Users authenticate once to Authentik, then access all Proxmox hosts without re-authentication
- Documentation created: AUTHENTIK-SSO-GUIDE.md and AUTHENTIK-QUICK-START.md

### 6.3 n8n (10.0.10.22) ✅ COMPLETED
- [x] Create VM/container on main-pve (Container ID: 106)
- [x] Assign static IP 10.0.10.22
- [x] Install n8n (Docker-based deployment)
- [x] Configure PostgreSQL connection (using external DB at 10.0.10.20)
- [x] Updated to latest version (1.123.5)
- [x] Verified: Accessible at http://10.0.10.22:5678 ✅
- [x] SSO Investigation: ❌ OIDC SSO requires n8n Enterprise license (not available in free self-hosted version)

**Notes:**
- n8n OIDC/SSO is an Enterprise-only feature
- Free self-hosted version uses standard email/password authentication
- For SSO integration, would need n8n Cloud subscription or Enterprise license
- Current deployment uses regular authentication - fully functional

### 6.4 n8n + Claude Code Integration ✅ COMPLETED
**Completion Date:** 2025-12-14
**Actual Time:** ~2 hours
**Status:** ✅ Basic integration operational, ready for production workflows

**Reference:** https://github.com/theNetworkChuck/n8n-claude-code-guide

**Architecture:**
- n8n (10.0.10.22 on main-pve) → SSH → Claude Code (10.0.10.10 on HOMELAB-COMMAND)

**Key Configuration Notes:**
- Windows SSH requires PowerShell as default shell for Claude Code to work
- SSH commands MUST use `-n` flag or "Disable Stdin" option to prevent hanging
- Claude Code headless mode: `--output-format json --permission-mode acceptEdits`
- Test workflow created and verified: "Claude Code Test"

#### 6.4.1 Install Claude Code on HOMELAB-COMMAND (10.0.10.10) ✅
- [x] SSH or RDP to HOMELAB-COMMAND (10.0.10.10)
- [x] Node.js already installed: v24.11.0
- [x] Claude Code already installed: v2.0.65
- [x] Verified installation: `claude --version`
- [x] Test headless mode: `claude -p "What is 2+2?" --output-format json --permission-mode acceptEdits`

#### 6.4.2 Configure SSH Access for n8n ✅
- [x] SSH server already running on HOMELAB-COMMAND (Windows OpenSSH)
- [x] Set PowerShell as default SSH shell (required for Claude Code):
  ```powershell
  New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
  Restart-Service sshd
  ```
- [x] Generated SSH key on n8n VM: `ssh-keygen -t ed25519 -C "n8n-to-homelab-command"`
- [x] Added public key to HOMELAB-COMMAND: `C:\Users\Fred\.ssh\authorized_keys`
- [x] Test passwordless SSH: `ssh Fred@10.0.10.10 "hostname"` ✅
- [x] Test Claude Code via SSH: `ssh -n Fred@10.0.10.10 "claude -p 'What is 2+2?' --output-format json --permission-mode acceptEdits"` ✅
- [x] **Critical:** Must use `-n` flag with SSH to prevent stdin hanging

#### 6.4.3 Configure n8n SSH Credentials ✅
- [x] Logged into n8n web interface (http://10.0.10.22:5678)
- [x] Created SSH credential: **homelab-command-ssh**
  - **Host:** 10.0.10.10
  - **Port:** 22
  - **Username:** Fred
  - **Authentication:** Private Key (from `~/.ssh/id_ed25519` on n8n VM)
- [x] Connection tested successfully ✅
- [x] Credential saved

#### 6.4.4 Create Test Workflow ✅
- [x] Created new workflow: "Claude Code Test"
- [x] Added **Manual Trigger** node
- [x] Added **SSH** node:
  - **Credential:** homelab-command-ssh
  - **Command:** `claude -p "What is 2+2?" --output-format json --permission-mode acceptEdits`
  - **SSH Options:** Enabled "Disable Stdin" (equivalent to `-n` flag)
- [x] Added **Code** node to parse JSON response:
  ```javascript
  const sshOutput = $input.item.json.stdout;
  const claudeResponse = JSON.parse(sshOutput);
  return {
    answer: claudeResponse.result,
    cost: claudeResponse.total_cost_usd,
    duration_seconds: claudeResponse.duration_ms / 1000,
    session_id: claudeResponse.session_id
  };
  ```
- [x] Executed workflow successfully ✅
- [x] Verified Claude Code response: "2 + 2 = 4"

#### 6.4.5 Advanced: Session Management Workflow
- [ ] Add **Code** node to generate session UUID:
  ```javascript
  const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
  return [{ json: { sessionId: uuid } }];
  ```
- [ ] Add **SSH** node for initial query:
  - **Command:** `claude -p "{{ $json.prompt }}" --session-id {{ $json.sessionId }}`
- [ ] Add **SSH** node for follow-up:
  - **Command:** `claude -r --session-id {{ $('UUID Generator').item.json.sessionId }} -p "{{ $json.followup }}"`
- [ ] Test multi-turn conversation

#### 6.4.6 Optional: Slack Integration
- [ ] Install Slack app in n8n
- [ ] Create workflow triggered by Slack messages
- [ ] Use SSH node to send message to Claude Code
- [ ] Return Claude response to Slack thread
- [ ] Implement session tracking for conversations

#### 6.4.7 Optional: Tool Deployment
For automated skill deployment (UniFi, infrastructure tasks):
- [ ] Update SSH command to include `--dangerously-skip-permissions`:
  ```bash
  claude --dangerously-skip-permissions -p "Your task requiring tools"
  ```
- [ ] Test with infrastructure directory context:
  ```bash
  cd /path/to/infrastructure && claude -p "Check WireGuard status"
  ```

#### 6.4.8 Verification & Testing ✅ BASIC TESTING COMPLETE
- [x] Test basic headless command from n8n ✅
- [ ] Test session-based multi-turn conversation (optional - future enhancement)
- [x] Verify Claude Code can access local files on HOMELAB-COMMAND ✅
- [ ] Test error handling (network disconnect, invalid commands) (optional - future enhancement)
- [ ] Monitor resource usage on HOMELAB-COMMAND during heavy Claude operations (ongoing)
- [x] Document SSH requirements: Must use `-n` flag or "Disable Stdin" option in n8n

#### 6.4.9 Production Considerations
- [ ] Set appropriate SSH timeout in n8n (default may be too short for complex Claude tasks)
- [ ] Configure Claude Code project context on HOMELAB-COMMAND:
  - Clone infrastructure repo to known location
  - Set up CLAUDE.md in project directory
- [ ] Consider output length limits (Slack: 4000 chars, n8n processing limits)
- [ ] Set up logging for Claude Code executions
- [ ] Add error notifications to n8n workflow
- [ ] Optional: Add Pangolin route for public n8n access (with Authentik SSO)

### 6.5 RustDesk ID Server (10.0.10.23)
- [ ] Create VM/container on main-pve
- [ ] Assign static IP 10.0.10.23
- [ ] Install RustDesk hbbs (ID server)
- [ ] Configure relay server on VPS (hbbr)
- [ ] Test RustDesk client connections

### 6.6 Prometheus + Grafana (10.0.10.25)
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
