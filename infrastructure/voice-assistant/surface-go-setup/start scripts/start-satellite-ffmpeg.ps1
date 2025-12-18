# Wyoming Satellite with ffmpeg audio (Windows)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Wyoming Satellite (ffmpeg audio)" -ForegroundColor Cyan  
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$GAMING_PC_IP = "10.0.10.92"
$HA_IP = "10.0.10.114"
$SATELLITE_NAME = "Surface Go"
$SATELLITE_AREA = "office"
$WAKE_WORD = "ok_nabu"

# Audio device names - YOU MUST SET THESE!
# Run this command to find your device names:
#   ffmpeg -list_devices true -f dshow -i dummy
$MIC_DEVICE = "Microphone Array (Realtek(R) Audio)"  # CHANGE THIS
$SPEAKER_DEVICE = "Speakers (Realtek(R) Audio)"      # CHANGE THIS

# Change to installation directory
Set-Location "$env:USERPROFILE\wyoming-satellite"

# Activate venv
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

# Check if ffmpeg is installed
Write-Host "Checking for ffmpeg..." -ForegroundColor Yellow
try {
    $null = ffmpeg -version 2>&1
    Write-Host "  ✓ ffmpeg found" -ForegroundColor Green
} catch {
    Write-Host "  ✗ ffmpeg not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install ffmpeg:" -ForegroundColor Yellow
    Write-Host "  winget install ffmpeg" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "After installing, close and reopen PowerShell" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Green
Write-Host "  Satellite: $SATELLITE_NAME ($SATELLITE_AREA)" -ForegroundColor White
Write-Host "  Gaming PC: $GAMING_PC_IP" -ForegroundColor White
Write-Host "  Home Assistant: $HA_IP" -ForegroundColor White
Write-Host "  Wake Word: $WAKE_WORD" -ForegroundColor White
Write-Host "  Microphone: $MIC_DEVICE" -ForegroundColor White
Write-Host "  Speaker: $SPEAKER_DEVICE" -ForegroundColor White
Write-Host ""

# Test services
Write-Host "Testing services..." -ForegroundColor Yellow
$allGood = $true

$services = @(
    @{Name="Piper TTS"; Port=10200},
    @{Name="Whisper STT"; Port=10300},
    @{Name="OpenWakeWord"; Port=10400}
)

foreach ($service in $services) {
    $test = Test-NetConnection -ComputerName $GAMING_PC_IP -Port $service.Port -WarningAction SilentlyContinue -InformationLevel Quiet
    if ($test) {
        Write-Host "  ✓ $($service.Name)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($service.Name) - not reachable" -ForegroundColor Red
        $allGood = $false
    }
}

if (-not $allGood) {
    Write-Host ""
    Write-Host "WARNING: Some services not reachable!" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        exit 0
    }
}

Write-Host ""
Write-Host "Starting Wyoming Satellite..." -ForegroundColor Green
Write-Host "Say '$WAKE_WORD' to test" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

# Start satellite with ffmpeg audio
python -m wyoming_satellite `
  --uri tcp://0.0.0.0:10700 `
  --name "$SATELLITE_NAME" `
  --area "$SATELLITE_AREA" `
  --mic-command "ffmpeg -f dshow -i audio='$MIC_DEVICE' -ar 16000 -ac 1 -f s16le -" `
  --snd-command "ffmpeg -f s16le -ar 22050 -ac 1 -i - -f dshow audio='$SPEAKER_DEVICE'" `
  --wake-uri tcp://${GAMING_PC_IP}:10400 `
  --wake-word-name "$WAKE_WORD" `
  --debug