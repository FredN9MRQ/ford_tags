# Homelab 3-Tier Backup Strategy

**Comprehensive Disaster Recovery Plan**

**Created:** 2025-12-25
**Backup Target:** OMV Storage (10.0.10.5) - 12TB

---

## 🎯 Backup Philosophy

**3-2-1 Rule Enhanced:**
- **3** copies of data (Production + 2 backups)
- **2** different media types (Local disk + Cloud)
- **1** copy offsite (Cloud or remote location)
- **+1** EXTRA: Immutable/versioned backups

**Recovery Time Objective (RTO):** 4-8 hours (full rebuild)
**Recovery Point Objective (RPO):** 24 hours (daily backups)

---

## 📊 Infrastructure Inventory

### Main-PVE (10.0.10.3) - Primary Workload Host
**VMs:**
- `110` - debian (10GB)

**Containers:**
- `102` - postgresql ⭐ CRITICAL (databases for all services)
- `103` - bar-assistant
- `105` - ollama (AI models)
- `106` - n8n ⭐ CRITICAL (workflows)
- `108` - pelican-panel
- `109` - pelican-wings
- `113/114` - twingate-connector
- `115` - ca-server ⭐ CRITICAL (certificate authority)
- `121` - authentik ⭐ CRITICAL (SSO/authentication)
- `123` - rustdesk (remote desktop)
- `125` - prometheus (monitoring)
- `200` - obsidian-livesync

**Estimated Total:** ~150GB

### PVE-Router (10.0.10.2) - Office Network Host
**VMs:**
- `104` - haos16.2 ⭐ CRITICAL (Home Assistant - 32GB)

**Containers:**
- `100` - pve-scripts-local
- `101` - docker
- `107` - dockge

**Estimated Total:** ~50GB

### PVE-Storage (10.0.10.4) - Backup Target Host
**VMs:**
- `400` - OMV ⭐ CRITICAL (12TB storage - NOT backed up itself)

**Note:** OMV acts as backup destination, not source

### VPS (66.63.182.168) - Public Services
**Services:**
- Caddy reverse proxy ⭐ CRITICAL
- RustDesk relay server
- WireGuard VPN server ⭐ CRITICAL

**Estimated Total:** ~5GB

---

## 🗂️ What to Backup

### Tier 1: CRITICAL (Cannot operate without)
**Priority: DAILY backups, keep 7 days + 4 weeklies**

1. **PostgreSQL Database** (Container 102)
   - All databases: authentik, n8n, grafana
   - Dump format: SQL + custom format
   - ~2-5GB

2. **Authentik** (Container 121)
   - Database (in PostgreSQL)
   - Media files (/media)
   - Blueprints/configurations
   - ~500MB

3. **n8n Workflows** (Container 106)
   - Database (in PostgreSQL)
   - Workflow exports (JSON)
   - Credentials (encrypted)
   - ~1GB

4. **Home Assistant** (VM 104)
   - Full VM backup
   - configuration.yaml + all configs
   - Automations, scripts, scenes
   - ~32GB VM + 500MB configs

5. **Certificate Authority** (Container 115)
   - All certificates and keys
   - CA private key ⭐ MOST CRITICAL
   - ~100MB

6. **VPS Configurations**
   - Caddyfile
   - WireGuard config
   - SSL certificates
   - Service configs
   - ~500MB

7. **SSH Keys & Secrets**
   - All SSH private/public keys
   - API tokens
   - Service credentials
   - ~10MB

### Tier 2: IMPORTANT (Significant effort to recreate)
**Priority: WEEKLY backups, keep 4 weeks + 6 monthlies**

1. **Prometheus/Grafana** (Container 125)
   - Dashboards (JSON exports)
   - Alert rules
   - Configuration
   - Metrics data (optional - large)
   - ~10GB without metrics, ~100GB with

2. **Ollama** (Container 105)
   - Downloaded AI models
   - Model configurations
   - ~20-50GB (varies by models)

3. **All Other Containers**
   - Configuration files
   - Application data
   - ~20GB total

4. **Proxmox Configurations**
   - Node configs (/etc/pve)
   - Network configs
   - Storage configs
   - ~100MB

### Tier 3: NICE TO HAVE (Can be recreated from docs/internet)
**Priority: MONTHLY backups, keep 3 months**

1. **Container Templates**
   - LXC templates
   - ~2GB

2. **ISO Images**
   - OS installation ISOs
   - ~10GB

3. **Documentation**
   - Already in GitHub ✅
   - Local copies for redundancy
   - ~50MB

---

## 🏗️ 3-Tier Backup Architecture

### **TIER 1: Local Backups (OMV - 10.0.10.5)**
**Purpose:** Fast recovery, primary backup location
**Storage:** 12TB available
**Retention:** 7 days daily + 4 weeks weekly + 3 months monthly

**Advantages:**
- ✅ Fast backup (1Gbps LAN)
- ✅ Fast recovery (local network)
- ✅ Large capacity
- ✅ No cloud costs

**Disadvantages:**
- ❌ Same physical location (fire/flood risk)
- ❌ Same power source
- ❌ Requires separate offsite strategy

**Backup Path Structure:**
```
/mnt/backups/  (OMV NFS share)
├── proxmox/
│   ├── main-pve/
│   │   ├── daily/
│   │   │   ├── 2025-12-25/
│   │   │   │   ├── vzdump-lxc-102-*.tar.gz
│   │   │   │   ├── vzdump-lxc-121-*.tar.gz
│   │   │   │   └── ...
│   │   ├── weekly/
│   │   └── monthly/
│   ├── pve-router/
│   └── pve-storage/
├── databases/
│   ├── postgresql/
│   │   ├── daily/
│   │   │   ├── 2025-12-25_all_databases.sql
│   │   │   ├── 2025-12-25_authentik.dump
│   │   │   └── 2025-12-25_n8n.dump
│   │   └── weekly/
│   └── mysql/ (if applicable)
├── configs/
│   ├── vps/
│   │   ├── caddy/
│   │   ├── wireguard/
│   │   └── ssl/
│   ├── home-assistant/
│   ├── authentik/
│   └── prometheus/
├── keys/
│   ├── ssh/
│   ├── ssl/
│   └── ca/
└── application-data/
    ├── n8n/
    ├── grafana/
    └── ollama/
```

### **TIER 2: Off-Site Backup (External Drive or Remote Location)**
**Purpose:** Protection from local disasters
**Storage:** External HDD/SSD (2-4TB)
**Retention:** Weekly snapshots, 8 weeks

**Options:**
1. **External Drive at Different Location**
   - Weekly: Take drive to office/friend's house
   - Rotate 2 drives for continuous protection
   - Cost: ~$150 for 2x 2TB drives

2. **Remote Sync to Friend/Family**
   - If you have trusted person with server
   - Encrypted sync via rsync/restic
   - Cost: Free (reciprocal arrangement)

3. **Secondary OMV at Different Location**
   - If you have second property
   - Automated sync
   - Cost: $200-300 for small NAS

**Recommended:** Option 1 (External drives) for cost/simplicity

### **TIER 3: Cloud Backup (Encrypted)**
**Purpose:** Ultimate disaster protection, geographic diversity
**Storage:** Cloud provider (Backblaze B2, Wasabi, AWS S3 Glacier)
**Retention:** Monthly snapshots, 6-12 months

**Recommended Provider: Backblaze B2**
- **Cost:** $6/TB/month storage + $0.01/GB download
- **Estimated:** ~$30-50/month for 100-200GB critical data
- **Features:** S3-compatible, no egress fees for first 3x stored data

**Alternative: Wasabi**
- **Cost:** $6.99/TB/month, no egress fees
- **Minimum:** 1TB commitment
- **Good if:** Planning to backup 500GB+

**Budget Option: Google Drive**
- **Cost:** $10/month for 2TB (Google One)
- **Pros:** Cheap, easy to use
- **Cons:** Not ideal for automated backups, terms of service

**What Goes to Cloud:**
- ✅ Database dumps (compressed)
- ✅ Critical configs
- ✅ SSH keys (encrypted)
- ✅ CA certificates
- ✅ Application configs
- ❌ Full VM backups (too large/expensive)
- ❌ Ollama models (can re-download)
- ❌ ISO files (can re-download)

**Encryption:**
- All cloud backups encrypted with Restic or Borg
- Keys stored securely (password manager + paper backup)

---

## 🔄 Backup Schedule

### Daily (Automated - 2:00 AM)
**Runs on:** All Proxmox hosts
**Target:** OMV NFS share
**Retention:** Keep 7 days

```
02:00 - PostgreSQL dump (all databases)
02:15 - Critical container backups (authentik, n8n, ca-server)
02:45 - Home Assistant VM backup
03:30 - Config file sync (VPS, containers)
04:00 - Verify backups, send notification
```

### Weekly (Automated - Sunday 3:00 AM)
**Runs on:** All Proxmox hosts
**Target:** OMV + Off-site preparation
**Retention:** Keep 4 weeks on OMV, copy to external drive monthly

```
03:00 - Full VM backups (all VMs)
04:00 - All container backups
05:00 - Prometheus/Grafana export
06:00 - Sync to off-site staging area
07:00 - Verify, send summary email
```

### Monthly (Automated - 1st of month, 4:00 AM)
**Runs on:** All Proxmox hosts
**Target:** OMV + Cloud (encrypted)
**Retention:** Keep 3 months on OMV, 12 months in cloud

```
04:00 - Full infrastructure backup
05:00 - Compress and encrypt for cloud
06:00 - Upload to Backblaze B2
08:00 - Verify cloud backup integrity
09:00 - Send monthly backup report
```

### Manual (As Needed)
- Before major changes
- Before Proxmox/system updates
- After significant configuration changes

---

## 🛠️ Backup Tools & Technologies

### Proxmox VE Backup (vzdump)
**Purpose:** VM and container backups
**Features:**
- Snapshot-based (minimal downtime)
- Compression (gzip, lzo, zstd)
- Retention policies
- Verification

**Command Example:**
```bash
vzdump 102 --storage local --mode snapshot --compress zstd --remove 0
```

### PostgreSQL pg_dump
**Purpose:** Database backups
**Features:**
- Consistent snapshots
- Custom format (smaller, faster restore)
- SQL format (human-readable, portable)

**Command Example:**
```bash
pg_dump -U postgres -F c -f /backup/authentik_$(date +%Y%m%d).dump authentik
```

### Restic
**Purpose:** Encrypted cloud backups
**Features:**
- Deduplication
- Encryption (AES-256)
- Incremental backups
- Multiple backends (B2, S3, SFTP)
- Verification

**Command Example:**
```bash
restic -r b2:homelab-backup backup /mnt/backups/critical
```

### Rsync
**Purpose:** Config file sync, off-site sync
**Features:**
- Fast incremental sync
- Preserve permissions
- Compression
- Checksum verification

**Command Example:**
```bash
rsync -avz --delete /mnt/backups/ /mnt/offsite/
```

### Borg Backup (Alternative to Restic)
**Purpose:** Encrypted deduplicated backups
**Features:**
- Better compression
- Faster than Restic
- Append-only mode (ransomware protection)

---

## 📝 Implementation Plan

### Phase 1: Setup OMV Backup Storage (Week 1)
**Duration:** 2-3 hours

1. **Configure OMV NFS Share**
   ```bash
   # On OMV (10.0.10.5)
   mkdir -p /srv/backups
   # Configure via OMV Web UI:
   # Storage → Shared Folders → Add
   # Services → NFS → Add share
   ```

2. **Mount on all Proxmox hosts**
   ```bash
   # On each Proxmox host
   mkdir -p /mnt/omv-backups
   echo "10.0.10.5:/srv/backups /mnt/omv-backups nfs defaults 0 0" >> /etc/fstab
   mount -a
   ```

3. **Test write access**
   ```bash
   touch /mnt/omv-backups/test-$(hostname).txt
   ```

### Phase 2: Automated Proxmox Backups (Week 1-2)
**Duration:** 3-4 hours

1. **Create backup scripts** (see scripts below)
2. **Test manual backups**
3. **Configure cron jobs**
4. **Verify first automated run**

### Phase 3: Database Backup Automation (Week 2)
**Duration:** 2 hours

1. **PostgreSQL backup script**
2. **Test restore procedure**
3. **Automate via cron**

### Phase 4: Config & Application Backups (Week 2-3)
**Duration:** 3-4 hours

1. **VPS backup script**
2. **Container config sync**
3. **Application data exports**

### Phase 5: Cloud Backup Setup (Week 3-4)
**Duration:** 4-5 hours

1. **Choose cloud provider** (Backblaze B2 recommended)
2. **Create bucket**
3. **Install Restic**
4. **Configure encryption**
5. **Test upload/restore**
6. **Automate monthly sync**

### Phase 6: Off-Site Backup (Week 4)
**Duration:** 1 hour + ongoing

1. **Purchase 2x external drives**
2. **Create weekly sync script**
3. **Establish rotation schedule**

### Phase 7: Documentation & Testing (Week 5)
**Duration:** 4-6 hours

1. **Document all procedures**
2. **Create restoration guide**
3. **Test restore procedures**
4. **Schedule quarterly DR tests**

---

## 🔧 Backup Scripts

### 1. Proxmox Backup Script

**Location:** `/usr/local/bin/backup-proxmox-to-omv.sh`

```bash
#!/bin/bash
# Proxmox Backup to OMV
# Backs up all VMs and containers to OMV NFS share

set -e

# Configuration
BACKUP_DIR="/mnt/omv-backups/proxmox/$(hostname)"
DAILY_DIR="$BACKUP_DIR/daily/$(date +%Y-%m-%d)"
WEEKLY_DIR="$BACKUP_DIR/weekly/week-$(date +%U)"
MONTHLY_DIR="$BACKUP_DIR/monthly/$(date +%Y-%m)"
LOG_FILE="/var/log/homelab-backup.log"
RETENTION_DAYS=7
RETENTION_WEEKS=4
RETENTION_MONTHS=3

# Determine backup type
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)

if [ "$DAY_OF_MONTH" == "01" ]; then
    BACKUP_TYPE="monthly"
    TARGET_DIR="$MONTHLY_DIR"
elif [ "$DAY_OF_WEEK" == "7" ]; then
    BACKUP_TYPE="weekly"
    TARGET_DIR="$WEEKLY_DIR"
else
    BACKUP_TYPE="daily"
    TARGET_DIR="$DAILY_DIR"
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting $BACKUP_TYPE backup for $(hostname)"

# Backup all VMs
for vmid in $(qm list | tail -n +2 | awk '{print $1}'); do
    vm_name=$(qm list | grep "^$vmid" | awk '{print $2}')
    log "Backing up VM $vmid ($vm_name)..."

    vzdump $vmid \
        --dumpdir "$TARGET_DIR" \
        --mode snapshot \
        --compress zstd \
        --remove 0 \
        --quiet 1

    if [ $? -eq 0 ]; then
        log "✓ VM $vmid backed up successfully"
    else
        log "✗ VM $vmid backup FAILED"
    fi
done

# Backup all containers
for ctid in $(pct list | tail -n +2 | awk '{print $1}'); then
    ct_name=$(pct list | grep "^$ctid" | awk '{print $3}')
    log "Backing up Container $ctid ($ct_name)..."

    vzdump $ctid \
        --dumpdir "$TARGET_DIR" \
        --mode snapshot \
        --compress zstd \
        --remove 0 \
        --quiet 1

    if [ $? -eq 0 ]; then
        log "✓ Container $ctid backed up successfully"
    else
        log "✗ Container $ctid backup FAILED"
    fi
done

# Cleanup old backups
log "Cleaning up old backups..."

# Daily cleanup
find "$BACKUP_DIR/daily" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null

# Weekly cleanup
find "$BACKUP_DIR/weekly" -type d -mtime +$((RETENTION_WEEKS * 7)) -exec rm -rf {} + 2>/dev/null

# Monthly cleanup
find "$BACKUP_DIR/monthly" -type d -mtime +$((RETENTION_MONTHS * 30)) -exec rm -rf {} + 2>/dev/null

# Calculate backup size
BACKUP_SIZE=$(du -sh "$TARGET_DIR" | awk '{print $1}')
log "Backup complete! Size: $BACKUP_SIZE"

# Send notification (optional - requires mail setup)
# echo "Proxmox backup completed on $(hostname). Size: $BACKUP_SIZE" | mail -s "Backup Success" fred@nianticbooks.com

log "=== Backup complete ==="
```

### 2. PostgreSQL Backup Script

**Location:** `/usr/local/bin/backup-postgresql.sh`

```bash
#!/bin/bash
# PostgreSQL Database Backup
# Backs up all databases from container 102

set -e

BACKUP_DIR="/mnt/omv-backups/databases/postgresql/$(date +%Y-%m-%d)"
LOG_FILE="/var/log/homelab-backup.log"
CONTAINER_ID=102
RETENTION_DAYS=30

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"

log "Starting PostgreSQL backup..."

# Backup all databases (SQL format - portable)
pct exec $CONTAINER_ID -- sudo -u postgres pg_dumpall > "$BACKUP_DIR/all_databases.sql"
log "✓ All databases backed up (SQL format)"

# Backup individual databases (custom format - faster restore)
DATABASES=$(pct exec $CONTAINER_ID -- sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

for db in $DATABASES; do
    db=$(echo $db | tr -d '[:space:]')
    log "Backing up database: $db"

    pct exec $CONTAINER_ID -- sudo -u postgres pg_dump -F c "$db" > "$BACKUP_DIR/${db}.dump"

    if [ $? -eq 0 ]; then
        log "✓ $db backed up successfully"
    else
        log "✗ $db backup FAILED"
    fi
done

# Compress backups
log "Compressing backups..."
cd "$BACKUP_DIR"
tar -czf "../postgresql_$(date +%Y-%m-%d).tar.gz" .
cd ..
rm -rf "$BACKUP_DIR"

# Cleanup old backups
find /mnt/omv-backups/databases/postgresql -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

BACKUP_SIZE=$(du -sh "postgresql_$(date +%Y-%m-%d).tar.gz" | awk '{print $1}')
log "PostgreSQL backup complete! Size: $BACKUP_SIZE"
```

### 3. VPS Configuration Backup Script

**Location (on VPS):** `/usr/local/bin/backup-vps-configs.sh`

```bash
#!/bin/bash
# VPS Configuration Backup
# Backs up critical configs to OMV via rsync

set -e

BACKUP_DIR="/tmp/vps-backup-$(date +%Y-%m-%d)"
OMV_TARGET="root@10.0.10.5:/srv/backups/configs/vps/"
LOG_FILE="/var/log/vps-backup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"

log "Starting VPS configuration backup..."

# Caddy
log "Backing up Caddy configuration..."
cp -r /etc/caddy "$BACKUP_DIR/"

# WireGuard
log "Backing up WireGuard configuration..."
cp -r /etc/wireguard "$BACKUP_DIR/"

# SSL Certificates (from Caddy)
log "Backing up SSL certificates..."
cp -r /var/lib/caddy/.local/share/caddy "$BACKUP_DIR/ssl-certs"

# Systemd services
log "Backing up custom systemd services..."
mkdir -p "$BACKUP_DIR/systemd"
cp /etc/systemd/system/rustdesk-* "$BACKUP_DIR/systemd/" 2>/dev/null || true

# Network configuration
log "Backing up network configuration..."
cp /etc/netplan/* "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/network/interfaces "$BACKUP_DIR/" 2>/dev/null || true

# SSH configuration
log "Backing up SSH configuration..."
cp -r /etc/ssh "$BACKUP_DIR/"

# Installed packages list
log "Saving installed packages list..."
dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt"

# Create archive
log "Creating compressed archive..."
cd /tmp
tar -czf "vps-backup-$(date +%Y-%m-%d).tar.gz" "vps-backup-$(date +%Y-%m-%d)"

# Sync to OMV
log "Syncing to OMV storage..."
rsync -avz "vps-backup-$(date +%Y-%m-%d).tar.gz" "$OMV_TARGET"

# Cleanup
rm -rf "$BACKUP_DIR" "vps-backup-$(date +%Y-%m-%d).tar.gz"

log "VPS backup complete!"
```

### 4. Critical Configs Sync Script

**Location:** `/usr/local/bin/backup-critical-configs.sh`

```bash
#!/bin/bash
# Sync critical configuration files from all containers

set -e

BACKUP_ROOT="/mnt/omv-backups/configs"
DATE=$(date +%Y-%m-%d)
LOG_FILE="/var/log/homelab-backup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Authentik (Container 121)
log "Backing up Authentik configs..."
mkdir -p "$BACKUP_ROOT/authentik/$DATE"
pct exec 121 -- tar -czf - /media /blueprints > "$BACKUP_ROOT/authentik/$DATE/authentik-data.tar.gz" 2>/dev/null || true

# n8n (Container 106)
log "Backing up n8n workflows..."
mkdir -p "$BACKUP_ROOT/n8n/$DATE"
pct exec 106 -- n8n export:workflow --all --output=/tmp/workflows.json 2>/dev/null || true
pct pull 106 /tmp/workflows.json "$BACKUP_ROOT/n8n/$DATE/workflows.json" 2>/dev/null || true

# Prometheus/Grafana (Container 125)
log "Backing up Prometheus/Grafana configs..."
mkdir -p "$BACKUP_ROOT/prometheus/$DATE"
pct exec 125 -- tar -czf - /etc/prometheus /etc/grafana > "$BACKUP_ROOT/prometheus/$DATE/monitoring-configs.tar.gz" 2>/dev/null || true

# RustDesk Keys (Container 123)
log "Backing up RustDesk encryption keys..."
mkdir -p "$BACKUP_ROOT/rustdesk/$DATE"
pct exec 123 -- tar -czf - /opt/rustdesk/id_ed25519* > "$BACKUP_ROOT/rustdesk/$DATE/rustdesk-keys.tar.gz" 2>/dev/null || true

# CA Server (Container 115)
log "Backing up Certificate Authority..."
mkdir -p "$BACKUP_ROOT/ca-server/$DATE"
pct exec 115 -- tar -czf - /root/ca > "$BACKUP_ROOT/ca-server/$DATE/ca-complete.tar.gz" 2>/dev/null || true

# Home Assistant (VM 104 on pve-router)
log "Backing up Home Assistant configuration..."
mkdir -p "$BACKUP_ROOT/home-assistant/$DATE"
ssh root@10.0.10.2 "qm exec 104 -- tar -czf - /config" > "$BACKUP_ROOT/home-assistant/$DATE/ha-config.tar.gz" 2>/dev/null || true

log "Critical configs backup complete!"
```

---

## 📋 Cron Schedule

**Add to each Proxmox host:**

```bash
# /etc/cron.d/homelab-backup

# Daily backups at 2 AM
0 2 * * * root /usr/local/bin/backup-postgresql.sh
15 2 * * * root /usr/local/bin/backup-critical-configs.sh
30 2 * * * root /usr/local/bin/backup-proxmox-to-omv.sh

# Weekly full backup (Sunday 3 AM)
0 3 * * 0 root /usr/local/bin/backup-proxmox-to-omv.sh

# Monthly cloud backup (1st of month, 4 AM)
0 4 1 * * root /usr/local/bin/backup-to-cloud.sh
```

**Add to VPS:**

```bash
# Daily VPS config backup
30 2 * * * /usr/local/bin/backup-vps-configs.sh
```

---

## 🔐 Encryption & Security

### SSH Keys Backup
```bash
# Backup all SSH keys (encrypted)
tar -czf ssh-keys-$(date +%Y%m%d).tar.gz ~/.ssh
gpg --symmetric --cipher-algo AES256 ssh-keys-*.tar.gz
rm ssh-keys-*.tar.gz
# Store encrypted file in multiple locations
```

### Cloud Backup Encryption (Restic)
```bash
# Initialize Restic repository
restic -r b2:homelab-backup init

# Set password in environment
export RESTIC_PASSWORD="your-strong-password-here"
export B2_ACCOUNT_ID="your-b2-account-id"
export B2_ACCOUNT_KEY="your-b2-account-key"

# Backup critical data
restic -r b2:homelab-backup backup /mnt/omv-backups/databases
restic -r b2:homelab-backup backup /mnt/omv-backups/configs

# Verify
restic -r b2:homelab-backup snapshots
```

### Encryption Keys Storage
**Store in 3 places:**
1. Password manager (primary)
2. Printed on paper in safe
3. Encrypted file on separate USB drive

---

## 🔄 Restoration Procedures

### Full Disaster Recovery (Complete Loss)

**Estimated Time:** 6-8 hours
**Prerequisites:** New hardware, OMV backups accessible

**Step 1: Reinstall Proxmox (1 hour)**
```bash
# Install Proxmox VE on new hardware
# Configure network (10.0.10.0/24)
# Set hostname
```

**Step 2: Mount Backup Storage (15 min)**
```bash
mkdir -p /mnt/omv-backups
mount -t nfs 10.0.10.5:/srv/backups /mnt/omv-backups
```

**Step 3: Restore PostgreSQL (30 min)**
```bash
# Create new PostgreSQL container
pct create 102 local:vztmpl/debian-12-standard.tar.zst \
    --hostname postgresql \
    --net0 name=eth0,bridge=vmbr0,ip=10.0.10.20/24,gw=10.0.10.1

# Start and install PostgreSQL
pct start 102
pct exec 102 -- apt update && apt install -y postgresql

# Restore all databases
pct push 102 /mnt/omv-backups/databases/postgresql/latest/all_databases.sql /tmp/
pct exec 102 -- sudo -u postgres psql < /tmp/all_databases.sql
```

**Step 4: Restore Critical Containers (2 hours)**
```bash
# Find latest backups
LATEST_BACKUP="/mnt/omv-backups/proxmox/main-pve/daily/$(ls -t /mnt/omv-backups/proxmox/main-pve/daily | head -1)"

# Restore Authentik
qmrestore $LATEST_BACKUP/vzdump-lxc-121-*.tar.gz 121

# Restore n8n
qmrestore $LATEST_BACKUP/vzdump-lxc-106-*.tar.gz 106

# Restore other containers...
```

**Step 5: Restore VPS (1 hour)**
```bash
# Reinstall Ubuntu on VPS
# Extract configs
tar -xzf /mnt/omv-backups/configs/vps/latest/vps-backup-*.tar.gz
cp -r vps-backup-*/caddy /etc/
cp -r vps-backup-*/wireguard /etc/
systemctl restart caddy wireguard
```

**Step 6: Verify & Test (2 hours)**
```bash
# Check all services
# Test authentication
# Verify databases
# Test network connectivity
```

### Partial Recovery (Single VM/Container)

```bash
# Restore specific container
BACKUP_FILE=$(ls -t /mnt/omv-backups/proxmox/main-pve/daily/*/vzdump-lxc-121-*.tar.gz | head -1)
pct restore 121 "$BACKUP_FILE" --storage local

# Start container
pct start 121

# Verify services
pct exec 121 -- systemctl status
```

### Database Recovery (Single Database)

```bash
# Restore single database
cd /mnt/omv-backups/databases/postgresql/latest
pct push 102 authentik.dump /tmp/
pct exec 102 -- sudo -u postgres pg_restore -d authentik /tmp/authentik.dump
```

---

## ✅ Verification & Testing

### Weekly Verification
```bash
# Verify backup files exist
ls -lh /mnt/omv-backups/proxmox/main-pve/daily/$(date +%Y-%m-%d)

# Check backup sizes (should not be 0)
find /mnt/omv-backups -name "*.tar.gz" -size 0

# Test mount point
df -h /mnt/omv-backups
```

### Monthly Verification
```bash
# Test restore of random container
# Restore to test VMID (900)
RANDOM_BACKUP=$(find /mnt/omv-backups -name "vzdump-lxc-*.tar.gz" | shuf -n 1)
pct restore 900 "$RANDOM_BACKUP" --storage local
pct start 900
# Verify services, then destroy
pct stop 900 && pct destroy 900
```

### Quarterly DR Test
**Full disaster recovery simulation**
1. Document current state
2. Restore entire infrastructure to test environment
3. Verify all services functional
4. Document issues and gaps
5. Update procedures

---

## 📊 Monitoring & Alerts

### Backup Success Monitoring

```bash
# Check last backup time
find /mnt/omv-backups/proxmox/main-pve/daily -name "*.tar.gz" -mtime -1 | wc -l
# Should be > 0 if backup ran today

# Add to Prometheus
node_backup_last_success{job="backups",type="proxmox"} $(stat -c %Y $(ls -t /mnt/omv-backups/proxmox/main-pve/daily/*/*.tar.gz | head -1))
```

### Email Notifications

```bash
# Add to backup scripts
if [ $? -eq 0 ]; then
    echo "Backup successful on $(hostname)" | mail -s "✓ Backup Success" fred@nianticbooks.com
else
    echo "Backup FAILED on $(hostname)" | mail -s "✗ Backup FAILED" fred@nianticbooks.com
fi
```

### Grafana Dashboard

**Create dashboard for:**
- Last successful backup time (per host)
- Backup size over time
- Failed backup count
- Storage usage on OMV

---

## 💰 Cost Estimate

### One-Time Costs
| Item | Cost | Purpose |
|------|------|---------|
| 2x 2TB External HDD | $150 | Off-site rotation |
| USB Drive (64GB) | $15 | Encryption key backup |
| **Total** | **$165** | |

### Monthly Costs
| Service | Cost | Storage |
|---------|------|---------|
| Backblaze B2 | $12-30/mo | 200-500GB |
| **OR** Google Drive | $10/mo | 2TB |
| **Total** | **$10-30/mo** | |

### OMV Storage (Already Owned)
- 12TB available
- Estimated usage: 500GB-1TB for backups
- 11TB+ remaining for other use

---

## 📈 Expected Storage Usage

**Daily Backups (OMV):**
- Containers: ~50GB compressed
- Databases: ~5GB
- Configs: ~2GB
- Total per day: ~60GB
- Week (7 days): ~420GB
- Month (30 days rolling): ~400GB (with cleanup)

**Weekly Backups:**
- Full VMs + Containers: ~200GB
- 4 weeks retention: ~800GB

**Total OMV Usage: ~1.2TB**

**Cloud Backups (Monthly):**
- Compressed critical data: ~100-200GB
- 12 months retention: ~2.4TB (with deduplication: ~500GB)

---

## 🎯 Success Criteria

**Backup System is Successful When:**
- ✅ All critical VMs/containers backed up daily
- ✅ PostgreSQL dumps run without errors
- ✅ Configs synced across all systems
- ✅ Weekly backups complete successfully
- ✅ Monthly cloud upload verified
- ✅ Test restores succeed quarterly
- ✅ Recovery time < 8 hours for full rebuild
- ✅ No data loss in last 24 hours (RPO met)
- ✅ Notifications sent for failures
- ✅ Off-site backups rotated weekly

---

## 📋 Quick Reference

**Backup Locations:**
```
Tier 1 (Local):   /mnt/omv-backups (10.0.10.5 NFS)
Tier 2 (Offsite): /mnt/external-drive (rotated weekly)
Tier 3 (Cloud):   b2:homelab-backup (Backblaze B2)
```

**Key Scripts:**
```
Proxmox:    /usr/local/bin/backup-proxmox-to-omv.sh
PostgreSQL: /usr/local/bin/backup-postgresql.sh
Configs:    /usr/local/bin/backup-critical-configs.sh
Cloud:      /usr/local/bin/backup-to-cloud.sh
VPS:        /usr/local/bin/backup-vps-configs.sh (on VPS)
```

**Restore Commands:**
```
Container:  pct restore <VMID> <backup-file>
VM:         qmrestore <backup-file> <VMID>
Database:   pct exec 102 -- pg_restore -d <dbname> <dump-file>
Config:     tar -xzf <config-backup> -C /
```

**Check Backup Status:**
```bash
ls -lh /mnt/omv-backups/proxmox/main-pve/daily/$(date +%Y-%m-%d)
tail -f /var/log/homelab-backup.log
```

---

**Implementation Status:** 📝 READY TO IMPLEMENT
**Estimated Setup Time:** 5-6 days (spread over 4 weeks)
**Maintenance Time:** 1 hour/month (verification + off-site rotation)

**Next Steps:**
1. Review and approve this plan
2. Begin Phase 1 (OMV setup)
3. Test scripts before automation
4. Choose cloud provider
5. Purchase off-site drives

**Created:** 2025-12-25
**Status:** Awaiting approval and implementation
