# Aider Helper Functions for Fred's Workflow
# Add to PowerShell profile: . C:\Users\Fred\projects\aider-helpers.ps1

# Quick launch Aider with 7b model (fast, everyday coding)
function aider-fast {
    aider --model ollama/qwen2.5-coder:7b-instruct @args
}

# Launch Aider with 14b model (complex tasks, better reasoning)
function aider-smart {
    aider --model ollama/qwen2.5-coder:14b-instruct-q4_K_M @args
}

# Launch Aider with architect mode (planning, design)
function aider-plan {
    aider --model ollama/qwen2.5-coder:14b-instruct-q4_K_M --architect @args
}

# Quick commit with Aider (use for git commit messages)
function aider-commit {
    aider --model ollama/qwen2.5-coder:7b-instruct --commit
}

# Launch Aider in watch mode (auto-reload on file changes)
function aider-watch {
    aider --model ollama/qwen2.5-coder:7b-instruct --watch-files @args
}

# Show Aider status and current models
function aider-status {
    Write-Host "=== Aider Status ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available models:" -ForegroundColor Yellow
    ollama list | Select-String "qwen2.5-coder"
    Write-Host ""
    Write-Host "Quick commands:" -ForegroundColor Yellow
    Write-Host "  aider-fast   - Fast 7b model (everyday coding)"
    Write-Host "  aider-smart  - Powerful 14b model (complex tasks)"
    Write-Host "  aider-plan   - Architect mode (planning)"
    Write-Host "  aider-commit - Generate commit messages"
    Write-Host "  aider-watch  - Watch mode (auto-reload)"
    Write-Host ""
    Write-Host "Example usage:" -ForegroundColor Yellow
    Write-Host "  cd C:\Users\Fred\projects\VA-Strategy"
    Write-Host "  aider-fast"
    Write-Host "  > Add a function to parse headache log entries"
}

# Token usage estimator
function aider-estimate {
    param(
        [Parameter(Mandatory=$false)]
        [string]$model = "7b"
    )

    Write-Host "=== Token Cost Comparison ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Local Ollama (your setup):" -ForegroundColor Green
    Write-Host "  Cost: `$0.00 (free!)"
    Write-Host "  Speed: Fast (8GB RTX 5060)"
    Write-Host "  Privacy: 100% local"
    Write-Host ""
    Write-Host "Claude API (Claude Code):" -ForegroundColor Yellow
    Write-Host "  Cost: ~`$3-15 per million tokens"
    Write-Host "  Speed: Depends on network"
    Write-Host "  Limits: Monthly cap"
    Write-Host ""
    Write-Host "Recommendation: Use Aider for routine coding, Claude for complex architecture" -ForegroundColor Cyan
}

Write-Host "Aider helpers loaded! Type 'aider-status' for quick start." -ForegroundColor Green
