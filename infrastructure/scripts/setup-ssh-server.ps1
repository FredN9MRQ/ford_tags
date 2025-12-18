# Setup OpenSSH Server on Windows for n8n integration
# Run this script as Administrator

Write-Host "=== Installing OpenSSH Server ===" -ForegroundColor Cyan

# Install OpenSSH Server if not already installed
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the service
Start-Service sshd

# Set service to start automatically
Set-Service -Name sshd -StartupType 'Automatic'

# Confirm firewall rule
$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if ($null -eq $firewallRule) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "Firewall rule created" -ForegroundColor Green
} else {
    Write-Host "Firewall rule already exists" -ForegroundColor Yellow
}

Write-Host "`n=== Adding n8n SSH Public Key ===" -ForegroundColor Cyan

# Create .ssh directory if it doesn't exist
$sshDir = "$env:USERPROFILE\.ssh"
if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force
    Write-Host "Created $sshDir" -ForegroundColor Green
}

# Add public key to authorized_keys
$authorizedKeys = "$sshDir\authorized_keys"
$publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7Z8MRRnwUYH9sUu5daOxVn5EQrLrPwTC3Z3SJkDM1L n8n-to-claude-code"

if (Test-Path $authorizedKeys) {
    $existingKeys = Get-Content $authorizedKeys
    if ($existingKeys -contains $publicKey) {
        Write-Host "Public key already exists in authorized_keys" -ForegroundColor Yellow
    } else {
        Add-Content -Path $authorizedKeys -Value $publicKey
        Write-Host "Added public key to authorized_keys" -ForegroundColor Green
    }
} else {
    Set-Content -Path $authorizedKeys -Value $publicKey
    Write-Host "Created authorized_keys with public key" -ForegroundColor Green
}

# Set correct permissions (important for Windows OpenSSH)
icacls $authorizedKeys /inheritance:r
icacls $authorizedKeys /grant:r "$env:USERNAME:F"
icacls $authorizedKeys /grant SYSTEM:F

Write-Host "`n=== SSH Server Setup Complete ===" -ForegroundColor Green
Write-Host "Service Status:" -ForegroundColor Cyan
Get-Service sshd | Select-Object Name, Status, StartType
