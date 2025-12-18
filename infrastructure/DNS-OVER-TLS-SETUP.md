# DNS over TLS Configuration Guide

This guide covers setting up DNS over TLS (DoT) on your UCG Ultra gateway to encrypt DNS queries network-wide.

## What is DNS over TLS?

DNS over TLS encrypts DNS queries between your network and upstream DNS servers, preventing ISPs and other third parties from monitoring or logging your DNS lookups. Once configured on the UCG Ultra, all devices on your network automatically benefit without per-device configuration.

## Prerequisites

- UCG Ultra at 10.0.10.1
- Admin access to UniFi Network application
- Internet connectivity

## Configuration Steps

### 1. Access UCG Ultra Web Interface

```
URL: https://10.0.10.1
or access via UniFi Network application
```

### 2. Navigate to DNS Settings

1. Click **Settings** (gear icon)
2. Select **Internet**
3. Click on **WAN** (or **Primary WAN1**)
4. Scroll to **DNS Servers** section

### 3. Enable DNS over TLS

1. Toggle **DNS over TLS** to **ON**
2. Configure upstream DNS servers (see options below)
3. Click **Apply Changes**

## Recommended DNS Providers

### Option 1: Cloudflare (Recommended - Privacy-focused, fastest)

**DNS Servers:**
- Primary: `1.1.1.1`
- Secondary: `1.0.0.1`

**TLS Hostname:** `cloudflare-dns.com`

**Features:**
- Fastest global DNS resolver
- Privacy-focused (doesn't log queries)
- DNSSEC validation
- Malware blocking available (1.1.1.2/1.0.0.2)
- Family filtering available (1.1.1.3/1.0.0.3)

### Option 2: Quad9 (Security-focused)

**DNS Servers:**
- Primary: `9.9.9.9`
- Secondary: `149.112.112.112`

**TLS Hostname:** `dns.quad9.net`

**Features:**
- Blocks known malicious domains
- Privacy-focused (based in Switzerland)
- DNSSEC validation
- Threat intelligence from multiple sources

### Option 3: Google Public DNS

**DNS Servers:**
- Primary: `8.8.8.8`
- Secondary: `8.8.4.4`

**TLS Hostname:** `dns.google`

**Features:**
- High reliability and uptime
- Fast global network
- DNSSEC validation
- Note: Google logs queries for 24-48 hours

### Option 4: AdGuard DNS (Ad Blocking)

**DNS Servers (Default - Ad Blocking):**
- Primary: `94.140.14.14`
- Secondary: `94.140.15.15`

**TLS Hostname:** `dns.adguard-dns.com`

**Features:**
- Built-in ad and tracker blocking
- Family protection mode available
- No logging
- Free tier available

## Additional Recommended Settings

### Enable DNSSEC

While in DNS settings:
1. Enable **DNSSEC** (if available)
2. This cryptographically validates DNS responses to prevent spoofing

### Configure Local DNS Records

For easier access to infrastructure services:

**Settings → Networks → LAN → DHCP → Local DNS Records**

Add custom entries:
- `proxmox.home` → `10.0.10.3` (main-pve)
- `proxmox-router.home` → `10.0.10.2` (pve-router)
- `storage.home` → `10.0.10.5` (OpenMediaVault)
- `homeassistant.home` → `10.0.10.24` (Home Assistant)
- `esphome.home` → `10.0.10.28` (ESPHome)
- `auth.home` → `10.0.10.21` (Authentik - when deployed)

This allows you to access services via friendly names instead of IP addresses.

## Verification

### Test DNS over TLS is Working

**Method 1: Cloudflare Test (if using Cloudflare DNS)**
1. Visit: https://1.1.1.1/help
2. Look for "Using DNS over TLS (DoT)" - should show **Yes**

**Method 2: Command Line Test**

From any device on your network:
```bash
# Test DNS resolution
nslookup google.com

# Test DNSSEC validation (should succeed)
dig @1.1.1.1 dnssec-failed.org

# Check if queries are encrypted (requires tcpdump)
sudo tcpdump -i any port 853
# Should show TLS traffic on port 853, not plaintext DNS on port 53
```

**Method 3: Check UCG Ultra Logs**

In UniFi Network application:
1. Navigate to **System Settings → Logs**
2. Filter for DNS-related events
3. Should see successful DoT connections

## Advanced: Local DNS Resolver Option

For even more control (ad blocking, custom filtering, detailed logging), consider deploying a local DNS resolver:

### Pi-hole or AdGuard Home

**Deployment:**
- LXC container on pve-router (10.0.10.2)
- IP: 10.0.10.26 (available in allocation plan)
- Resources: 1 CPU, 512MB-1GB RAM, 4GB storage

**Configuration:**
1. Deploy Pi-hole/AdGuard Home on 10.0.10.26
2. Configure it to use DoT upstream (Cloudflare, Quad9, etc.)
3. Point UCG Ultra DNS to 10.0.10.26
4. All network traffic → Pi-hole → DoT upstream

**Benefits:**
- Network-wide ad blocking
- Detailed query logging and statistics
- Custom blocklists and whitelists
- Local DNS record management
- DoT encryption for upstream queries

See `PIHOLE-SETUP.md` (future document) for deployment guide.

## Troubleshooting

### DNS Resolution Fails After Enabling DoT

**Symptoms:** Websites won't load, "DNS resolution failed" errors

**Solutions:**
1. Verify upstream DNS servers are correct
2. Check UCG Ultra has internet connectivity
3. Temporarily disable DoT to isolate issue
4. Try different DNS provider (Cloudflare vs Quad9)
5. Check firewall rules allow outbound port 853 (DoT)

### Slow DNS Resolution

**Possible Causes:**
- Upstream DNS server is slow/distant
- Network latency issues
- DNSSEC validation overhead

**Solutions:**
1. Try different DNS provider closer to your region
2. Use DNS benchmark tool: https://www.grc.com/dns/benchmark.htm
3. Check UCG Ultra CPU/memory usage

### Some Devices Can't Resolve DNS

**Check:**
1. Device is using UCG Ultra as DNS (10.0.10.1)
2. Device has valid DHCP lease
3. No hardcoded DNS servers on the device
4. Firewall rules aren't blocking DNS

## Security Considerations

### What DoT Protects Against
- ISP DNS query logging and selling data
- DNS query snooping on local network
- Man-in-the-middle DNS hijacking

### What DoT Does NOT Protect Against
- Website tracking (cookies, fingerprinting)
- ISP seeing which websites you visit (they see IP addresses)
- Malware/phishing (use Quad9 or filtering DNS for this)

### Additional Privacy Measures
- Use HTTPS everywhere (encrypted web traffic)
- Consider VPN for full traffic encryption
- Use privacy-focused browsers (Firefox, Brave)
- Enable tracking protection in browsers

## Maintenance

### Regular Checks
- **Monthly:** Verify DoT is still active (check test sites)
- **Quarterly:** Review DNS provider performance
- **As Needed:** Update local DNS records for new services

### When to Reconfigure
- Moving to new internet provider
- DNS provider changes policies
- Performance degrades
- Adding local DNS resolver (Pi-hole)

## Network-Wide Impact

Once configured, DNS over TLS benefits:
- All computers (Windows, Mac, Linux)
- Mobile devices (phones, tablets)
- IoT devices (smart home, cameras, etc.)
- Guest network devices
- All VLANs managed by UCG Ultra

**No per-device configuration needed.**

## Related Documentation

- `IP-ALLOCATION.md` - Network addressing plan
- `RUNBOOK.md` - General network troubleshooting
- `SERVICES.md` - Service configuration reference
- Future: `PIHOLE-SETUP.md` - Local DNS resolver deployment

## References

- [Cloudflare DNS over TLS](https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-tls/)
- [Quad9 Documentation](https://www.quad9.net/support/faq/)
- [DNS over TLS RFC 7858](https://datatracker.ietf.org/doc/html/rfc7858)
- [UniFi Gateway Documentation](https://help.ui.com/hc/en-us/categories/200320654-UniFi-Gateway)

---

**Last Updated:** 2025-11-18
**Status:** Ready for deployment
**Priority:** Medium (privacy/security enhancement)
