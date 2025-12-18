# Enable SSH Server Firewall Rule
# Run this on HOMELAB-COMMAND as Administrator

Write-Host "Enabling SSH Server Firewall Rule..." -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

# Check if SSH service exists
$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if (-not $sshdService) {
    Write-Host "ERROR: SSH service (sshd) not found" -ForegroundColor Red
    Write-Host "Install OpenSSH Server first:" -ForegroundColor Yellow
    Write-Host "  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0" -ForegroundColor Yellow
    exit 1
}

# Check if firewall rule already exists
$existingRule = Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue
if ($existingRule) {
    Write-Host "SSH firewall rule already exists" -ForegroundColor Yellow
    Write-Host "Rule details:" -ForegroundColor Cyan
    $existingRule | Format-List Name, DisplayName, Enabled, Direction, Action

    # Enable it if disabled
    if (-not $existingRule.Enabled) {
        Write-Host "Enabling existing rule..." -ForegroundColor Yellow
        Enable-NetFirewallRule -Name "sshd"
        Write-Host "SSH firewall rule enabled!" -ForegroundColor Green
    } else {
        Write-Host "Rule is already enabled" -ForegroundColor Green
    }
} else {
    # Create new firewall rule
    Write-Host "Creating SSH firewall rule..." -ForegroundColor Yellow
    New-NetFirewallRule -Name sshd `
        -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 | Out-Null

    Write-Host "SSH firewall rule created successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Checking SSH service status..." -ForegroundColor Cyan
$sshdService = Get-Service -Name sshd
if ($sshdService.Status -eq "Running") {
    Write-Host "SSH service is running" -ForegroundColor Green
} else {
    Write-Host "SSH service is stopped, starting it..." -ForegroundColor Yellow
    Start-Service sshd
    Write-Host "SSH service started" -ForegroundColor Green
}

# Set to automatic startup if not already
if ($sshdService.StartType -ne "Automatic") {
    Write-Host "Setting SSH service to automatic startup..." -ForegroundColor Yellow
    Set-Service -Name sshd -StartupType 'Automatic'
    Write-Host "SSH service set to automatic startup" -ForegroundColor Green
}

Write-Host ""
Write-Host "Current network configuration:" -ForegroundColor Cyan
ipconfig | Select-String "IPv4"

Write-Host ""
Write-Host "Testing SSH locally..." -ForegroundColor Cyan
$testResult = Test-NetConnection -ComputerName localhost -Port 22 -InformationLevel Quiet
if ($testResult) {
    Write-Host "SSH port 22 is accessible on localhost" -ForegroundColor Green
} else {
    Write-Host "WARNING: SSH port 22 not responding on localhost" -ForegroundColor Red
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Note your IPv4 address above"
Write-Host "  2. From M6800, test: ssh username@YOUR_IP"
Write-Host "  3. If successful, set up DHCP reservation for 10.0.10.10"
Write-Host ""
