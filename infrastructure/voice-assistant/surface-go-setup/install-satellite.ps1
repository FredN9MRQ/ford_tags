# Surface Go Voice Satellite Setup (Windows)
# PowerShell script to install Wyoming Satellite

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Surface Go Voice Satellite Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
Write-Host "Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Python 3.10 or later from:" -ForegroundColor Yellow
    Write-Host "https://www.python.org/downloads/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "During installation, make sure to check 'Add Python to PATH'" -ForegroundColor Yellow
    exit 1
}

# Check Python version (need 3.10+)
$versionString = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
$version = [decimal]$versionString
if ($version -lt 3.10) {
    Write-Host "Python version too old. Need 3.10+, found $versionString" -ForegroundColor Red
    exit 1
}

Write-Host "Python version OK: $versionString" -ForegroundColor Green
Write-Host ""

# Get Gaming PC IP
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Configuration" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$gamingPcIp = Read-Host "Enter your Gaming PC IP address (e.g., 192.168.1.100)"
$haIp = Read-Host "Enter your Home Assistant IP address (e.g., 192.168.1.50)"

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Green
Write-Host "  Gaming PC IP: $gamingPcIp" -ForegroundColor White
Write-Host "  Home Assistant IP: $haIp" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Is this correct? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Setup cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Installing Wyoming Satellite" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Create installation directory
$installPath = "$env:USERPROFILE\wyoming-satellite"
Write-Host "Creating installation directory at: $installPath" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $installPath | Out-Null
Set-Location $installPath

# Create virtual environment
Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
python -m venv venv

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

# Upgrade pip
Write-Host "Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# Install Wyoming satellite
Write-Host "Installing Wyoming Satellite (this may take a few minutes)..." -ForegroundColor Yellow
pip install wyoming-satellite

# Install PyAudio for microphone support
Write-Host "Installing audio dependencies..." -ForegroundColor Yellow
pip install pyaudio

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Creating Configuration" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Create configuration file
$configContent = @"
# Wyoming Satellite Configuration

# Microphone settings
microphone:
  device: ""  # Leave empty for default device
  sample_rate: 16000
  channels: 1

# Audio output settings
speaker:
  device: ""  # Leave empty for default device
  sample_rate: 22050

# Wyoming protocol settings
wyoming:
  # STT (Speech-to-Text) - Gaming PC Whisper
  stt:
    uri: "tcp://$gamingPcIp:10300"

  # TTS (Text-to-Speech) - Gaming PC Piper
  tts:
    uri: "tcp://$gamingPcIp:10200"

  # Wake word detection - Gaming PC OpenWakeWord
  wake:
    uri: "tcp://$gamingPcIp:10400"
    names:
      - "ok_nabu"  # Default wake word

# Home Assistant connection
home_assistant:
  url: "http://$haIp:8123"
  token: ""  # Add your long-lived access token here

# Satellite settings
satellite:
  name: "Surface Go"
  area: "office"  # Change to your room/area

# Audio feedback
sounds:
  awake: ""  # Path to sound file when wake word detected
  done: ""   # Path to sound file when processing complete

# Debug settings
debug: false
"@

Set-Content -Path "config.yaml" -Value $configContent
Write-Host "Configuration file created: $installPath\config.yaml" -ForegroundColor Green

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Testing Audio Devices" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Test audio devices
Write-Host "Available audio devices:" -ForegroundColor Yellow
python -c "import pyaudio; p = pyaudio.PyAudio(); [print(f'{i}: {p.get_device_info_by_index(i)[\"name\"]}') for i in range(p.get_device_count())]; p.terminate()"

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Get a Home Assistant Long-Lived Access Token:" -ForegroundColor White
Write-Host "   - Open Home Assistant: http://$haIp:8123" -ForegroundColor White
Write-Host "   - Go to Profile > Security > Long-Lived Access Tokens" -ForegroundColor White
Write-Host "   - Create a token and add it to config.yaml" -ForegroundColor White
Write-Host ""
Write-Host "2. Edit the configuration if needed:" -ForegroundColor White
Write-Host "   notepad $installPath\config.yaml" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Start the satellite:" -ForegroundColor White
Write-Host "   cd $installPath" -ForegroundColor Cyan
Write-Host "   .\venv\Scripts\Activate.ps1" -ForegroundColor Cyan
Write-Host "   wyoming-satellite --config config.yaml" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. To run automatically on startup, create a scheduled task or use:" -ForegroundColor White
Write-Host "   .\start-satellite.ps1" -ForegroundColor Cyan
Write-Host ""

# Create start script
$startScript = @"
# Start Wyoming Satellite
Set-Location "$installPath"
& ".\venv\Scripts\Activate.ps1"
wyoming-satellite --config config.yaml
"@

Set-Content -Path "start-satellite.ps1" -Value $startScript
Write-Host "Start script created: $installPath\start-satellite.ps1" -ForegroundColor Green
Write-Host ""
