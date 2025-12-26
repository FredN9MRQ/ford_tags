# Backup System Quick Start Guide

**Get your 3-tier backup running in 1-2 hours**

---

## 🎯 Goal

Set up automated daily backups of your entire homelab to OMV storage (12TB).

---

## ✅ Prerequisites

- ✅ OMV running at 10.0.10.5
- ✅ Root access to all Proxmox hosts
- ✅ Root password for OMV: `homelab2025`
- ✅ Backup scripts in `infrastructure/scripts/`

---

## 🚀 Phase 1: OMV NFS Setup (30 minutes)

### Step 1: Configure OMV Backup Share

**On your browser:**
1. Go to http://10.0.10.5 (OMV web interface)
2. Login with admin credentials
3. Navigate to: **Storage → Shared Folders**
4. Click **+ Add**:
   - Name: `backups`
   - Device: Select your 12TB drive
   - Path: `/backups/`
   - Permissions: Read/Write
   - Click **Save**

5. Navigate to: **Services → NFS**
6. Click **Settings** tab:
   - Enable NFS: ✓
   - Click **Save**

7. Click **Shares** tab
8. Click **+ Add**:
   - Shared folder: `backups`
   - Client: `10.0.10.0/24`
   - Privilege: Read/Write
   - Extra options: `no_subtree_check,no_root_squash`
   - Click **Save**

9. Click **Apply** (yellow banner at top)

### Step 2: Mount NFS on All Proxmox Hosts

**On main-pve (10.0.10.3):**
```bash
ssh root@10.0.10.3

# Create mount point
mkdir -p /mnt/omv-backups

# Test mount
mount -t nfs 10.0.10.5:/export/backups /mnt/omv-backups

# If successful, make it permanent
echo "10.0.10.5:/export/backups /mnt/omv-backups nfs defaults 0 0" >> /etc/fstab

# Test
df -h /mnt/omv-backups
touch /mnt/omv-backups/test-main-pve.txt
ls -la /mnt/omv-backups/
```

**Repeat for pve-router (10.0.10.2):**
```bash
ssh root@10.0.10.2
mkdir -p /mnt/omv-backups
mount -t nfs 10.0.10.5:/export/backups /mnt/omv-backups
echo "10.0.10.5:/export/backups /mnt/omv-backups nfs defaults 0 0" >> /etc/fstab
touch /mnt/omv-backups/test-pve-router.txt
```

**Repeat for pve-storage (10.0.10.4):**
```bash
ssh root@10.0.10.4
mkdir -p /mnt/omv-backups
mount -t nfs 10.0.10.5:/export/backups /mnt/omv-backups
echo "10.0.10.5:/export/backups /mnt/omv-backups nfs defaults 0 0" >> /etc/fstab
touch /mnt/omv-backups/test-pve-storage.txt
```

---

## 🚀 Phase 2: Deploy Backup Scripts (20 minutes)

### Copy Scripts to Proxmox Hosts

**On your Windows machine:**
```powershell
cd C:\Users\Fred\projects\infrastructure\scripts

# Copy to main-pve
scp backup-proxmox-to-omv.sh root@10.0.10.3:/usr/local/bin/
scp backup-postgresql.sh root@10.0.10.3:/usr/local/bin/

# Copy to pve-router
scp backup-proxmox-to-omv.sh root@10.0.10.2:/usr/local/bin/

# Copy to pve-storage (if needed)
scp backup-proxmox-to-omv.sh root@10.0.10.4:/usr/local/bin/
```

### Make Scripts Executable

**On each Proxmox host:**
```bash
chmod +x /usr/local/bin/backup-proxmox-to-omv.sh
chmod +x /usr/local/bin/backup-postgresql.sh
```

### Deploy VPS Backup Script

**On your Windows machine:**
```powershell
scp scripts/backup-vps-configs.sh fred@66.63.182.168:~/
```

**On VPS:**
```bash
ssh fred@66.63.182.168
sudo mv ~/backup-vps-configs.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-vps-configs.sh
```

---

## 🚀 Phase 3: Test Backups (30 minutes)

### Test Proxmox Backup (main-pve)

```bash
ssh root@10.0.10.3

# Run test backup (won't interfere with production)
/usr/local/bin/backup-proxmox-to-omv.sh --test

# Check results
ls -lh /mnt/omv-backups/proxmox/main-pve/test/
tail -100 /var/log/homelab-backup.log
```

**Expected output:**
- Backup files in test directory
- Log showing successful VMs/containers backed up
- No errors in log file

### Test PostgreSQL Backup

```bash
ssh root@10.0.10.3

# Run test backup
/usr/local/bin/backup-postgresql.sh --test

# Check results
ls -lh /mnt/omv-backups/databases/postgresql/test/
tail -50 /var/log/homelab-backup.log
```

**Expected output:**
- `.tar.gz` file with all databases
- Log showing successful database dumps
- File size reasonable (few GB)

### Test VPS Backup

```bash
ssh fred@66.63.182.168

# Run test backup
sudo /usr/local/bin/backup-vps-configs.sh --test

# Check if it synced to OMV
ssh root@10.0.10.5 "ls -lh /srv/backups/configs/vps/"
```

**Expected output:**
- VPS config archive on OMV
- Caddy, WireGuard configs included

---

## 🚀 Phase 4: Automate with Cron (10 minutes)

### Schedule Backups on main-pve

```bash
ssh root@10.0.10.3

# Create cron file
cat > /etc/cron.d/homelab-backup << 'EOF'
# Homelab Automated Backups

# Daily PostgreSQL backup at 2:00 AM
0 2 * * * root /usr/local/bin/backup-postgresql.sh

# Daily Proxmox backup at 2:30 AM
30 2 * * * root /usr/local/bin/backup-proxmox-to-omv.sh

# Weekly full backup (Sunday 3 AM)
0 3 * * 0 root /usr/local/bin/backup-proxmox-to-omv.sh
EOF

# Verify cron file
cat /etc/cron.d/homelab-backup
```

### Schedule Backups on pve-router

```bash
ssh root@10.0.10.2

cat > /etc/cron.d/homelab-backup << 'EOF'
# Daily Proxmox backup at 2:30 AM
30 2 * * * root /usr/local/bin/backup-proxmox-to-omv.sh

# Weekly full backup (Sunday 3 AM)
0 3 * * 0 root /usr/local/bin/backup-proxmox-to-omv.sh
EOF
```

### Schedule VPS Backup

```bash
ssh fred@66.63.182.168

# Add to fred's crontab (will prompt for sudo password when running)
crontab -e

# Add this line:
30 2 * * * sudo /usr/local/bin/backup-vps-configs.sh
```

**Alternative (if sudo without password is set up):**
```bash
sudo crontab -e
# Add:
30 2 * * * /usr/local/bin/backup-vps-configs.sh
```

---

## ✅ Verification

### Check Cron is Active

```bash
# On each Proxmox host
systemctl status cron
grep homelab /var/log/syslog | tail -5
```

### Monitor First Automated Run

**Next morning after 2 AM:**
```bash
# Check backups ran
ssh root@10.0.10.3
tail -200 /var/log/homelab-backup.log | grep "Backup complete"

# Check backup files exist
ls -lh /mnt/omv-backups/proxmox/main-pve/daily/$(date +%Y-%m-%d)/
ls -lh /mnt/omv-backups/databases/postgresql/postgresql_$(date +%Y-%m-%d).tar.gz
```

### Check Backup Sizes

```bash
# Total backup usage
du -sh /mnt/omv-backups/

# By category
du -sh /mnt/omv-backups/proxmox/
du -sh /mnt/omv-backups/databases/
du -sh /mnt/omv-backups/configs/
```

---

## 🎯 Success Criteria

**Your backup system is working when:**

- ✅ NFS mount accessible from all Proxmox hosts
- ✅ Test backups run successfully without errors
- ✅ Backup files created in OMV storage
- ✅ Cron jobs scheduled on all hosts
- ✅ Log files show successful backups
- ✅ Backup retention working (old backups cleaned up)

---

## 📊 Expected Results After First Week

**Daily Backups:**
```
/mnt/omv-backups/
├── proxmox/
│   ├── main-pve/daily/
│   │   ├── 2025-12-26/  (~150GB)
│   │   ├── 2025-12-27/  (~150GB)
│   │   ├── 2025-12-28/  (~150GB)
│   │   └── ...
│   └── pve-router/daily/
│       ├── 2025-12-26/  (~50GB)
│       └── ...
├── databases/
│   └── postgresql/
│       ├── postgresql_2025-12-26.tar.gz  (~5GB)
│       ├── postgresql_2025-12-27.tar.gz  (~5GB)
│       └── ...
└── configs/
    └── vps/
        ├── vps-backup-2025-12-26.tar.gz  (~500MB)
        └── ...
```

**Total Usage After 1 Week:** ~1.5TB
**After 1 Month:** ~2-3TB (with retention cleanup)

---

## 🔧 Troubleshooting

### NFS Mount Fails
```bash
# Check OMV NFS service
ssh root@10.0.10.5 "systemctl status nfs-server"

# Check exports
showmount -e 10.0.10.5

# Test manual mount
mount -t nfs -v 10.0.10.5:/export/backups /mnt/omv-backups
```

### Backup Script Fails
```bash
# Check logs
tail -100 /var/log/homelab-backup.log

# Run in dry-run mode
/usr/local/bin/backup-proxmox-to-omv.sh --dry-run

# Check permissions
ls -la /mnt/omv-backups/
touch /mnt/omv-backups/test.txt
```

### Cron Not Running
```bash
# Check cron service
systemctl status cron

# Check cron logs
grep CRON /var/log/syslog | tail -20

# Manually run cron job
run-parts --test /etc/cron.d/
```

### Out of Space
```bash
# Check OMV disk usage
ssh root@10.0.10.5 "df -h"

# Clean old backups manually
find /mnt/omv-backups -name "*.tar.gz" -mtime +7 -ls
# If looks safe:
find /mnt/omv-backups -name "*.tar.gz" -mtime +7 -delete
```

---

## 📚 Next Steps (After Basic Backup Working)

### Phase 5: Cloud Backup (Week 2-3)
- Sign up for Backblaze B2
- Install Restic
- Configure encrypted cloud sync
- See: `HOMELAB-BACKUP-STRATEGY.md` for details

### Phase 6: Off-Site Backup (Week 3-4)
- Purchase 2x external drives
- Create weekly rotation schedule
- Test restore from external drive

### Phase 7: Disaster Recovery Testing (Week 4-5)
- Document full restore procedure
- Test restoring a single VM
- Test restoring a database
- Schedule quarterly DR tests

---

## 📞 Support

**Documentation:**
- Full strategy: `HOMELAB-BACKUP-STRATEGY.md`
- Script reference: `/scripts/` folder
- Logs: `/var/log/homelab-backup.log` on each host

**Common Commands:**
```bash
# View recent backup log
tail -f /var/log/homelab-backup.log

# List backups
ls -lh /mnt/omv-backups/proxmox/main-pve/daily/

# Check backup size
du -sh /mnt/omv-backups/

# Manual backup (test)
/usr/local/bin/backup-proxmox-to-omv.sh --test

# Manual backup (production)
/usr/local/bin/backup-proxmox-to-omv.sh
```

---

**Time Estimate:** 1-2 hours for basic setup
**Difficulty:** Medium
**Result:** Automated daily backups to 12TB OMV storage

**Last Updated:** 2025-12-25
