# SSH Setup Guide - Homelab Infrastructure

Complete guide for setting up SSH connections between Windows machines in the homelab.

## Overview

This guide documents the SSH configuration between:
- **HOMELAB-COMMAND** (10.0.10.10) - Windows client/workstation
- **M6800** - Windows SSH server

## Architecture

```
HOMELAB-COMMAND (10.0.10.10)
    ↓ SSH (Port 22)
M6800 (Windows OpenSSH Server)
    - Projects in C:\Users\Fred\projects
    - Infrastructure scripts
    - Development environment
```

## Prerequisites

- Windows 10/11 on both machines
- Both machines on same network (10.0.10.0/24)
- Administrator access on M6800 for SSH server setup

## Setup Steps

### 1. Install OpenSSH Server on M6800

```powershell
# Check if OpenSSH Server is installed
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

# Install if not present
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the service
Start-Service sshd

# Enable automatic startup
Set-Service -Name sshd -StartupType 'Automatic'

# Verify service is running
Get-Service sshd
```

### 2. Configure Windows Firewall on M6800

```powershell
# Allow SSH through Windows Firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Or use the automated script
# C:\Users\Fred\projects\infrastructure\scripts\enable-ssh-firewall.ps1
```

### 3. Generate SSH Keys on HOMELAB-COMMAND

```powershell
# Generate ED25519 key pair (recommended for better security)
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519 -C "homelab-command-to-m6800"

# Or generate RSA key (if ED25519 not supported)
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa -C "homelab-command-to-m6800"

# Keys will be created in:
# - Private key: C:\Users\Fred\.ssh\id_ed25519
# - Public key: C:\Users\Fred\.ssh\id_ed25519.pub
```

### 4. Copy Public Key to M6800

**Manual Method:**

```powershell
# On HOMELAB-COMMAND - Display your public key
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub

# On M6800 - Create .ssh directory if needed
$sshDir = "$env:USERPROFILE\.ssh"
if (!(Test-Path $sshDir)) {
    New-Item -Path $sshDir -ItemType Directory -Force
}

# Create authorized_keys file and paste the public key
# Note: For administrators, use administrators_authorized_keys instead
$authKeysFile = "$env:ProgramData\ssh\administrators_authorized_keys"
Set-Content -Path $authKeysFile -Value "YOUR_PUBLIC_KEY_HERE"

# Set correct permissions (critical!)
icacls.exe "$authKeysFile" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

**Automated Method (if SSH password auth is enabled):**

```powershell
# From HOMELAB-COMMAND
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh fred@M6800 "mkdir -p C:\ProgramData\ssh; cat >> C:\ProgramData\ssh\administrators_authorized_keys"

# Fix permissions on M6800
ssh fred@M6800 "icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant Administrators:F /grant SYSTEM:F"
```

### 5. Configure SSH Client on HOMELAB-COMMAND

Create or edit `C:\Users\Fred\.ssh\config`:

```
Host m6800
    HostName M6800
    User Fred
    IdentityFile C:\Users\Fred\.ssh\id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host homelab-command
    HostName 10.0.10.10
    User Fred
    IdentityFile C:\Users\Fred\.ssh\id_ed25519
```

### 6. Test the Connection

```powershell
# Test SSH connection
ssh m6800

# Test with verbose output (for troubleshooting)
ssh -v m6800

# Test specific command
ssh m6800 "hostname"
```

## Troubleshooting

### Connection Refused

**Symptoms:**
```
ssh: connect to host M6800 port 22: Connection refused
```

**Solutions:**
1. Check SSH service is running on M6800:
   ```powershell
   Get-Service sshd
   Start-Service sshd  # If stopped
   ```

2. Verify firewall rule exists:
   ```powershell
   Get-NetFirewallRule -Name sshd
   ```

3. Test network connectivity:
   ```powershell
   Test-NetConnection -ComputerName M6800 -Port 22
   ```

### Permission Denied (publickey)

**Symptoms:**
```
Permission denied (publickey,keyboard-interactive)
```

**Solutions:**
1. Verify public key is in correct location:
   - For administrators: `C:\ProgramData\ssh\administrators_authorized_keys`
   - For regular users: `C:\Users\Fred\.ssh\authorized_keys`

2. Check file permissions on M6800:
   ```powershell
   icacls C:\ProgramData\ssh\administrators_authorized_keys
   ```
   Should show only Administrators and SYSTEM with Full control.

3. Verify SSH key is being offered:
   ```powershell
   ssh -v m6800 2>&1 | Select-String "Offering"
   ```

4. Restart SSH service after permission changes:
   ```powershell
   Restart-Service sshd
   ```

### Name Resolution Issues

**Symptoms:**
```
Could not resolve hostname M6800
```

**Solutions:**
1. Use IP address instead of hostname in SSH config
2. Add entry to hosts file:
   ```powershell
   Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "10.0.10.XX  M6800"
   ```
3. Configure static DNS entry in router/DHCP server

### Slow Connection/Hangs

**Solutions:**
1. Add to SSH config to disable GSSAPI authentication:
   ```
   GSSAPIAuthentication no
   ```

2. Increase verbosity to identify hang point:
   ```powershell
   ssh -vvv m6800
   ```

## Security Best Practices

### 1. Disable Password Authentication (After Key Setup Works)

On M6800, edit `C:\ProgramData\ssh\sshd_config`:

```
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH service:
```powershell
Restart-Service sshd
```

### 2. Change Default SSH Port (Optional)

Edit `C:\ProgramData\ssh\sshd_config`:
```
Port 2222  # Or any port above 1024
```

Update firewall rule:
```powershell
New-NetFirewallRule -Name sshd-custom -DisplayName 'OpenSSH Server (Custom Port)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 2222
```

### 3. Restrict SSH Access by IP

```powershell
# Allow SSH only from specific IP
New-NetFirewallRule -Name sshd-restricted -DisplayName 'OpenSSH Server (Restricted)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -RemoteAddress 10.0.10.10
```

### 4. Key Management

- Use passphrase-protected keys for sensitive environments
- Rotate keys periodically (every 6-12 months)
- Remove old keys from authorized_keys file
- Keep private keys secure - never share them

### 5. Monitoring

Enable SSH logging on M6800:

```powershell
# View SSH logs
Get-WinEvent -LogName "OpenSSH/Operational" | Select-Object -First 20

# Monitor failed login attempts
Get-WinEvent -LogName "OpenSSH/Operational" | Where-Object {$_.Message -like "*failed*"}
```

## Automated Scripts

### enable-ssh-firewall.ps1

Location: `C:\Users\Fred\projects\infrastructure\scripts\enable-ssh-firewall.ps1`

Automatically configures firewall rules for SSH server.

### setup-ssh-server.ps1

Automated script for complete SSH server setup on Windows:

```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Configure service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Create admin authorized_keys file
$authKeysFile = "$env:ProgramData\ssh\administrators_authorized_keys"
New-Item -Path $authKeysFile -ItemType File -Force
icacls.exe "$authKeysFile" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

### test-homelab-ssh.sh

Location: `C:\Users\Fred\projects\infrastructure\scripts\test-homelab-ssh.sh`

Tests SSH connectivity between homelab machines.

## Common Use Cases

### 1. Remote File Transfer (SCP)

```powershell
# Copy file to M6800
scp localfile.txt m6800:C:/Users/Fred/

# Copy file from M6800
scp m6800:C:/Users/Fred/remotefile.txt ./

# Copy directory recursively
scp -r localdir/ m6800:C:/Users/Fred/remotedir/
```

### 2. Remote Command Execution

```powershell
# Single command
ssh m6800 "powershell -Command Get-Process"

# Multiple commands
ssh m6800 "powershell -Command 'Get-Date; hostname; Get-Service sshd'"

# Run script
ssh m6800 "powershell -ExecutionPolicy Bypass -File C:/scripts/script.ps1"
```

### 3. Port Forwarding

```powershell
# Local port forwarding - Access M6800 service on local port 8080
ssh -L 8080:localhost:80 m6800

# Remote port forwarding - Expose local service to M6800
ssh -R 9090:localhost:8080 m6800

# Dynamic port forwarding (SOCKS proxy)
ssh -D 1080 m6800
```

### 4. SSH Tunneling for Home Assistant

```powershell
# Forward Home Assistant port through SSH tunnel
ssh -L 8123:localhost:8123 m6800

# Access in browser: http://localhost:8123
```

## Integration with Claude Code

Claude Code can use SSH to access remote development environments:

```bash
# From Claude Code on HOMELAB-COMMAND
# Access M6800 projects directory
ssh m6800 "cd C:/Users/Fred/projects && dir"

# Edit files remotely
ssh m6800 "powershell -Command 'Get-Content C:/Users/Fred/projects/file.txt'"
```

## Maintenance Tasks

### Weekly
- Review SSH logs for failed attempts
- Check authorized_keys file for unauthorized entries

### Monthly
- Test SSH connectivity from all client machines
- Verify firewall rules are correct
- Update OpenSSH if new version available

### Quarterly
- Review and remove old SSH keys
- Audit SSH configuration for security best practices
- Test backup SSH access methods

## References

- [Microsoft OpenSSH Documentation](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_overview)
- [OpenSSH Manual Pages](https://www.openssh.com/manual.html)
- Infrastructure scripts: `C:\Users\Fred\projects\infrastructure\scripts\`

## Recent Work Log

### 2025-12-13
- Configured SSH server on M6800
- Set up SSH key authentication from HOMELAB-COMMAND
- Created firewall rules for SSH access
- Tested bidirectional connectivity
- Documented troubleshooting steps for permission issues
