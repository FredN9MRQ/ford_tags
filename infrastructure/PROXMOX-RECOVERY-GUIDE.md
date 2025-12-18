# Proxmox Recovery Guide

Detailed procedures for recovering Proxmox VE installations, VMs, and containers from various failure scenarios.

## Table of Contents
- [Overview](#overview)
- [Backup Strategy](#backup-strategy)
- [Recovery Scenarios](#recovery-scenarios)
- [Tools and Commands](#tools-and-commands)
- [Preventive Measures](#preventive-measures)

## Overview

This guide covers recovery procedures for Proxmox VE environments, specifically:
- Proxmox node failures (hardware issues, corruption, etc.)
- VM/Container restoration
- Cluster recovery
- Configuration restoration

## Backup Strategy

### What to Backup

**1. Proxmox Configuration**
```bash
# Backup Proxmox configs
tar -czf /backup/proxmox-etc-$(date +%Y%m%d).tar.gz /etc/pve/

# Backup network configuration
cp /etc/network/interfaces /backup/interfaces.$(date +%Y%m%d)

# Backup storage configuration
pvesm status > /backup/storage-status.$(date +%Y%m%d).txt
```

**2. VM/Container Backups**
```bash
# Backup all VMs/containers
vzdump --all --mode snapshot --compress zstd --storage [backup-storage]

# Backup specific VM
vzdump VMID --mode snapshot --compress zstd --storage [backup-storage]

# Backup to network location
vzdump VMID --dumpdir /mnt/backup --mode snapshot --compress zstd
```

**3. Boot Configuration**
```bash
# Backup boot loader
dd if=/dev/sda of=/backup/mbr-backup.img bs=512 count=1

# Backup partition table
sfdisk -d /dev/sda > /backup/partition-table.$(date +%Y%m%d).txt
```

### Automated Backup Script

Create `/usr/local/bin/backup-proxmox.sh`:

```bash
#!/bin/bash
# Automated Proxmox backup script

BACKUP_DIR="/mnt/backup/proxmox"
DATE=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

# Backup Proxmox configuration
tar -czf "$BACKUP_DIR/$DATE/pve-config.tar.gz" /etc/pve/ 2>/dev/null

# Backup network config
cp /etc/network/interfaces "$BACKUP_DIR/$DATE/interfaces"

# Backup storage config
pvesm status > "$BACKUP_DIR/$DATE/storage-status.txt"

# Backup firewall rules
iptables-save > "$BACKUP_DIR/$DATE/iptables-rules"

# List all VMs and containers
qm list > "$BACKUP_DIR/$DATE/vm-list.txt"
pct list > "$BACKUP_DIR/$DATE/ct-list.txt"

# Backup VM configs (excluding disks)
for vm in $(qm list | awk '{if(NR>1) print $1}'); do
    qm config $vm > "$BACKUP_DIR/$DATE/vm-$vm-config.txt"
done

# Backup container configs
for ct in $(pct list | awk '{if(NR>1) print $1}'); do
    pct config $ct > "$BACKUP_DIR/$DATE/ct-$ct-config.txt"
done

# Remove old backups
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +

echo "Backup completed: $BACKUP_DIR/$DATE"
```

Set up cron job:
```bash
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-proxmox.sh
```

## Recovery Scenarios

### Scenario 1: Single VM/Container Recovery

**Symptoms:**
- VM won't start
- VM corrupted
- Accidental deletion

**Recovery Procedure:**

**1. From Proxmox Backup**
```bash
# List available backups
ls -lh /var/lib/vz/dump/

# Restore VM from backup
qmrestore /var/lib/vz/dump/vzdump-qemu-VMID-DATE.vma.zst NEW_VMID \
    --storage local-lvm

# Restore container from backup
pct restore NEW_CTID /var/lib/vz/dump/vzdump-lxc-CTID-DATE.tar.zst \
    --storage local-lvm

# Start restored VM/container
qm start NEW_VMID
pct start NEW_CTID
```

**2. From External Backup Location**
```bash
# Mount backup location if needed
mount /dev/sdX1 /mnt/backup

# Or mount network share
mount -t nfs backup-server:/backups /mnt/backup

# Restore from external location
qmrestore /mnt/backup/vzdump-qemu-VMID.vma.zst NEW_VMID \
    --storage local-lvm
```

**3. Restore to Different Storage**
```bash
# List available storage
pvesm status

# Restore to specific storage
qmrestore /path/to/backup.vma.zst NEW_VMID --storage [storage-name]
```

### Scenario 2: Proxmox Node Complete Failure

**Symptoms:**
- Hardware failure (motherboard, CPU, RAM)
- Disk controller failure
- Proxmox installation corrupted

**Recovery Options:**

**Option A: Reinstall Proxmox and Restore VMs**

**1. Reinstall Proxmox VE**
```bash
# Boot from Proxmox ISO
# Follow installation wizard
# Configure same network settings as before
# Configure same hostname

# After installation, update system
apt update && apt full-upgrade
```

**2. Restore Network Configuration**
```bash
# Copy backed up network config
scp backup-server:/backup/interfaces /etc/network/interfaces

# Restart networking
systemctl restart networking
```

**3. Configure Storage**
```bash
# Recreate storage configurations
# Web UI: Datacenter → Storage → Add

# Or via command line
pvesm add dir backup --path /mnt/backup --content backup
pvesm add nfs shared-storage --server NFS_IP --export /export/path --content images,backup
```

**4. Restore VMs/Containers**
```bash
# Copy backups if needed
scp -r backup-server:/backups/* /var/lib/vz/dump/

# Restore each VM
for backup in /var/lib/vz/dump/vzdump-qemu-*.vma.zst; do
    VMID=$(basename $backup | grep -oP '\d+')
    echo "Restoring VM $VMID..."
    qmrestore $backup $VMID --storage local-lvm
done

# Restore each container
for backup in /var/lib/vz/dump/vzdump-lxc-*.tar.zst; do
    CTID=$(basename $backup | grep -oP '\d+')
    echo "Restoring CT $CTID..."
    pct restore $CTID $backup --storage local-lvm
done
```

**Option B: Disk Recovery (If disks are intact)**

**1. Boot from Proxmox Live ISO**
```bash
# Don't install - boot to rescue mode
```

**2. Mount Proxmox System Disk**
```bash
# Identify system disk
lsblk

# Mount root filesystem
mkdir /mnt/pve-root
mount /dev/sdX3 /mnt/pve-root  # Adjust partition number

# Mount boot partition
mount /dev/sdX2 /mnt/pve-root/boot/efi
```

**3. Chroot into System**
```bash
# Mount proc, sys, dev
mount -t proc proc /mnt/pve-root/proc
mount -t sysfs sys /mnt/pve-root/sys
mount -o bind /dev /mnt/pve-root/dev
mount -t devpts devpts /mnt/pve-root/dev/pts

# Chroot
chroot /mnt/pve-root

# Try to repair
proxmox-boot-tool refresh
update-grub
update-initramfs -u

# Exit chroot
exit

# Unmount and reboot
umount -R /mnt/pve-root
reboot
```

### Scenario 3: ZFS Pool Recovery

**Symptoms:**
- ZFS pool degraded
- Missing or failed disk in ZFS mirror/RAID

**Recovery Procedure:**

**1. Check Pool Status**
```bash
# Check ZFS pool health
zpool status

# Example output showing degraded pool:
# pool: rpool
#  state: DEGRADED
# scan: scrub in progress since...
```

**2. Replace Failed Disk in ZFS Mirror**
```bash
# Identify failed disk
zpool status rpool

# Replace disk (assuming /dev/sdb failed, replacing with /dev/sdc)
zpool replace rpool /dev/sdb /dev/sdc

# Monitor resilvering progress
watch zpool status rpool
```

**3. Import Pool from Backup Disks**
```bash
# If pool is not automatically imported
zpool import

# Import specific pool
zpool import rpool

# Force import if needed (use cautiously)
zpool import -f rpool
```

**4. Scrub Pool After Recovery**
```bash
# Start scrub to verify data integrity
zpool scrub rpool

# Monitor scrub progress
zpool status
```

### Scenario 4: LVM Recovery

**Symptoms:**
- LVM volume group issues
- Corrupted LVM metadata
- Missing physical volumes

**Recovery Procedure:**

**1. Scan for Volume Groups**
```bash
# Scan for all volume groups
vgscan

# Activate all volume groups
vgchange -ay
```

**2. Restore LVM Metadata**
```bash
# LVM automatically backs up metadata to /etc/lvm/archive/

# List available metadata backups
ls -lh /etc/lvm/archive/

# Restore from backup
vgcfgrestore pve -f /etc/lvm/archive/pve_XXXXX.vg

# Activate volume group
vgchange -ay pve
```

**3. Recover from Failed Disk**
```bash
# Remove failed physical volume from volume group
vgreduce pve /dev/sdX

# Add new physical volume
pvcreate /dev/sdY
vgextend pve /dev/sdY

# Move data from old to new disk (if old disk still readable)
pvmove /dev/sdX /dev/sdY
vgreduce pve /dev/sdX
```

### Scenario 5: Cluster Node Recovery

**Symptoms:**
- Node removed from cluster
- Cluster quorum lost
- Split-brain scenario

**Recovery Procedure:**

**1. Check Cluster Status**
```bash
# Check cluster status
pvecm status

# Check quorum
pvecm nodes
```

**2. Restore Single Node from Cluster**
```bash
# If node was removed from cluster and you want to use it standalone

# Stop cluster services
systemctl stop pve-cluster
systemctl stop corosync

# Start in local mode
pmxcfs -l

# Remove cluster configuration
rm /etc/pve/corosync.conf
rm -rf /etc/corosync/*

# Restart services
killall pmxcfs
systemctl start pve-cluster
```

**3. Rejoin Node to Cluster**
```bash
# On the node to be rejoined
pvecm add CLUSTER_NODE_IP

# Enter cluster network information when prompted
# Node will rejoin cluster and sync configuration
```

**4. Recover Lost Quorum (Emergency Only)**
```bash
# If majority of cluster nodes are down and you need to continue
# WARNING: This can cause split-brain if other nodes come back

# Set expected votes to current online nodes
pvecm expected 1

# This allows single node to have quorum temporarily
```

### Scenario 6: Configuration Recovery Without Backups

**If /etc/pve/ is lost but VMs/containers intact:**

**1. Identify Existing VMs/Containers**
```bash
# List LVM volumes
lvs

# List ZFS datasets
zfs list -t all

# VM disks typically in:
# LVM: pve/vm-XXX-disk-Y
# ZFS: rpool/data/vm-XXX-disk-Y
```

**2. Recreate VM Configuration**
```bash
# Create new VM with same VMID
qm create VMID --name "recovered-vm" --memory 4096 --cores 2

# Attach existing disk (LVM example)
qm set VMID --scsi0 local-lvm:vm-VMID-disk-0

# For ZFS
qm set VMID --scsi0 local-zfs:vm-VMID-disk-0

# Set other options as needed
qm set VMID --net0 virtio,bridge=vmbr0
qm set VMID --boot c --bootdisk scsi0

# Try to start VM
qm start VMID
```

**3. Recreate Container Configuration**
```bash
# Containers are stored in /var/lib/vz/ or ZFS dataset
# Check for rootfs

# Create container pointing to existing rootfs
pct create CTID /var/lib/vz/template/cache/[template].tar.gz \
    --rootfs local-lvm:vm-CTID-disk-0 \
    --hostname recovered-ct \
    --memory 2048

# Start container
pct start CTID
```

## Tools and Commands

### Essential Proxmox Commands

**VM Management:**
```bash
# List all VMs
qm list

# Show VM config
qm config VMID

# Start/stop VM
qm start VMID
qm stop VMID
qm shutdown VMID

# Clone VM
qm clone VMID NEW_VMID --name new-vm-name

# Migrate VM (in cluster)
qm migrate VMID TARGET_NODE
```

**Container Management:**
```bash
# List all containers
pct list

# Show container config
pct config CTID

# Start/stop container
pct start CTID
pct stop CTID
pct shutdown CTID

# Enter container
pct enter CTID
```

**Storage Management:**
```bash
# List storage
pvesm status

# Add storage
pvesm add [type] [storage-id] [options]

# Scan for storage
pvesm scan [type]
```

**Backup/Restore:**
```bash
# Create backup
vzdump VMID --mode snapshot --compress zstd

# Restore backup
qmrestore /path/to/backup.vma.zst NEW_VMID

# List backups
pvesh get /nodes/NODE/storage/STORAGE/content --content backup
```

### Diagnostic Commands

```bash
# Check Proxmox version
pveversion -v

# Check system resources
pvesh get /nodes/NODE/status

# Check running processes
pvesh get /nodes/NODE/tasks

# Check logs
journalctl -u pve-cluster
journalctl -u pvedaemon
journalctl -u pveproxy

# Check disk health
smartctl -a /dev/sdX

# Check network
ip addr
ip route
```

### Recovery Tools

**SystemRescue CD:**
- Boot from SystemRescue ISO
- Access to ZFS, LVM, and filesystem tools
- Can mount and repair Proxmox installations

**Proxmox Live ISO:**
- Boot without installing
- Can mount existing installations
- Repair bootloader and configurations

**TestDisk/PhotoRec:**
- Recover deleted files
- Repair partition tables

## Preventive Measures

### Regular Maintenance

**1. Daily Checks**
```bash
# Check cluster/node status
pvecm status

# Check VM/CT status
qm list
pct list

# Check storage health
pvesm status
```

**2. Weekly Tasks**
```bash
# Update Proxmox
apt update && apt dist-upgrade

# Check for failed systemd services
systemctl --failed

# Review logs
journalctl -p err -b
```

**3. Monthly Tasks**
```bash
# Test backup restore
qmrestore [backup] 999 --storage local-lvm
qm start 999
# Verify VM boots correctly
qm stop 999
qm destroy 999

# Check disk health
for disk in /dev/sd?; do smartctl -H $disk; done

# Check ZFS scrub
zpool scrub rpool
```

### Backup Best Practices

**1. 3-2-1 Backup Strategy**
- 3 copies of data
- 2 different media types
- 1 off-site copy

**2. Automated Backups**
- Schedule regular VM/CT backups
- Backup Proxmox configuration
- Test restore procedures regularly

**3. Documentation**
- Keep network diagrams updated
- Document IP allocations
- Maintain runbooks for common tasks
- Store documentation off-site

### Monitoring Setup

**1. Setup Email Alerts**
```bash
# Configure postfix for email
apt install postfix

# Test email
echo "Test" | mail -s "Proxmox Alert Test" your@email.com
```

**2. Monitor Resources**
- Set up monitoring for CPU, RAM, disk usage
- Alert on high resource consumption
- Monitor backup job success/failure

**3. Health Checks**
```bash
# Create health check script
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
# Proxmox Health Check

# Check cluster status
if ! pvecm status &>/dev/null; then
    echo "WARNING: Cluster status check failed"
fi

# Check storage
pvesm status | grep -v active && echo "WARNING: Storage issue detected"

# Check for failed VMs
qm list | grep stopped && echo "INFO: Stopped VMs detected"

# Check system load
LOAD=$(cat /proc/loadavg | awk '{print $1}')
if (( $(echo "$LOAD > 8" | bc -l) )); then
    echo "WARNING: High system load: $LOAD"
fi

# Check disk space
df -h | awk '$5 ~ /^9[0-9]%/ || $5 ~ /^100%/ {print "WARNING: Disk space low on " $6 ": " $5}'
EOF

chmod +x /usr/local/bin/health-check.sh

# Add to crontab
echo "*/15 * * * * /usr/local/bin/health-check.sh | mail -s 'Proxmox Health Alert' your@email.com" | crontab -
```

## Emergency Contacts

### Proxmox Resources
- Proxmox Forums: https://forum.proxmox.com/
- Proxmox Documentation: https://pve.proxmox.com/pve-docs/
- Proxmox Wiki: https://pve.proxmox.com/wiki/

### Hardware Support
- Document hardware vendor support contacts
- Keep warranty information accessible
- Maintain spare parts inventory

## Recovery Time Objectives

| Scenario | Target Recovery Time | Notes |
|----------|---------------------|-------|
| Single VM restore | 30 minutes | From local backup |
| Complete node rebuild | 4-8 hours | Including OS reinstall |
| ZFS pool recovery | 1-6 hours | Depends on resilvering time |
| Cluster rejoin | 1-2 hours | Network reconfiguration |
| Full disaster recovery | 24-48 hours | From off-site backups |

## Recent Recovery Events

### Event Log Template

**Date:** YYYY-MM-DD
**Affected System:** [Proxmox node/VM/CT]
**Issue:** [Description]
**Resolution:** [Steps taken]
**Downtime:** [Duration]
**Lessons Learned:** [Improvements for next time]

---

**Last Updated:** 2025-12-13
**Version:** 1.0
