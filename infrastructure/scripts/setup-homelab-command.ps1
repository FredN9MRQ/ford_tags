# HOMELAB-COMMAND Setup Script
# Purpose: Automated setup of HOMELAB-COMMAND as primary Claude Code workstation
# Run this script on HOMELAB-COMMAND (10.0.10.10) with Administrator privileges

param(
    [switch]$DryRun,
    [switch]$SkipNodeInstall,
    [switch]$SkipGitInstall,
    [switch]$SkipSSH
)

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor $Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $Red
}

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires Administrator privileges"
    Write-Host "Please run PowerShell as Administrator and try again"
    exit 1
}

if ($DryRun) {
    Write-Warning "DRY RUN MODE - No changes will be made"
}

# ============================================================================
# Phase 1: Install Core Dependencies
# ============================================================================

Write-Step "Phase 1: Checking Core Dependencies"

# Check Node.js
Write-Host "`nChecking Node.js..."
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion -match 'v(\d+)') {
        $majorVersion = [int]$matches[1]
        if ($majorVersion -ge 20) {
            Write-Success "Node.js $nodeVersion installed"
        } else {
            Write-Warning "Node.js $nodeVersion installed but version 20+ recommended"
            if (-not $SkipNodeInstall) {
                Write-Host "Upgrading Node.js via winget..."
                if (-not $DryRun) {
                    winget install OpenJS.NodeJS.LTS
                }
            }
        }
    }
} catch {
    Write-Warning "Node.js not found"
    if (-not $SkipNodeInstall) {
        Write-Host "Installing Node.js via winget..."
        if (-not $DryRun) {
            winget install OpenJS.NodeJS.LTS
            Write-Success "Node.js installed. You may need to restart PowerShell."
        } else {
            Write-Host "[DRY RUN] Would install: winget install OpenJS.NodeJS.LTS"
        }
    }
}

# Check Git
Write-Host "`nChecking Git..."
try {
    $gitVersion = git --version 2>$null
    Write-Success "$gitVersion installed"
} catch {
    Write-Warning "Git not found"
    if (-not $SkipGitInstall) {
        Write-Host "Installing Git via winget..."
        if (-not $DryRun) {
            winget install Git.Git
            Write-Success "Git installed. You may need to restart PowerShell."
        } else {
            Write-Host "[DRY RUN] Would install: winget install Git.Git"
        }
    }
}

# ============================================================================
# Phase 2: SSH Setup
# ============================================================================

Write-Step "Phase 2: SSH Configuration"

if (-not $SkipSSH) {
    # Check if SSH keys exist
    Write-Host "`nChecking SSH keys..."
    $sshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519"
    if (Test-Path $sshKeyPath) {
        Write-Success "SSH key already exists at $sshKeyPath"
    } else {
        Write-Warning "No SSH key found"
        Write-Host "To generate SSH key, run:"
        Write-Host "  ssh-keygen -t ed25519 -C `"your_email@example.com`""
        Write-Host ""
        Write-Host "Then add the public key to GitHub:"
        Write-Host "  Get-Content ~\.ssh\id_ed25519.pub | Set-Clipboard"
        Write-Host "  Visit: https://github.com/settings/keys"
    }

    # Check OpenSSH Server
    Write-Host "`nChecking OpenSSH Server..."
    $sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

    if ($sshServer.State -eq "Installed") {
        Write-Success "OpenSSH Server is installed"
    } else {
        Write-Warning "OpenSSH Server not installed"
        if (-not $DryRun) {
            Write-Host "Installing OpenSSH Server..."
            Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
            Write-Success "OpenSSH Server installed"
        } else {
            Write-Host "[DRY RUN] Would install OpenSSH Server"
        }
    }

    # Check SSH service
    Write-Host "`nChecking SSH service..."
    $sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue

    if ($sshdService) {
        if ($sshdService.Status -eq "Running") {
            Write-Success "SSH service is running"
        } else {
            Write-Warning "SSH service is stopped"
            if (-not $DryRun) {
                Start-Service sshd
                Write-Success "SSH service started"
            } else {
                Write-Host "[DRY RUN] Would start SSH service"
            }
        }

        if ($sshdService.StartType -ne "Automatic") {
            Write-Warning "SSH service not set to automatic startup"
            if (-not $DryRun) {
                Set-Service -Name sshd -StartupType 'Automatic'
                Write-Success "SSH service set to automatic startup"
            } else {
                Write-Host "[DRY RUN] Would set SSH service to automatic"
            }
        }
    } else {
        Write-Warning "SSH service not found (install OpenSSH Server first)"
    }

    # Check firewall rule
    Write-Host "`nChecking SSH firewall rule..."
    $firewallRule = Get-NetFirewallRule -Name "*ssh*" -ErrorAction SilentlyContinue
    if ($firewallRule) {
        Write-Success "SSH firewall rule exists"
    } else {
        Write-Warning "No SSH firewall rule found"
        if (-not $DryRun) {
            New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
            Write-Success "SSH firewall rule created"
        } else {
            Write-Host "[DRY RUN] Would create SSH firewall rule"
        }
    }
}

# ============================================================================
# Phase 3: Install Claude Code
# ============================================================================

Write-Step "Phase 3: Claude Code Installation"

Write-Host "`nChecking Claude Code..."
try {
    $claudeVersion = claude --version 2>$null
    Write-Success "Claude Code $claudeVersion installed"
} catch {
    Write-Warning "Claude Code not found"
    Write-Host "Installing Claude Code via npm..."
    if (-not $DryRun) {
        npm install -g @anthropic-ai/claude-code
        Write-Success "Claude Code installed"
        Write-Host ""
        Write-Host "Next step: Authenticate Claude Code"
        Write-Host "  Run: claude auth"
    } else {
        Write-Host "[DRY RUN] Would install: npm install -g @anthropic-ai/claude-code"
    }
}

# ============================================================================
# Phase 4: Repository Setup
# ============================================================================

Write-Step "Phase 4: Repository Setup"

$projectsDir = "$env:USERPROFILE\projects"
Write-Host "`nChecking projects directory..."

if (Test-Path $projectsDir) {
    Write-Success "Projects directory exists: $projectsDir"
} else {
    Write-Warning "Projects directory not found"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $projectsDir | Out-Null
        Write-Success "Created: $projectsDir"
    } else {
        Write-Host "[DRY RUN] Would create: $projectsDir"
    }
}

# List of repositories to clone
$repos = @(
    "infrastructure",
    "claude-workflows",
    "VA-Strategy",
    "claude-code-history",
    "config"
)

Write-Host "`nChecking repositories..."
foreach ($repo in $repos) {
    $repoPath = Join-Path $projectsDir $repo
    if (Test-Path $repoPath) {
        Write-Success "$repo already cloned"
    } else {
        Write-Warning "$repo not found"
        if (-not $DryRun) {
            Write-Host "To clone, run:"
            Write-Host "  cd $projectsDir"
            Write-Host "  git clone git@github.com:FredN9MRQ/$repo.git"
        } else {
            Write-Host "[DRY RUN] Would clone: git@github.com:FredN9MRQ/$repo.git"
        }
    }
}

# ============================================================================
# Summary
# ============================================================================

Write-Step "Setup Summary"

Write-Host ""
Write-Host "Core Dependencies:" -ForegroundColor $Cyan
try {
    $nodeVer = node --version 2>$null
    Write-Host "  Node.js: $nodeVer" -ForegroundColor $Green
} catch {
    Write-Host "  Node.js: Not installed" -ForegroundColor $Red
}

try {
    $gitVer = git --version 2>$null
    Write-Host "  Git: $gitVer" -ForegroundColor $Green
} catch {
    Write-Host "  Git: Not installed" -ForegroundColor $Red
}

try {
    $claudeVer = claude --version 2>$null
    Write-Host "  Claude Code: $claudeVer" -ForegroundColor $Green
} catch {
    Write-Host "  Claude Code: Not installed" -ForegroundColor $Red
}

Write-Host ""
Write-Host "SSH Configuration:" -ForegroundColor $Cyan
$sshService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if ($sshService -and $sshService.Status -eq "Running") {
    Write-Host "  SSH Server: Running" -ForegroundColor $Green
    Write-Host "  Test from remote: ssh $env:USERNAME@10.0.10.10" -ForegroundColor $Yellow
} else {
    Write-Host "  SSH Server: Not running" -ForegroundColor $Red
}

Write-Host ""
Write-Host "Repositories:" -ForegroundColor $Cyan
$clonedCount = 0
foreach ($repo in $repos) {
    $repoPath = Join-Path $projectsDir $repo
    if (Test-Path $repoPath) {
        $clonedCount++
    }
}
Write-Host "  Cloned: $clonedCount / $($repos.Count)" -ForegroundColor $(if ($clonedCount -eq $repos.Count) { $Green } else { $Yellow })

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor $Cyan
Write-Host "  1. Ensure SSH keys are generated and added to GitHub"
Write-Host "  2. Authenticate Claude Code: claude auth"
Write-Host "  3. Clone missing repositories to $projectsDir"
Write-Host "  4. Test SSH access from n8n VM"
Write-Host "  5. Test VSCode Remote SSH from M6800"
Write-Host ""
Write-Host "For detailed instructions, see: HOMELAB-COMMAND-SETUP.md"

if ($DryRun) {
    Write-Host ""
    Write-Warning "This was a DRY RUN. Run without -DryRun to apply changes."
}
