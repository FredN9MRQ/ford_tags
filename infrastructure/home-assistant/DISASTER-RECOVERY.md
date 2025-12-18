# Disaster Recovery Plan

This document outlines procedures for recovering from various disaster scenarios affecting your infrastructure.

## Table of Contents
- [Emergency Contact Information](#emergency-contact-information)
- [Recovery Time Objectives](#recovery-time-objectives)
- [Backup Locations](#backup-locations)
- [Disaster Scenarios](#disaster-scenarios)
- [Recovery Procedures](#recovery-procedures)
- [Post-Recovery Checklist](#post-recovery-checklist)

---

## Emergency Contact Information

### Primary Contacts
| Role | Name | Phone | Email | Availability |
|------|------|-------|-------|--------------|
| Infrastructure Owner | _____________ | _____________ | _____________ | 24/7 |
| Network Admin | _____________ | _____________ | _____________ | Business Hours |
| Backup Contact | _____________ | _____________ | _____________ | 24/7 |

### Service Provider Contacts
| Provider | Service | Support Number | Account ID | Notes |
|----------|---------|----------------|------------|-------|
| VPS Provider | _____________ | _____________ | _____________ | _____________ |
| DNS Provider | _____________ | _____________ | _____________ | _____________ |
| Domain Registrar | _____________ | _____________ | _____________ | _____________ |
| ISP (Home Lab) | _____________ | _____________ | _____________ | _____________ |

---

## Recovery Time Objectives

Define acceptable downtime for each service tier:

| Tier | Service Type | RTO (Recovery Time Objective) | RPO (Recovery Point Objective) |
|------|-------------|------------------------------|--------------------------------|
| Critical | Public-facing services, Authentication | 1 hour | 15 minutes |
| Important | Internal services, Databases | 4 hours | 1 hour |
| Standard | Development, Testing | 24 hours | 24 hours |
| Low Priority | Monitoring, Logging | 48 hours | 24 hours |

---

## Backup Locations

### Primary Backup Location
- **Location**: _____________ (e.g., OMV storage node, external drive)
- **Path**: _____________
- **Retention**: _____________
- **Access Method**: _____________

### Secondary Backup Location (Off-site)
- **Location**: _____________ (e.g., Cloud storage, remote server)
- **Path**: _____________
- **Retention**: _____________
- **Access Method**: _____________

### Backup Schedule
- **Proxmox VMs/Containers**: Daily at _____
- **Configuration Files**: Weekly on _____
- **Critical Data**: Hourly/Daily
- **Off-site Sync**: Daily/Weekly

### Critical Items to Backup
- [ ] Proxmox VM/Container configurations and disks
- [ ] Pangolin reverse proxy configurations
- [ ] Gerbil tunnel configurations and keys
- [ ] SSL/TLS certificates and keys
- [ ] SSH keys and authorized_keys files
- [ ] Network configuration files
- [ ] DNS zone files (if self-hosted)
- [ ] Database dumps
- [ ] Application data and configurations
- [ ] Documentation and credentials (encrypted)

---

## Disaster Scenarios

### Scenario 1: VPS Complete Failure

**Impact**: All public-facing services down, no external access to home lab services

**Recovery Procedure**:
1. **Immediate Actions (0-15 minutes)**
   - Verify VPS is actually down (ping, SSH, web checks)
   - Contact VPS provider support
   - Check VPS provider status page
   - Notify users if necessary

2. **Short-term Mitigation (15-60 minutes)**
   - If hardware failure, request provider rebuild
   - If account issue, resolve with provider
   - Consider spinning up temporary VPS with another provider

3. **VPS Rebuild (1-4 hours)**
   ```bash
   # On new VPS:

   # 1. Update system
   sudo apt update && sudo apt upgrade -y

   # 2. Install Pangolin
   # [Installation commands]

   # 3. Restore Pangolin configuration from backup
   scp backup-server:/backups/pangolin-config.tar.gz .
   sudo tar -xzf pangolin-config.tar.gz -C /

   # 4. Install Gerbil server
   # [Installation commands]

   # 5. Restore Gerbil configuration
   scp backup-server:/backups/gerbil-config.tar.gz .
   sudo tar -xzf gerbil-config.tar.gz -C /

   # 6. Restore SSL certificates
   sudo tar -xzf ssl-certs-backup.tar.gz -C /etc/letsencrypt/

   # 7. Configure firewall
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow [GERBIL_PORT]/tcp
   sudo ufw enable

   # 8. Start services
   sudo systemctl enable --now pangolin
   sudo systemctl enable --now gerbil

   # 9. Update DNS A record to new VPS IP
   # [DNS provider steps]

   # 10. Reconnect Gerbil tunnels from home lab
   # [See Gerbil reconnection below]
   ```

4. **Verification**
   - Test all public routes
   - Verify Gerbil tunnels are connected
   - Check SSL certificates are valid
   - Monitor logs for errors

---

### Scenario 2: Home Lab Network Outage

**Impact**: All home lab services unreachable, Gerbil tunnels down

**Recovery Procedure**:
1. **Immediate Actions (0-15 minutes)**
   - Check router/modem status
   - Verify ISP is not having outage
   - Check physical connections
   - Reboot router/modem if necessary

2. **ISP Outage (Variable duration)**
   - Contact ISP support
   - Consider failover to mobile hotspot if critical
   - Notify users of expected downtime

3. **Restore Gerbil Tunnels**
   ```bash
   # On each home lab machine with tunnels:

   # 1. Verify local services are running
   systemctl status [service-name]

   # 2. Test VPS connectivity
   ping [VPS_IP]

   # 3. Restart Gerbil tunnels
   sudo systemctl restart gerbil-tunnel-*

   # 4. Verify tunnels are connected
   gerbil status

   # 5. Check logs for errors
   journalctl -u gerbil-tunnel-* -n 50
   ```

---

### Scenario 3: Proxmox Node Failure (DL380p or i5)

**Impact**: All VMs/containers on failed node are down

**Recovery Procedure**:
1. **Immediate Actions (0-30 minutes)**
   - Identify which node has failed
   - Determine cause (power, hardware, network)
   - Check if other cluster nodes are healthy

2. **If Node Can Be Recovered**
   ```bash
   # Try to boot node
   # If successful, check cluster status:
   pvecm status

   # Check VM/Container status
   qm list
   pct list

   # Start critical VMs/Containers
   qm start VMID
   pct start CTID
   ```

3. **If Node Cannot Be Recovered - Migrate Services**
   ```bash
   # On working node:

   # 1. Check available resources
   pvesh get /nodes/NODE/status

   # 2. Restore VMs from backup to working node
   qmrestore /path/to/backup/vzdump-qemu-VMID.vma.zst NEW_VMID --storage local-lvm

   # 3. Restore containers from backup
   pct restore NEW_CTID /path/to/backup/vzdump-lxc-CTID.tar.zst --storage local-lvm

   # 4. Start restored VMs/containers
   qm start NEW_VMID
   pct start NEW_CTID

   # 5. Update internal DNS/documentation with new IPs if changed
   ```

4. **Resource Constraints**
   - If insufficient resources on remaining node:
     - Prioritize critical services only
     - Consider scaling down VM resources temporarily
     - Plan for hardware replacement/repair

---

### Scenario 4: Storage Node (OMV) Failure

**Impact**: Shared storage unavailable, backups inaccessible, data loss risk

**Recovery Procedure**:
1. **Immediate Actions (0-30 minutes)**
   - Verify storage node is down
   - Check if disks are healthy (if node boots)
   - Identify affected services using shared storage

2. **If Disk Failure**
   - Check RAID status (if configured)
   - Replace failed disk
   - Rebuild RAID array
   - Restore from off-site backup if necessary

3. **If Complete Storage Loss**
   ```bash
   # 1. Rebuild OMV on new hardware/disks
   # [OMV installation]

   # 2. Configure network shares
   # [NFS/CIFS setup]

   # 3. Restore data from off-site backup
   rsync -avz backup-location:/backups/ /mnt/storage/

   # 4. Remount shares on Proxmox nodes
   # Update /etc/fstab on each node
   mount -a

   # 5. Verify Proxmox can access storage
   pvesm status
   ```

---

### Scenario 5: DNS Provider Failure

**Impact**: Domain not resolving, all services unreachable by domain name

**Recovery Procedure**:
1. **Immediate Actions (0-15 minutes)**
   - Check DNS provider status page
   - Test DNS resolution: `nslookup domain.com`
   - Verify it's provider issue, not configuration

2. **Short-term Mitigation (15-60 minutes)**
   - Share direct IP addresses with users temporarily
   - Set up temporary DNS using Cloudflare (free tier)

3. **Migrate to New DNS Provider**
   ```bash
   # 1. Export zone file from old provider (if possible)

   # 2. Create account with new DNS provider

   # 3. Import zone file or manually create records:
   # A record: domain.com -> VPS_IP
   # A record: *.domain.com -> VPS_IP (if using wildcard)
   # Other records as needed

   # 4. Update nameservers at domain registrar
   # (Propagation takes 24-48 hours)

   # 5. Monitor DNS propagation
   dig domain.com @8.8.8.8
   ```

---

### Scenario 6: Complete Data Center Loss (Home Lab)

**Impact**: All home lab infrastructure destroyed (fire, flood, etc.)

**Recovery Procedure**:
1. **Immediate Actions**
   - Ensure safety of personnel
   - Contact insurance provider
   - Assess extent of damage
   - Secure remaining equipment

2. **Short-term (Services that must continue)**
   - Move critical services to VPS temporarily
   - Use cloud providers for temporary hosting
   - Restore from off-site backups

3. **Long-term (Infrastructure Rebuild)**
   - Procure replacement hardware
   - Rebuild Proxmox cluster
   - Restore VMs/containers from off-site backups
   - Reconfigure network
   - Re-establish Gerbil tunnels
   - Full testing and verification

---

## Recovery Procedures

### General Recovery Steps

1. **Assess the Situation**
   - Identify what has failed
   - Determine scope of impact
   - Estimate recovery time

2. **Communicate**
   - Notify affected users
   - Update status page if available
   - Keep stakeholders informed

3. **Prioritize**
   - Focus on critical services first
   - Use RTO/RPO objectives
   - Document decisions

4. **Execute Recovery**
   - Follow specific scenario procedures
   - Document all actions taken
   - Keep logs of commands executed

5. **Verify**
   - Test all restored services
   - Check data integrity
   - Monitor for issues

6. **Document**
   - Record what happened
   - Document what worked/didn't work
   - Update this document with lessons learned

---

## Post-Recovery Checklist

After any disaster recovery, complete the following:

### Immediate Post-Recovery (0-24 hours)
- [ ] All critical services are operational
- [ ] All services are monitored
- [ ] Temporary workarounds documented
- [ ] Incident logged with timeline

### Short-term (1-7 days)
- [ ] All services fully restored
- [ ] Performance is normal
- [ ] Backups are running
- [ ] Security review completed
- [ ] Post-mortem meeting scheduled

### Long-term (1-4 weeks)
- [ ] Post-mortem completed
- [ ] Lessons learned documented
- [ ] Disaster recovery plan updated
- [ ] Preventive measures implemented
- [ ] Training updated if needed
- [ ] Backup/monitoring improvements made

---

## Post-Mortem Template

After each disaster recovery event, complete a post-mortem:

**Incident Date**: _____________
**Recovery Completed**: _____________
**Total Downtime**: _____________

### What Happened?
[Detailed description of the incident]

### Timeline
| Time | Event |
|------|-------|
| _____ | _____ |
| _____ | _____ |

### Root Cause
[What caused the failure?]

### What Went Well?
-
-

### What Went Poorly?
-
-

### Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| _______ | _____ | ________ | ______ |

### Improvements to This Plan
[What should be updated in the disaster recovery plan?]

---

## Testing Schedule

Regular disaster recovery testing ensures procedures work when needed:

| Test Type | Frequency | Last Test | Next Test | Status |
|-----------|-----------|-----------|-----------|--------|
| Backup restore test | Quarterly | _________ | _________ | ______ |
| VPS failover drill | Semi-annually | _________ | _________ | ______ |
| Node failure simulation | Annually | _________ | _________ | ______ |
| Full DR scenario | Annually | _________ | _________ | ______ |

---

## Document Maintenance

**Last Updated**: _____________
**Updated By**: _____________
**Next Review Date**: _____________
**Version**: 1.0
