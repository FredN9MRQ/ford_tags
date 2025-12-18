# Clone All Repositories Script for HOMELAB-COMMAND
# Purpose: Clone all active repositories from GitHub
# Usage: .\clone-all-repos.ps1 [-TargetDir C:\path\to\projects] [-DryRun]

param(
    [string]$TargetDir = "$env:USERPROFILE\projects",
    [switch]$DryRun
)

$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"

# List of active repositories
$repos = @(
    "infrastructure",
    "claude-workflows",
    "VA-Strategy",
    "claude-code-history",
    "config"
)

$githubUser = "FredN9MRQ"

Write-Host "Clone All Repositories" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target directory: $TargetDir"
Write-Host "GitHub user: $githubUser"
Write-Host "Repositories: $($repos.Count)"
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor $Yellow
    Write-Host ""
}

# Create target directory if it doesn't exist
if (-not (Test-Path $TargetDir)) {
    Write-Host "Creating target directory: $TargetDir" -ForegroundColor $Yellow
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $TargetDir | Out-Null
    } else {
        Write-Host "[DRY RUN] Would create directory"
    }
}

# Change to target directory
if (-not $DryRun) {
    Set-Location $TargetDir
}

# Clone or check each repository
foreach ($repo in $repos) {
    $repoPath = Join-Path $TargetDir $repo
    $repoUrl = "git@github.com:$githubUser/$repo.git"

    Write-Host "[$repo]" -ForegroundColor Cyan

    if (Test-Path $repoPath) {
        Write-Host "  ✓ Already exists at: $repoPath" -ForegroundColor $Green

        # Check if it's a git repository
        $gitDir = Join-Path $repoPath ".git"
        if (Test-Path $gitDir) {
            # Get current branch and last commit
            if (-not $DryRun) {
                Push-Location $repoPath
                $branch = git rev-parse --abbrev-ref HEAD 2>$null
                $lastCommit = git log -1 --oneline 2>$null
                Write-Host "  Branch: $branch" -ForegroundColor $Yellow
                Write-Host "  Last commit: $lastCommit" -ForegroundColor $Yellow
                Pop-Location
            }
        } else {
            Write-Host "  ⚠ Directory exists but is not a git repository!" -ForegroundColor $Red
        }
    } else {
        Write-Host "  Cloning from: $repoUrl" -ForegroundColor $Yellow
        if (-not $DryRun) {
            try {
                git clone $repoUrl $repoPath 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ Successfully cloned" -ForegroundColor $Green
                } else {
                    Write-Host "  ✗ Clone failed" -ForegroundColor $Red
                }
            } catch {
                Write-Host "  ✗ Error: $_" -ForegroundColor $Red
            }
        } else {
            Write-Host "  [DRY RUN] Would clone: $repoUrl"
        }
    }
    Write-Host ""
}

# Summary
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host ""

$clonedCount = 0
$missingCount = 0

foreach ($repo in $repos) {
    $repoPath = Join-Path $TargetDir $repo
    if (Test-Path $repoPath) {
        $clonedCount++
    } else {
        $missingCount++
    }
}

Write-Host "Repositories cloned: $clonedCount / $($repos.Count)" -ForegroundColor $(if ($clonedCount -eq $repos.Count) { $Green } else { $Yellow })
if ($missingCount -gt 0) {
    Write-Host "Missing: $missingCount" -ForegroundColor $Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Verify SSH access to GitHub: ssh -T git@github.com"
Write-Host "  2. Navigate to a project: cd $TargetDir\infrastructure"
Write-Host "  3. Test Claude Code: claude"
Write-Host "  4. Pull latest changes: git pull"

if ($DryRun) {
    Write-Host ""
    Write-Host "This was a DRY RUN. Run without -DryRun to actually clone repositories." -ForegroundColor $Yellow
}
