# Infrastructure Runbook

This runbook provides step-by-step procedures for common operational tasks in your infrastructure.

## Table of Contents
- [Pangolin Reverse Proxy Operations](#pangolin-reverse-proxy-operations)
- [Gerbil Tunnel Management](#gerbil-tunnel-management)
- [Proxmox Operations](#proxmox-operations)
- [SSL/TLS Certificate Management](#ssltls-certificate-management)
- [Network Troubleshooting](#network-troubleshooting)
- [Security Procedures](#security-procedures)
- [Backup Operations](#backup-operations)

---

## Pangolin Reverse Proxy Operations

### Add a New Route
```bash
# 1. SSH into VPS
ssh user@your-vps-ip

# 2. Edit Pangolin configuration
sudo nano /path/to/pangolin/config.yml

# 3. Add new route configuration
# domain.example.com -> backend:port

# 4. Test configuration
sudo pangolin config test

# 5. Reload Pangolin
sudo systemctl reload pangolin
# OR
sudo pangolin reload

# 6. Verify route is active
curl -I https://domain.example.com
```

### Remove a Route
```bash
# 1. Edit configuration and comment out or remove route
sudo nano /path/to/pangolin/config.yml

# 2. Reload Pangolin
sudo systemctl reload pangolin

# 3. Verify route is removed
curl -I https://domain.example.com
```

### View Pangolin Logs
```bash
# Real-time logs
sudo tail -f /var/log/pangolin/access.log
sudo tail -f /var/log/pangolin/error.log

# Search for specific domain
grep "domain.example.com" /var/log/pangolin/access.log

# Check last 100 errors
sudo tail -n 100 /var/log/pangolin/error.log
```

### Restart Pangolin Service
```bash
# Check status
sudo systemctl status pangolin

# Restart
sudo systemctl restart pangolin

# Verify it's running
sudo systemctl is-active pangolin
```

---

## Gerbil Tunnel Management

### Check Active Tunnels
```bash
# On VPS - check listening Gerbil server
ss -tlnp | grep gerbil

# On home lab - check active tunnel connections
gerbil status
# OR
ps aux | grep gerbil
```

### Start a Tunnel
```bash
# On home lab machine
gerbil connect --name tunnel-name \
  --local localhost:PORT \
  --remote VPS_IP:REMOTE_PORT \
  --auth-key /path/to/auth.key

# Start as systemd service
sudo systemctl start gerbil-tunnel-name
```

### Stop a Tunnel
```bash
# If running as service
sudo systemctl stop gerbil-tunnel-name

# If running manually
pkill -f "gerbil.*tunnel-name"
```

### Restart a Tunnel
```bash
sudo systemctl restart gerbil-tunnel-name

# Verify tunnel is active
gerbil status tunnel-name
# OR
ss -tn | grep REMOTE_PORT
```

### Debug Tunnel Connection Issues
```bash
# 1. Check if local service is running
curl http://localhost:LOCAL_PORT

# 2. Check if tunnel process is running
ps aux | grep gerbil

# 3. Check tunnel logs
journalctl -u gerbil-tunnel-name -n 50

# 4. Test VPS endpoint
# On VPS:
curl http://localhost:REMOTE_PORT

# 5. Check firewall on VPS
sudo ufw status
sudo iptables -L -n | grep REMOTE_PORT
```

---

## Proxmox Operations

### Create a New VM
```bash
# Via Proxmox web UI: https://PROXMOX_IP:8006

# Via CLI on Proxmox node:
qm create VMID --name vm-name --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Attach disk
qm set VMID --scsi0 local-lvm:32

# Set boot order
qm set VMID --boot order=scsi0

# Start VM
qm start VMID
```

### Create a New Container (LXC)
```bash
# Download template
pveam update
pveam available
pveam download local ubuntu-22.04-standard

# Create container
pct create CTID local:vztmpl/ubuntu-22.04-standard.tar.gz \
  --hostname ct-name \
  --memory 1024 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp

# Start container
pct start CTID

# Enter container
pct enter CTID
```

### Stop/Start VM or Container
```bash
# VM operations
qm stop VMID          # Stop
qm start VMID         # Start
qm shutdown VMID      # Graceful shutdown
qm reboot VMID        # Reboot
qm status VMID        # Check status

# Container operations
pct stop CTID
pct start CTID
pct shutdown CTID
pct reboot CTID
pct status CTID
```

### Migrate VM Between Nodes
```bash
# Online migration (VM stays running)
qm migrate VMID target-node --online

# Offline migration
qm migrate VMID target-node

# Check migration status
qm status VMID
```

### Check Resource Usage
```bash
# Overall cluster resources
pvesh get /cluster/resources

# Specific node resources
pvesh get /nodes/NODE_NAME/status

# VM resource usage
qm status VMID --verbose

# Storage usage
pvesm status
```

### Backup VM or Container
```bash
# Backup VM
vzdump VMID --storage STORAGE_NAME --mode snapshot

# Backup container
vzdump CTID --storage STORAGE_NAME

# List backups
pvesm list STORAGE_NAME
```

### Restore from Backup
```bash
# Restore VM
qmrestore /path/to/backup/vzdump-qemu-VMID.vma.zst VMID

# Restore container
pct restore CTID /path/to/backup/vzdump-lxc-CTID.tar.zst
```

---

## SSL/TLS Certificate Management

### Request New Let's Encrypt Certificate
```bash
# Install certbot if needed
sudo apt install certbot

# Request certificate (HTTP-01 challenge)
sudo certbot certonly --standalone -d domain.example.com

# Request wildcard certificate (DNS-01 challenge)
sudo certbot certonly --manual --preferred-challenges dns -d "*.example.com"

# Certificates are stored in: /etc/letsencrypt/live/domain.example.com/
```

### Renew Certificates
```bash
# Dry run to test renewal
sudo certbot renew --dry-run

# Renew all certificates
sudo certbot renew

# Renew specific certificate
sudo certbot renew --cert-name domain.example.com

# Set up auto-renewal (check if already configured)
sudo systemctl status certbot.timer
```

### Check Certificate Expiration
```bash
# Check local certificate
sudo certbot certificates

# Check remote certificate
echo | openssl s_client -servername domain.example.com -connect domain.example.com:443 2>/dev/null | openssl x509 -noout -dates

# Check all certificates expiring in 30 days
sudo certbot certificates | grep "Expiry Date"
```

### Deploy Certificate to Service
```bash
# Copy certificate to service location
sudo cp /etc/letsencrypt/live/domain.example.com/fullchain.pem /path/to/service/cert.pem
sudo cp /etc/letsencrypt/live/domain.example.com/privkey.pem /path/to/service/key.pem

# Set permissions
sudo chmod 644 /path/to/service/cert.pem
sudo chmod 600 /path/to/service/key.pem

# Reload service
sudo systemctl reload service-name
```

---

## Network Troubleshooting

### Check Network Connectivity
```bash
# Ping test
ping -c 4 8.8.8.8

# DNS resolution
nslookup domain.example.com
dig domain.example.com

# Trace route
traceroute domain.example.com
mtr domain.example.com
```

### Check Open Ports
```bash
# Check listening ports
ss -tlnp
netstat -tlnp

# Check if specific port is open
ss -tlnp | grep :PORT
nc -zv localhost PORT

# Check firewall rules
sudo ufw status numbered
sudo iptables -L -n -v
```

### Test Service Availability
```bash
# HTTP/HTTPS test
curl -I https://domain.example.com
curl -v https://domain.example.com

# Test specific port
nc -zv host PORT
telnet host PORT

# Check service status
sudo systemctl status service-name
```

### Check Network Interface Status
```bash
# List all interfaces
ip addr show
ip link show

# Check interface statistics
ip -s link show eth0

# Restart interface
sudo ip link set eth0 down
sudo ip link set eth0 up
```

---

## Security Procedures

### Update SSH Key
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "description"

# Copy to server
ssh-copy-id -i ~/.ssh/new_key.pub user@server

# Test new key
ssh -i ~/.ssh/new_key user@server

# Update SSH config
nano ~/.ssh/config
```

### Review Failed Login Attempts
```bash
# Check auth logs
sudo grep "Failed password" /var/log/auth.log
sudo journalctl -u ssh -n 100

# Check fail2ban status (if installed)
sudo fail2ban-client status sshd
```

### Update Firewall Rules
```bash
# Add new rule
sudo ufw allow PORT/tcp
sudo ufw allow from IP_ADDRESS to any port PORT

# Remove rule
sudo ufw delete allow PORT/tcp
sudo ufw status numbered
sudo ufw delete NUMBER

# Reload firewall
sudo ufw reload
```

### Security Updates
```bash
# Check for updates
sudo apt update
sudo apt list --upgradable

# Install security updates only
sudo apt upgrade -y

# Reboot if kernel updated
sudo needrestart -r a
```

---

## Backup Operations

### Manual Backup
```bash
# Backup specific VM/Container
vzdump VMID --storage STORAGE_NAME --mode snapshot --compress zstd

# Backup configuration files
tar -czf config-backup-$(date +%Y%m%d).tar.gz /etc/pangolin /etc/gerbil

# Backup to remote location
rsync -avz /path/to/data/ user@backup-server:/path/to/backup/
```

### Verify Backup
```bash
# List backup contents
tar -tzf backup.tar.gz | less

# Check backup integrity
tar -tzf backup.tar.gz > /dev/null && echo "OK" || echo "CORRUPTED"

# Check vzdump backup
cat /path/to/backup/vzdump-qemu-VMID.log
```

### Restore Specific Files
```bash
# Extract specific file from backup
tar -xzf backup.tar.gz path/to/specific/file

# Restore from rsync backup
rsync -avz user@backup-server:/path/to/backup/ /path/to/restore/
```

---

## Emergency Contacts

- Infrastructure Owner: _______________
- Network Administrator: _______________
- VPS Provider Support: _______________
- DNS Provider Support: _______________

## Additional Resources

- Pangolin Documentation: _______________
- Gerbil Documentation: _______________
- Proxmox Documentation: https://pve.proxmox.com/pve-docs/
- Internal Wiki: _______________
