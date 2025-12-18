# Infrastructure Brainstorming Session

**Date**: 2025-10-28
**Status**: Planning Phase

---

## Initial Claude Code Discovery

I watched this video, https://youtu.be/MsQACpcuTkU?si=2h5VUlgtIcpLbP1v literally took his word as fact and subscribed to Claude Pro. I need to set this up on my 2013 Mac Pro Running Sequoia (using Open Core Legacy Patcher) please outline the steps and process for making this happen

### Claude Code Interest - The /init Command

Specifically Claude Code, as a clarification, I am most intrigued by the use of the /init command

**Setup Requirements:**
- Homebrew installation
- Claude Code CLI tool
- API authentication (separate from Claude Pro subscription)
- Note: Claude Pro ≠ API access (separate billing)

---

## Infrastructure Expansion Plans

### Current Environment

**VPS:**
- 2 cores / 4GB RAM
- Running: Pangolin reverse proxy with Gerbil tunnels (WireGuard-based)
- Concern: RAM and CPU usage limits

**Home Lab (Proxmox):**
- **DL380p**: 32 cores, 96GB RAM (main cluster node)
- **i5**: 8 cores, 8GB RAM (secondary cluster node)
- **OMV**: 12TB storage node

**Development Machine:**
- Mac Pro 2013 running Sequoia (via Open Core Legacy Patcher)

### Proposed New Services

1. **RustDesk Server** - Self-hosted remote desktop
2. **n8n** - Workflow automation platform
3. **Authentik** - Single Sign-On (SSO) platform
4. **Obsidian Livesync** - Self-hosted note synchronization

---

## Architecture Decision: Hybrid Approach

### VPS (Lightweight Services Only)
- Pangolin reverse proxy (existing)
- Gerbil tunnels (existing, WireGuard-based)
- RustDesk relay server (hbbr) - ~30-50MB RAM for NAT traversal only

**Reasoning**: Keep VPS lightweight to avoid resource constraints

### DL380p Proxmox (Heavy Lifting)
- PostgreSQL (shared database server)
- Authentik SSO with WebAuthn support
- n8n workflow automation
- RustDesk ID server (hbbs) - handles registration and signaling
- Prometheus + Grafana monitoring
- Obsidian CouchDB sync server

**Reasoning**: Abundant resources (32 cores, 96GB RAM) available for all services

---

## Authentik SSO - Core Requirements

### WebAuthn/FIDO2 Hardware Authentication

**Critical Requirement**: Device-specific hardware 2FA

**Supported Devices:**
- iPhone with Face ID (biometric authentication)
- Windows 11 laptop with Windows Hello (fingerprint/face/PIN)
- No YubiKey required (but supported if needed later)

**Security Features:**
- Phishing-resistant (WebAuthn verifies domain)
- Each device has unique cryptographic key
- Keys stored in device secure enclave (iPhone) or TPM (Windows)
- Can revoke individual devices if lost/stolen
- TOTP as backup MFA method

### Integration Targets

**Priority 1 (Critical):**
- Proxmox VE (OpenID Connect)
- n8n (OAuth2)
- Pangolin admin dashboard (if supported)

**Priority 2 (Nice to have):**
- Grafana (OAuth2)
- HomeAssistant (OAuth2)
- Any future services

**SSO Policies:**
- External access (via Pangolin): WebAuthn REQUIRED
- Internal network access: WebAuthn preferred, TOTP acceptable
- Admin operations: Always require WebAuthn

---

## Network Architecture

### Flow Diagram
```
Internet → VPS (Pangolin Reverse Proxy)
              ↓
       Gerbil Tunnel (WireGuard)
              ↓
       DL380p Proxmox Home Lab
              ↓
       Authentik SSO ←→ All Services
              ├─→ n8n
              ├─→ RustDesk (hbbs)
              ├─→ Grafana
              ├─→ Proxmox Web UI
              └─→ HomeAssistant (future)
```

### Service Endpoints
- `auth.yourdomain.com` → Authentik SSO
- `n8n.yourdomain.com` → n8n workflows
- `grafana.yourdomain.com` → Monitoring dashboards
- `obsidian.yourdomain.com` → Note sync (CouchDB)

---

## Implementation Strategy: 8 Phases

### Phase 1: Planning & Preparation
- Document current infrastructure
- Make architecture decisions (LXC vs Docker, shared vs separate PostgreSQL)
- Create project structure with Claude Code
- Plan network layout and port assignments

### Phase 2: Infrastructure Foundation on Proxmox
- Deploy PostgreSQL 15 (shared database server)
- Network and port planning
- Reserve static IPs for all services

### Phase 3: Deploy Core Services on Proxmox
- Authentik SSO with WebAuthn/FIDO2 support
- n8n workflow automation
- RustDesk ID server (hbbs)

### Phase 4: VPS Configuration
- RustDesk relay server (hbbr) - lightweight
- Update Pangolin reverse proxy routes
- DNS record creation
- SSL certificate management

### Phase 5: SSO Integration & WebAuthn Enrollment
- Configure Authentik OAuth2/OIDC providers
- Integrate Proxmox with OpenID Connect
- Integrate n8n with OAuth2
- Enroll all personal devices (iPhone, Windows laptop)
- Set up TOTP backup

### Phase 6: Monitoring, Security & Hardening
- Deploy Prometheus + Grafana monitoring stack
- Security hardening (firewall rules, Fail2ban, SSL)
- WebAuthn policies and device management
- Configure alerts

### Phase 7: Backup, Documentation & Testing
- Comprehensive backup solution to OMV (NFS)
- Complete infrastructure documentation
- Testing and validation procedures
- Disaster recovery drills

### Phase 8: Future Integrations
- HomeAssistant integration with Authentik
- Obsidian Livesync deployment
- Additional services as needed

---

## Resource Allocation Plan

### Proxmox DL380p Services

| Service | Cores | RAM | Storage | Purpose |
|---------|-------|-----|---------|---------|
| PostgreSQL | 2 | 4GB | 20GB | Shared database for all services |
| Authentik | 2 | 3GB | 30GB | SSO platform with WebAuthn |
| n8n | 4 | 4GB | 40GB | Workflow automation |
| RustDesk (hbbs) | 2 | 2GB | 10GB | Remote desktop ID server |
| Monitoring | 2 | 4GB | 50GB | Prometheus + Grafana |
| Obsidian Sync | 2 | 2GB | 50GB | CouchDB for note synchronization |
| **Total** | **14** | **19GB** | **200GB** | |
| **Available** | **18/32** | **77GB/96GB** | - | Still plenty of headroom! |

### VPS Resource Usage

| Service | Cores | RAM | Purpose |
|---------|-------|-----|---------|
| Pangolin | ~1 | ~2GB | Reverse proxy |
| Gerbil | ~0.5 | ~256MB | WireGuard tunnels |
| RustDesk (hbbr) | ~0.5 | ~128MB | NAT traversal relay |
| **Total** | **~2** | **~2.4GB** | |
| **Limit** | **2** | **4GB** | Within safe limits ✅ |

---

## Obsidian Implementation Details

### Why Obsidian for Infrastructure Documentation?
- Native markdown checkbox support
- Real-time sync across all devices (Mac, Windows, iPhone)
- Self-hosted sync (no subscription needed)
- Can store infrastructure checklist, notes, diagrams
- Works offline
- End-to-end encrypted

### Obsidian Livesync Architecture
- CouchDB server on Proxmox (backend)
- Obsidian apps on all devices (clients)
- Self-hosted sync via Pangolin reverse proxy
- Database: `obsidian-vault`
- Backup to OMV storage

### Device Setup
1. Mac Pro: Primary documentation device
2. Windows 11 Laptop: Access from work/travel
3. iPhone: Mobile access to infrastructure notes and checklists

### Integration with Infrastructure Project
- Implementation checklist (190+ tasks) stored in Obsidian
- Real-time updates across devices as tasks are completed
- Can attach network diagrams, screenshots, configs
- Version history via CouchDB replication

---

## Security Considerations

### Authentication Layers
1. **Network Level**: Gerbil tunnel encryption (WireGuard)
2. **Application Level**: Authentik SSO with WebAuthn
3. **Device Level**: Hardware-based authentication (Face ID, Windows Hello)
4. **Backup Level**: TOTP authenticator app

### Firewall Strategy
- VPS: Only expose Pangolin ports (80, 443, Gerbil tunnel port)
- Proxmox: Internal network only, no direct external access
- LXC containers: Isolated, only necessary inter-container communication
- Fail2ban on Authentik and VPS SSH

### Backup Security
- Daily backups to OMV (12TB NFS storage)
- Weekly and monthly rotation
- PostgreSQL dumps (compressed)
- Authentik media and config backups
- n8n workflow backups (credentials encrypted)
- RustDesk encryption keys (CRITICAL)
- Grafana dashboards
- Off-site backup optional (cloud via rclone)

### Certificate Management
- Let's Encrypt via Pangolin
- Automated renewal
- HSTS headers enabled
- TLS 1.3 enforcement

---

## Development Approach: Claude Code Usage

### Primary Use Cases
1. Generate complete deployment scripts for each service
2. Create LXC container configurations
3. Generate Docker Compose files
4. Create backup automation scripts
5. Generate comprehensive documentation
6. Create testing and validation scripts

### Example /init Commands

**PostgreSQL Deployment:**
```
/init Create PostgreSQL 15 deployment for Proxmox LXC container with:
- Debian 12 base
- Separate databases for authentik, n8n, rustdesk, grafana
- Optimized for 4GB RAM
- Backup scripts to NFS mount
```

**Authentik with WebAuthn:**
```
/init Create Authentik SSO server deployment for Proxmox LXC with WebAuthn/FIDO2 support:
- Docker Compose setup
- External PostgreSQL connection
- WebAuthn enrollment flows
- OAuth2/OIDC provider configurations
- Integration templates for Proxmox, n8n, Grafana
```

**Complete Infrastructure:**
```
/init Create comprehensive project structure for self-hosted infrastructure:
- Folder organization for all services
- Deployment phase documentation
- Environment templates
- Backup automation
- Monitoring dashboards
- Security hardening checklists
```

---

## Timeline Estimate

### Week 1: Foundation (Phases 1-3)
- Day 1-2: Planning and documentation
- Day 3-4: PostgreSQL and network setup
- Day 5-7: Deploy Authentik, n8n, RustDesk on Proxmox

### Week 2: Integration (Phases 4-5)
- Day 1-2: VPS services and Pangolin configuration
- Day 3-5: SSO integration and WebAuthn enrollment
- Day 6-7: Testing and troubleshooting

### Week 3: Finalization (Phases 6-7)
- Day 1-3: Monitoring, security hardening, backup automation
- Day 4-5: Complete documentation
- Day 6-7: Comprehensive testing and disaster recovery drill

### Week 4+: Expansion (Phase 8)
- HomeAssistant integration
- Obsidian Livesync deployment
- Additional services as needed

**Note**: This is a methodical, careful rollout. No rushing. Test each phase thoroughly before proceeding.

---

## Success Metrics

### Technical Metrics
- All services accessible externally via SSO
- WebAuthn works on all enrolled devices
- No single service exceeding allocated resources
- VPS CPU/RAM usage under control (<50% / <3GB)
- Backups running successfully (100% success rate)
- All monitoring dashboards populated with data
- Zero unplanned downtime during deployment

### User Experience Metrics
- Single sign-on across all services
- Face ID / Windows Hello authentication works seamlessly
- No password fatigue (SSO handles everything)
- Mobile access to all services via Authentik
- Infrastructure documentation accessible from any device (Obsidian)
- Fast response times (<2s for service access)

### Security Metrics
- All external access requires WebAuthn
- No default passwords remaining
- Fail2ban protecting critical services
- SSL certificates valid and auto-renewing
- Audit logging enabled in Authentik
- Regular backup verification (monthly)

---

## Open Questions / Decisions Needed

### To Decide Before Starting:
- [ ] Confirm domain names to use (auth.domain.com, n8n.domain.com, etc.)
- [ ] LXC containers vs Docker VMs? (Recommendation: LXC for efficiency)
- [ ] Shared PostgreSQL or separate instances? (Recommendation: Shared)
- [ ] Separate VLAN for services? (Recommendation: Yes, if possible)
- [ ] Let's Encrypt via Pangolin or internal CA? (Recommendation: Let's Encrypt)
- [ ] Off-site backup strategy? (Cloud, second location, etc.)

### To Document During Setup:
- [ ] IP addresses assigned to each service
- [ ] Database credentials (store securely)
- [ ] OAuth Client IDs and secrets
- [ ] Authentik admin credentials
- [ ] RustDesk encryption keys (CRITICAL!)
- [ ] Backup schedule and retention
- [ ] Emergency access procedures

---

## Lessons Learned / Notes

### Why Hybrid Architecture?
- VPS is resource-constrained (2 cores / 4GB RAM)
- DL380p has abundant resources (32 cores / 96GB RAM)
- Gerbil tunnels already provide secure connectivity
- Minimizes VPS costs while maximizing home lab utilization
- Services stay responsive (no resource contention on VPS)

### Why Authentik over Alternatives?
- **vs Keycloak**: Much lighter weight (Keycloak needs 1-2GB+ RAM)
- **vs Authelia**: More feature-complete, better app support
- Native WebAuthn/FIDO2 support
- Modern UI
- Active development
- Good documentation
- Self-hosted (privacy and control)

### Why LXC Containers?
- More efficient than VMs (less overhead)
- Native Proxmox integration
- Easier backups and snapshots
- Better resource utilization
- Faster boot times
- Still provides isolation

### Why Shared PostgreSQL?
- Single database server to manage
- Easier backups (one dump for all databases)
- Resource efficiency (connection pooling)
- Simpler monitoring
- Adequate for home lab scale
- Can migrate to separate instances later if needed

---

## Reference Links

### Tools & Services
- **Claude Code**: https://docs.claude.com/en/docs/claude-code
- **Authentik**: https://goauthentik.io/
- **n8n**: https://n8n.io/
- **RustDesk**: https://rustdesk.com/
- **Obsidian**: https://obsidian.md/
- **Prometheus**: https://prometheus.io/
- **Grafana**: https://grafana.com/

### Documentation Created
- CLAUDE.md - Repository guidance for Claude Code
- RUNBOOK.md - Operational procedures
- DISASTER-RECOVERY.md - Recovery procedures
- SERVICES.md - Service configuration templates
- IMPROVEMENTS.md - Infrastructure recommendations
- MONITORING.md - Monitoring setup guide
- infrastructure-audit.md - Infrastructure audit checklist
- Infrastructure-Implementation-Checklist.md - Complete deployment checklist

### Automation Scripts
- backup-proxmox.sh - VM/container backups
- backup-vps.sh - VPS configuration backups
- health-check.sh - Service health monitoring
- cert-check.sh - SSL certificate expiration
- tunnel-monitor.sh - Gerbil tunnel monitoring
- resource-report.sh - Weekly resource reports

---

## Next Immediate Actions

1. **Review and finalize architecture decisions**
   - Confirm domain names
   - Decide on LXC vs Docker
   - Plan network/VLAN layout

2. **Start with Claude Code project structure**
   ```bash
   cd ~/proxmox-infrastructure
   claude
   /init Create comprehensive project structure...
   ```

3. **Fill out infrastructure audit checklist**
   - Current VPS details
   - Proxmox network configuration
   - Available IP addresses
   - DNS provider details

4. **Set up Obsidian for documentation**
   - Install on Mac Pro
   - Import implementation checklist
   - Begin checking off tasks as completed

5. **Begin Phase 1: Planning & Preparation**
   - Document current state
   - Make final decisions
   - Create project scaffolding

---

**Status**: Ready to begin implementation!
**Excitement Level**: 🚀🚀🚀

**Last Updated**: 2025-10-28
