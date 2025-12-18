# Gaming PC Setup Script for Voice Assistant AI Hub (Windows)
# PowerShell script for Windows setup

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Voice Assistant Gaming PC Setup (Windows)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some steps may require admin privileges" -ForegroundColor Yellow
    Write-Host ""
}

# Check Docker Desktop installation
Write-Host "Checking Docker Desktop..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker Desktop not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop first:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "2. Install and restart your computer" -ForegroundColor Yellow
    Write-Host "3. Enable WSL2 integration in Docker Desktop settings" -ForegroundColor Yellow
    Write-Host "4. Run this script again" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Check WSL2
Write-Host "Checking WSL2..." -ForegroundColor Yellow
try {
    $wslVersion = wsl --version
    Write-Host "WSL2 found" -ForegroundColor Green
} catch {
    Write-Host "WSL2 not found. Installing..." -ForegroundColor Yellow
    Write-Host "Run this command as Administrator:" -ForegroundColor Yellow
    Write-Host "wsl --install" -ForegroundColor Cyan
    Write-Host "Then restart and run this script again" -ForegroundColor Yellow
    exit 1
}

# Check NVIDIA GPU
Write-Host "Checking NVIDIA GPU..." -ForegroundColor Yellow
try {
    nvidia-smi | Out-Null
    Write-Host "NVIDIA GPU detected" -ForegroundColor Green
} catch {
    Write-Host "WARNING: nvidia-smi not found" -ForegroundColor Yellow
    Write-Host "Make sure NVIDIA drivers are installed" -ForegroundColor Yellow
}

# Test GPU in Docker
Write-Host ""
Write-Host "Testing GPU access in Docker..." -ForegroundColor Yellow
try {
    docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
    Write-Host "GPU access working!" -ForegroundColor Green
} catch {
    Write-Host "GPU test failed!" -ForegroundColor Red
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "1. Docker Desktop is running" -ForegroundColor Yellow
    Write-Host "2. WSL2 NVIDIA drivers are installed" -ForegroundColor Yellow
    Write-Host "3. GPU support is enabled in Docker Desktop settings" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Continue anyway? (Y/N)" -ForegroundColor Yellow
    $continue = Read-Host
    if ($continue -ne "Y" -and $continue -ne "y") {
        exit 1
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Starting AI Services" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Create config directory
New-Item -ItemType Directory -Force -Path "config\custom-wakewords" | Out-Null

# Start Docker Compose
Write-Host "Starting Docker containers..." -ForegroundColor Yellow
docker-compose up -d

Write-Host ""
Write-Host "Waiting for services to start..." -ForegroundColor Green
Start-Sleep -Seconds 15

# Check service status
Write-Host ""
Write-Host "Service Status:" -ForegroundColor Cyan
docker-compose ps

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Downloading AI Models" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Download Ollama models
Write-Host "Downloading Ollama models (this may take 10-20 minutes)..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Downloading Llama 3.1 8B (4.7GB)..." -ForegroundColor Yellow
docker exec ollama ollama pull llama3.1:8b

Write-Host ""
Write-Host "Downloading Phi-3 Mini (2.3GB - faster responses)..." -ForegroundColor Yellow
docker exec ollama ollama pull phi3:mini

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Get local IP
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1).IPAddress

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Service URLs:" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Ollama API:        http://localhost:11434" -ForegroundColor White
Write-Host "Ollama Web UI:     http://localhost:8080" -ForegroundColor White
Write-Host "Whisper STT:       http://localhost:10300" -ForegroundColor White
Write-Host "Piper TTS:         http://localhost:10200" -ForegroundColor White
Write-Host "OpenWakeWord:      http://localhost:10400" -ForegroundColor White
Write-Host ""
Write-Host "Your PC's IP Address: $localIP" -ForegroundColor Yellow
Write-Host "(Use this IP in Home Assistant and Surface Go configuration)" -ForegroundColor Yellow
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "1. Configure Home Assistant (see ..\home-assistant-config\)" -ForegroundColor White
Write-Host "2. Set up Surface Go satellite (see ..\surface-go-setup\)" -ForegroundColor White
Write-Host "3. Test voice commands through Home Assistant" -ForegroundColor White
Write-Host ""
Write-Host "Test Ollama: http://localhost:8080" -ForegroundColor Green
Write-Host ""
