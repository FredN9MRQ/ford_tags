# Home Assistant Configuration Sync Script
# Syncs local config files to Home Assistant server

param(
    [string]$HAServer = "10.0.10.24",
    [switch]$DryRun,
    [switch]$CheckOnly
)

$ConfigDir = Join-Path $PSScriptRoot "..\home-assistant"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Home Assistant Config Sync" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Source: $ConfigDir"
Write-Host "Target: \\$HAServer\config"
Write-Host ""

# Check if source directory exists
if (-not (Test-Path $ConfigDir)) {
    Write-Host "ERROR: Config directory not found: $ConfigDir" -ForegroundColor Red
    exit 1
}

# Check if HA server is reachable
Write-Host "Checking connectivity to $HAServer..." -ForegroundColor Yellow
if (-not (Test-Connection -ComputerName $HAServer -Count 1 -Quiet)) {
    Write-Host "ERROR: Cannot reach Home Assistant server at $HAServer" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Server is reachable" -ForegroundColor Green

# Try to access Samba share
$RemotePath = "\\$HAServer\config"
Write-Host "Checking Samba share access..." -ForegroundColor Yellow
if (-not (Test-Path $RemotePath)) {
    Write-Host "ERROR: Cannot access $RemotePath" -ForegroundColor Red
    Write-Host "Make sure Samba add-on is installed and running on Home Assistant" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Samba share accessible" -ForegroundColor Green
Write-Host ""

# Files to sync
$FilesToSync = @(
    "configuration.yaml",
    "automations.yaml",
    "scripts.yaml",
    "scenes.yaml",
    "switches.yaml",
    "secrets.yaml"
)

if ($CheckOnly) {
    Write-Host "Configuration check mode - comparing local vs remote files:" -ForegroundColor Cyan
    Write-Host ""

    foreach ($file in $FilesToSync) {
        $LocalFile = Join-Path $ConfigDir $file
        $RemoteFile = Join-Path $RemotePath $file

        if (Test-Path $LocalFile) {
            if (Test-Path $RemoteFile) {
                $LocalHash = (Get-FileHash $LocalFile -Algorithm MD5).Hash
                $RemoteHash = (Get-FileHash $RemoteFile -Algorithm MD5).Hash

                if ($LocalHash -eq $RemoteHash) {
                    Write-Host "  ✓ $file - No changes" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠ $file - Modified" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  + $file - New file" -ForegroundColor Cyan
            }
        }
    }
    Write-Host ""
    Write-Host "Use without -CheckOnly flag to sync files" -ForegroundColor Yellow
    exit 0
}

# Backup remote configs before sync
$BackupPath = Join-Path $RemotePath "backup_$Timestamp"
Write-Host "Creating backup at: $BackupPath" -ForegroundColor Yellow
try {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    foreach ($file in $FilesToSync) {
        $RemoteFile = Join-Path $RemotePath $file
        if (Test-Path $RemoteFile) {
            Copy-Item $RemoteFile -Destination $BackupPath -Force
        }
    }
    Write-Host "✓ Backup created" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Backup failed: $_" -ForegroundColor Yellow
}
Write-Host ""

# Sync files
Write-Host "Syncing configuration files..." -ForegroundColor Cyan
$SyncCount = 0

foreach ($file in $FilesToSync) {
    $LocalFile = Join-Path $ConfigDir $file
    $RemoteFile = Join-Path $RemotePath $file

    if (Test-Path $LocalFile) {
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would copy: $file" -ForegroundColor Yellow
        } else {
            try {
                Copy-Item $LocalFile -Destination $RemoteFile -Force
                Write-Host "  ✓ $file" -ForegroundColor Green
                $SyncCount++
            } catch {
                Write-Host "  ✗ $file - ERROR: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  - $file (not found locally, skipping)" -ForegroundColor Gray
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete. No files were actually copied." -ForegroundColor Yellow
} else {
    Write-Host "Sync complete! $SyncCount file(s) copied." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to Home Assistant: http://$HAServer:8123" -ForegroundColor White
    Write-Host "2. Developer Tools -> YAML -> Check Configuration" -ForegroundColor White
    Write-Host "3. If valid, reload or restart Home Assistant" -ForegroundColor White
    Write-Host ""
    Write-Host "Backup location: $BackupPath" -ForegroundColor Gray
}
