# WireGuard Tunnel Setup Progress

**Date:** 2025-11-17
**Status:** In Progress - Blocked on UCG Ultra Firewall Configuration

## Completed Tasks

### VPS Configuration (66.63.182.168)
- ✅ Installed WireGuard via apt
- ✅ Generated server and client keys:
  - Server Public: `qiXLh7V4Kt/nLLx8p5LkshqWVc+EKAgNO9LqG1J/0lc=`
  - Server Private: `WFyc4qu26rFyaqQ2F0Q8Ln0+4iPWG5fyE1FlHOgJ72U=`
  - Client Public: `vahZFwrevWgSIfsbWyCogCQ/08TeYd0b/MXmQ/XKZlc=`
  - Client Private: `0BU/ME5CsCAQ86R7u5GbYWUeUbkUPtgORPoYEkGoQ2k=`
- ✅ Configured `/etc/wireguard/wg0.conf`:
  - Interface: 10.0.8.1/24
  - ListenPort: 51820
  - Peer: UCG Ultra (vahZFwrevWgSIfsbWyCogCQ/08TeYd0b/MXmQ/XKZlc=)
  - AllowedIPs: 10.0.8.2/32, 10.0.10.0/24
  - PostUp/PostDown iptables rules for NAT and forwarding
- ✅ Enabled IP forwarding (`net.ipv4.ip_forward = 1`)
- ✅ Started and enabled `wg-quick@wg0` service
- ✅ Stopped old Gerbil container (was using port 51820)

### UCG Ultra Configuration (10.0.10.1)
- ✅ Created WireGuard VPN client configuration via uploaded config file
- ✅ Interface created: `wgclt1` with IP 10.0.8.2/24
- ✅ Tunnel connected successfully:
  - Latest handshake: active
  - Transfer: 3.62 GiB received, 3.99 GiB sent
  - Endpoint: 66.63.182.168:51820
- ✅ IP forwarding enabled on UCG Ultra
- ✅ Routes configured correctly:
  - 10.0.8.0/24 dev wgclt1
  - 10.0.10.0/24 dev br0

### Testing Results
- ✅ UCG Ultra can ping VPS tunnel IP (10.0.8.1) - ~10ms latency
- ✅ UCG Ultra can ping itself on tunnel (10.0.8.2)
- ✅ WireGuard handshake active and data flowing

## Current Blocker

### Issue 1: CRITICAL - Incorrect AllowedIPs Routing Configuration

**Problem:**
The UCG Ultra WireGuard configuration has **INCORRECT** `AllowedIPs` that would route all local LAN traffic through the VPN tunnel.

**Current Configuration (WRONG):**
```ini
AllowedIPs = 10.0.8.0/24, 10.0.10.0/24
```

**What this does:**
- Routes traffic to `10.0.8.0/24` through the tunnel ✅ (correct - tunnel network)
- Routes traffic to `10.0.10.0/24` through the tunnel ❌ (WRONG - this is your LOCAL LAN!)
- This means ALL local traffic would try to go through VPS and back, breaking everything
- Your outgoing internet traffic could also be routed through the VPS

**Required Fix:**
```ini
AllowedIPs = 10.0.8.0/24
```

**Why this is correct:**
- ✅ Only tunnel traffic (10.0.8.0/24) goes through WireGuard
- ✅ Local LAN traffic (10.0.10.0/24) stays local
- ✅ Outgoing internet traffic goes directly through your ISP
- ✅ VPS can still reach your LAN because the **VPS side** has `AllowedIPs = 10.0.8.2/32, 10.0.10.0/24`

### Issue 2: UCG Ultra Firewall Blocking Inbound VPS Traffic

**Problem:**
- VPS **cannot** ping UCG Ultra (10.0.8.2) - 100% packet loss
- VPS **cannot** ping UCG Ultra LAN IP (10.0.10.1) - 100% packet loss
- VPS **cannot** ping home lab devices (10.0.10.3) - 100% packet loss
- Traffic works UCG → VPS but not VPS → UCG (one-way connectivity)

**Root Cause:**
The WireGuard interface `wgclt1` is being assigned to the **External** zone instead of the **VPN** zone in UniFi's Zone-Based Firewall.

**Evidence:**
```bash
# iptables shows wgclt1 traffic routed to WAN rules
-A UBIOS_FORWARD_IN_USER -i wgclt1 -m comment --comment 00000001095216690481 -j UBIOS_WAN_IN_USER

# WAN to LAN chain drops NEW connections
Chain UBIOS_WAN_LAN_USER:
  3336K 3474M ACCEPT     all  ctstate RELATED,ESTABLISHED  # Only return traffic
      4   336 DROP       all  # Blocks NEW connections (our ping attempts)
```

**Zone Assignment:**
- Settings → Zones → External → Shows `VPS-tunnel (10.0.8.0/24)`
- Should be in: Settings → Zones → VPN
- Zone assignment appears to be non-editable in the UI

## Fix Procedure

### STEP 1: Fix AllowedIPs Configuration (CRITICAL - Do This First!)

**Method A: Via UCG Ultra Web UI (Recommended)**

1. Log into UCG Ultra web interface at https://10.0.10.1
2. Navigate to: **Settings → VPN → VPN Client**
3. Find your WireGuard VPN client connection
4. Click **Edit** or the pencil/settings icon
5. Look for the configuration or edit the `.conf` file
6. Change `AllowedIPs` from:
   ```
   AllowedIPs = 10.0.8.0/24, 10.0.10.0/24
   ```
   To:
   ```
   AllowedIPs = 10.0.8.0/24
   ```
7. **Save** the configuration
8. **Restart** the VPN client connection (disconnect and reconnect)
9. Verify the tunnel is up: Check that handshake is active

**Method B: Re-upload Corrected Config File**

If the UI doesn't allow editing, create a new config file and re-upload:

1. Create a new file `ucg-wireguard-fixed.conf` on your local machine:
   ```ini
   [Interface]
   PrivateKey = 0BU/ME5CsCAQ86R7u5GbYWUeUbkUPtgORPoYEkGoQ2k=
   Address = 10.0.8.2/24
   DNS = 1.1.1.1, 8.8.8.8

   [Peer]
   PublicKey = qiXLh7V4Kt/nLLx8p5LkshqWVc+EKAgNO9LqG1J/0lc=
   Endpoint = 66.63.182.168:51820
   AllowedIPs = 10.0.8.0/24
   PersistentKeepalive = 25
   ```
2. Delete the existing VPN client connection in UCG Ultra
3. Create a new VPN client and upload the corrected config file
4. Connect the VPN client
5. Verify tunnel is active

**Verification After Fix:**
```bash
# From a device on your LAN (10.0.10.x), test local connectivity:
ping 10.0.10.1        # Should work (UCG Ultra)
ping 10.0.10.3        # Should work (main-pve)
ping 8.8.8.8          # Should work (internet via ISP, not VPS)

# Check that internet traffic is NOT going through VPS:
traceroute 8.8.8.8    # Should NOT show 10.0.8.1 (VPS tunnel IP)
```

### STEP 2: Fix Firewall to Allow VPS → LAN Traffic

**Option 1: Create Firewall Rule (Recommended for immediate testing)**

Navigate to: **Settings → Firewall & Security → Firewall Rules**

1. Click **Create New Rule**
2. Configure:
   - **Name:** `Allow VPS Tunnel to LAN`
   - **Rule Type:** `LAN IN` (or `Traffic Rules` depending on UI version)
   - **Action:** `Accept`
   - **Source Type:** `Network` or `IP Group`
   - **Source:** `10.0.8.0/24` (or create a network group for VPS tunnel)
   - **Destination:** `Default` (LAN network) or `10.0.10.0/24`
   - **Protocol:** `All`
   - **Port:** Leave empty (all ports)
   - **Enabled:** Yes
3. **Save** the rule
4. **Position:** Drag to near the top of the rule list (before any blocking rules)
5. **Apply** changes

**Option 2: Investigate Zone Assignment**
- Check if VPN Client configuration has a zone setting
- Review UniFi documentation for VPN Client zone assignment
- May need to reconfigure as Site-to-Site VPN instead of VPN Client

**Option 3: Manual iptables Rule (Temporary workaround - NOT RECOMMENDED)**

⚠️ **Warning:** This will be overwritten on reboot or config change

SSH to UCG Ultra and add rule:
```bash
ssh root@10.0.10.1
iptables -I UBIOS_WAN_LAN_USER 1 -s 10.0.8.0/24 -j ACCEPT
```

### STEP 3: Test VPS → Home Lab Connectivity

After completing Steps 1 and 2, test from VPS:

```bash
# SSH to VPS
ssh fred@66.63.182.168

# Test tunnel connectivity
ping 10.0.8.2         # UCG Ultra tunnel IP - should work now
ping 10.0.10.1        # UCG Ultra LAN IP - should work now
ping 10.0.10.3        # main-pve - should work now

# Test service connectivity (if services are running)
curl http://10.0.10.3:8006     # Proxmox web interface
curl http://10.0.10.24:8123    # Home Assistant
```

### STEP 4: Update Pangolin Routes (After Connectivity Verified)

Once VPS can reach home lab:

```bash
# SSH to VPS
ssh fred@66.63.182.168

# Edit Pangolin configuration
sudo nano /etc/pangolin/config.yml

# Update routes to use tunnel:
# freddesk.nianticbooks.com → 10.0.10.3:8006
# bob.nianticbooks.com → 10.0.10.24:8123
# ad5m.nianticbooks.com → 10.0.10.30:80

# Test configuration
sudo pangolin config test

# Reload Pangolin
sudo systemctl reload pangolin
```

## Configuration Files

### VPS: /etc/wireguard/wg0.conf
```ini
[Interface]
Address = 10.0.8.1/24
ListenPort = 51820
PrivateKey = WFyc4qu26rFyaqQ2F0Q8Ln0+4iPWG5fyE1FlHOgJ72U=

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -A FORWARD -o wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = vahZFwrevWgSIfsbWyCogCQ/08TeYd0b/MXmQ/XKZlc=
AllowedIPs = 10.0.8.2/32, 10.0.10.0/24
```

### UCG Ultra: VPN Client Config (NEEDS TO BE CORRECTED!)

**Current Configuration (INCORRECT):**
```ini
[Interface]
PrivateKey = 0BU/ME5CsCAQ86R7u5GbYWUeUbkUPtgORPoYEkGoQ2k=
Address = 10.0.8.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = qiXLh7V4Kt/nLLx8p5LkshqWVc+EKAgNO9LqG1J/0lc=
Endpoint = 66.63.182.168:51820
AllowedIPs = 10.0.8.0/24, 10.0.10.0/24  ← ❌ WRONG! Routes local LAN through tunnel
PersistentKeepalive = 25
```

**Corrected Configuration:**
```ini
[Interface]
PrivateKey = 0BU/ME5CsCAQ86R7u5GbYWUeUbkUPtgORPoYEkGoQ2k=
Address = 10.0.8.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = qiXLh7V4Kt/nLLx8p5LkshqWVc+EKAgNO9LqG1J/0lc=
Endpoint = 66.63.182.168:51820
AllowedIPs = 10.0.8.0/24  ← ✅ CORRECT! Only tunnel traffic goes through VPN
PersistentKeepalive = 25
```

## Services Impact
- Pangolin reverse proxy: Still down (waiting for tunnel connectivity)
- Services at nianticbooks.com: Still inaccessible
- Gerbil tunnel: Decommissioned (container stopped)

## Next Session TODO

### Priority 1: Fix AllowedIPs (CRITICAL!)
1. ✅ **IDENTIFIED:** AllowedIPs configuration error - routing local LAN through tunnel
2. ⏳ **TODO:** Fix UCG Ultra WireGuard config - change `AllowedIPs` from `10.0.8.0/24, 10.0.10.0/24` to `10.0.8.0/24`
3. ⏳ **TODO:** Verify local traffic stays local (test with `traceroute 8.8.8.8` - should NOT show VPS)

### Priority 2: Fix Firewall Rules
4. ⏳ **TODO:** Create firewall rule to allow 10.0.8.0/24 → LAN (see STEP 2 above)
5. ⏳ **TODO:** Test VPS → home lab connectivity (ping from VPS to 10.0.10.3)

### Priority 3: Restore Services
6. ⏳ **TODO:** Configure Pangolin to route through tunnel (once connectivity verified)
7. ⏳ **TODO:** Test public service access (freddesk, bob, ad5m)

### Priority 4: Cleanup
8. ⏳ **TODO:** Update monitoring scripts for WireGuard (tunnel-monitor.sh)
9. ⏳ **TODO:** Document final configuration and update status to "Completed"

---

**Session Notes:**
- SSH to VPS: `ssh fred@66.63.182.168` (requires password for sudo)
- SSH to UCG Ultra: `ssh root@10.0.10.1`
- Check tunnel status: `wg show` (on both VPS and UCG)
- VPS WireGuard interface: `wg0`
- UCG WireGuard interface: `wgclt1`