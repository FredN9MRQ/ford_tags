# Infrastructure Improvement Recommendations

Based on the infrastructure audit checklist, this document outlines recommended improvements for security, reliability, and operational efficiency.

## Table of Contents
- [High Priority Improvements](#high-priority-improvements)
- [Security Enhancements](#security-enhancements)
- [Reliability & Availability](#reliability--availability)
- [Monitoring & Observability](#monitoring--observability)
- [Automation Opportunities](#automation-opportunities)
- [Documentation & Knowledge Management](#documentation--knowledge-management)
- [Capacity Planning](#capacity-planning)
- [Cost Optimization](#cost-optimization)

---

## High Priority Improvements

### 1. Implement Automated Backups

**Current State**: Manual or ad-hoc backups
**Target State**: Automated, scheduled backups with verification

**Action Items**:
- [ ] Set up automated Proxmox VM/Container backups (see `scripts/backup-proxmox.sh`)
- [ ] Configure automatic backup of VPS configurations
- [ ] Implement off-site backup sync (to cloud storage or remote location)
- [ ] Schedule regular backup restoration tests
- [ ] Set up backup monitoring and alerting

**Priority**: 🔴 Critical
**Estimated Effort**: 4-8 hours
**Benefits**: Data loss prevention, faster disaster recovery

---

### 2. SSL Certificate Auto-Renewal

**Current State**: Manual certificate management
**Target State**: Automated certificate renewal with monitoring

**Action Items**:
- [ ] Install and configure certbot with auto-renewal
- [ ] Set up certbot systemd timer: `systemctl enable certbot.timer`
- [ ] Configure renewal hooks to reload services
- [ ] Monitor certificate expiration dates
- [ ] Consider wildcard certificates to simplify management

**Priority**: 🔴 Critical
**Estimated Effort**: 2-4 hours
**Benefits**: Prevent service outages from expired certificates

**Implementation**:
```bash
# Enable auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Test renewal
sudo certbot renew --dry-run

# Add renewal hook for Pangolin
echo "systemctl reload pangolin" | sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-pangolin.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-pangolin.sh
```

---

### 3. Implement Basic Monitoring

**Current State**: No centralized monitoring
**Target State**: Uptime monitoring with alerts for critical services

**Action Items**:
- [ ] Deploy Uptime Kuma for service monitoring (lightweight, easy to set up)
- [ ] Configure health checks for all public services
- [ ] Set up alerting (email, SMS, or Slack)
- [ ] Monitor VPS resources (CPU, RAM, disk)
- [ ] Monitor Proxmox node resources
- [ ] Track Gerbil tunnel status

**Priority**: 🟠 High
**Estimated Effort**: 4-6 hours
**Benefits**: Early detection of issues, reduced downtime

See [MONITORING.md](MONITORING.md) for detailed setup instructions.

---

## Security Enhancements

### 4. Harden SSH Access

**Recommendations**:
- [ ] Disable password authentication (key-only)
- [ ] Change default SSH port on VPS
- [ ] Implement fail2ban for brute force protection
- [ ] Use SSH certificate authority for easier key management
- [ ] Enable 2FA for SSH (Google Authenticator)

**Implementation**:
```bash
# /etc/ssh/sshd_config
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
Port 2222    # Non-standard port

# Install fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

**Priority**: 🟠 High
**Estimated Effort**: 2-3 hours

---

### 5. Implement Network Segmentation

**Current State**: Flat network
**Target State**: VLANs separating different service tiers

**Recommendations**:
- [ ] VLAN 10: Management (Proxmox, OMV admin interfaces)
- [ ] VLAN 20: Production Services
- [ ] VLAN 30: Development/Testing
- [ ] VLAN 40: IoT/Untrusted devices
- [ ] Configure firewall rules between VLANs

**Priority**: 🟡 Medium
**Estimated Effort**: 8-12 hours
**Benefits**: Improved security, network isolation, easier troubleshooting

---

### 6. Secrets Management

**Current State**: Credentials in config files or documentation
**Target State**: Centralized secrets management

**Recommendations**:
- [ ] Use environment variables for sensitive data
- [ ] Implement Bitwarden/Vaultwarden for password management
- [ ] Consider HashiCorp Vault for API keys and certificates
- [ ] Encrypt sensitive files with GPG or age
- [ ] Never commit secrets to git

**Priority**: 🟠 High
**Estimated Effort**: 4-6 hours

---

### 7. Regular Security Updates

**Recommendations**:
- [ ] Enable unattended-upgrades for security patches
- [ ] Schedule monthly maintenance windows for updates
- [ ] Subscribe to security mailing lists for critical software
- [ ] Implement vulnerability scanning

**Implementation**:
```bash
# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

**Priority**: 🟠 High
**Estimated Effort**: 2-3 hours

---

## Reliability & Availability

### 8. Implement High Availability for Critical Services

**Recommendations**:
- [ ] Run critical services on both Proxmox nodes
- [ ] Set up floating IP or load balancing
- [ ] Configure automatic failover
- [ ] Use Proxmox HA features for critical VMs

**Priority**: 🟡 Medium
**Estimated Effort**: 8-16 hours

---

### 9. Backup VPS Provider Relationship

**Recommendations**:
- [ ] Document procedures for spinning up with alternate VPS provider
- [ ] Keep configuration backups accessible outside primary VPS
- [ ] Test VPS migration annually
- [ ] Consider multi-region deployment for critical services

**Priority**: 🟡 Medium
**Estimated Effort**: 4-6 hours

---

### 10. UPS and Power Management

**Recommendations**:
- [ ] Install UPS on all Proxmox nodes
- [ ] Configure Network UPS Tools (NUT) for graceful shutdown
- [ ] Test power failure procedures
- [ ] Document power-on sequence after outage

**Priority**: 🟠 High (if not already implemented)
**Estimated Effort**: 3-4 hours (plus hardware cost)

---

## Monitoring & Observability

### 11. Comprehensive Monitoring Stack

**Recommendations**:
- [ ] Deploy Prometheus for metrics collection
- [ ] Set up Grafana for visualization
- [ ] Configure Loki for log aggregation
- [ ] Implement Alertmanager for alerting
- [ ] Create dashboards for key metrics

**Dashboards to Create**:
- VPS resource utilization
- Proxmox cluster overview
- Storage capacity trends
- Service uptime and response times
- Gerbil tunnel status

**Priority**: 🟡 Medium
**Estimated Effort**: 12-16 hours
**See**: [MONITORING.md](MONITORING.md)

---

### 12. Centralized Logging

**Recommendations**:
- [ ] Aggregate logs from all services to central location
- [ ] Implement log retention policies
- [ ] Set up log-based alerts for errors
- [ ] Create log analysis dashboards

**Priority**: 🟡 Medium
**Estimated Effort**: 6-8 hours

---

## Automation Opportunities

### 13. Infrastructure as Code

**Current State**: Manual configuration
**Target State**: Automated, version-controlled infrastructure

**Recommendations**:
- [ ] Document VPS setup as Ansible playbooks
- [ ] Use Terraform for DNS and cloud resources
- [ ] Create Proxmox VM templates with cloud-init
- [ ] Version control all automation

**Priority**: 🟡 Medium
**Estimated Effort**: 16-24 hours
**Benefits**: Reproducible infrastructure, faster recovery, documentation

---

### 14. Automated Health Checks

**Recommendations**:
- [ ] Create scheduled health check scripts (see `scripts/health-check.sh`)
- [ ] Automated service restart on failure
- [ ] Self-healing for common issues
- [ ] Integration with monitoring system

**Priority**: 🟡 Medium
**Estimated Effort**: 4-6 hours

---

### 15. Certificate Management Automation

**Recommendations**:
- [ ] Automate certificate deployment to all services
- [ ] Automated service reloads after certificate renewal
- [ ] Certificate expiration monitoring
- [ ] Automated DNS validation for wildcard certs

**Priority**: 🟠 High
**Estimated Effort**: 3-4 hours

---

## Documentation & Knowledge Management

### 16. Living Documentation

**Current State**: Basic documentation
**Target State**: Comprehensive, up-to-date documentation

**Action Items**:
- [x] Complete infrastructure audit checklist
- [x] Create RUNBOOK.md with operational procedures
- [x] Create DISASTER-RECOVERY.md
- [x] Create SERVICES.md
- [ ] Fill in all service details in SERVICES.md
- [ ] Document network topology diagram
- [ ] Create quick reference cards for common tasks
- [ ] Schedule quarterly documentation reviews

**Priority**: 🟠 High
**Estimated Effort**: Ongoing

---

### 17. Runbook Automation

**Recommendations**:
- [ ] Convert manual procedures to scripts where possible
- [ ] Create interactive troubleshooting guides
- [ ] Document lessons learned from incidents
- [ ] Share knowledge across team

**Priority**: 🟡 Medium
**Estimated Effort**: Ongoing

---

## Capacity Planning

### 18. Resource Monitoring and Trending

**Recommendations**:
- [ ] Track resource utilization over time
- [ ] Set up alerts for capacity thresholds (80%, 90%)
- [ ] Create capacity planning reports
- [ ] Plan for growth based on trends

**Metrics to Track**:
- CPU utilization per node
- RAM usage per node
- Storage growth rate (OMV)
- Network bandwidth utilization
- Number of VMs/containers

**Priority**: 🟡 Medium
**Estimated Effort**: 4-6 hours (plus ongoing)

---

### 19. Resource Right-Sizing

**Recommendations**:
- [ ] Review VM/container resource allocations
- [ ] Identify over-provisioned VMs
- [ ] Identify resource-constrained VMs
- [ ] Adjust allocations based on actual usage

**Priority**: 🟢 Low
**Estimated Effort**: 2-4 hours

---

## Cost Optimization

### 20. VPS Cost Review

**Recommendations**:
- [ ] Compare current VPS pricing with alternatives
- [ ] Consider reserved instances or annual billing
- [ ] Evaluate if all VPS resources are utilized
- [ ] Review bandwidth usage and overage costs

**Priority**: 🟢 Low
**Estimated Effort**: 2-3 hours

---

### 21. Power Consumption Optimization

**Recommendations**:
- [ ] Enable CPU power management features
- [ ] Schedule non-critical services for off-peak hours
- [ ] Consider shutting down development VMs overnight
- [ ] Monitor power consumption

**Priority**: 🟢 Low
**Estimated Effort**: 3-4 hours

---

## Implementation Roadmap

### Phase 1: Critical (Weeks 1-2)
1. Automated backups with off-site storage
2. SSL certificate auto-renewal
3. SSH hardening and fail2ban
4. Basic uptime monitoring

### Phase 2: High Priority (Weeks 3-6)
1. Comprehensive monitoring stack
2. Security updates automation
3. Secrets management
4. Documentation completion
5. Health check automation

### Phase 3: Medium Priority (Weeks 7-12)
1. Network segmentation with VLANs
2. High availability for critical services
3. Infrastructure as Code implementation
4. Centralized logging
5. Capacity planning processes

### Phase 4: Ongoing
1. Regular security audits
2. Documentation maintenance
3. Performance optimization
4. Cost reviews
5. DR testing

---

## Success Metrics

Track the following to measure improvement:

| Metric | Current | Target |
|--------|---------|--------|
| Mean Time To Recovery (MTTR) | _____ | < 1 hour |
| Backup success rate | _____ | 100% |
| Service uptime | _____ | 99.9% |
| Certificate renewal failures | _____ | 0 |
| Security patches applied within | _____ | 7 days |
| Unplanned outages per month | _____ | < 1 |
| Time to detect issues | _____ | < 5 minutes |

---

## Notes

- Prioritize improvements based on your specific needs and risk tolerance
- Review and update this document quarterly
- Track implementation progress
- Measure impact of improvements

**Last Updated**: _____________
**Next Review**: _____________
**Version**: 1.0
