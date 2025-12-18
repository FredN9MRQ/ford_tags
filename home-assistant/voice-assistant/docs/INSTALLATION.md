# Installation Guide - Local Voice Assistant

Complete step-by-step installation guide for your privacy-focused, GPU-accelerated voice assistant.

## Overview

This installation consists of three main components:
1. **Gaming PC** - AI processing hub (Ollama, Whisper, Piper)
2. **Home Assistant** - Central coordinator and automation
3. **Surface Go** - Voice satellite (microphone/speaker interface)

## Prerequisites

### Gaming PC
- Windows 10/11 or Linux (Ubuntu 22.04+ recommended)
- NVIDIA RTX 5060 8GB (or similar GPU with 6GB+ VRAM)
- 16GB+ RAM
- 50GB+ free disk space
- Docker Desktop (Windows) or Docker Engine (Linux)
- Network connection

### Home Assistant
- Running Home Assistant instance (version 2023.11+)
- Access to configuration files
- Network connectivity to Gaming PC

### Surface Go
- Windows 10/11 or Linux
- Working microphone and speakers
- Python 3.10+
- Network connectivity to Gaming PC and Home Assistant

## Installation Steps

### Part 1: Gaming PC Setup (AI Hub)

#### Windows

1. **Install Prerequisites**
   - Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Enable WSL2: Open PowerShell as Admin and run:
     ```powershell
     wsl --install
     ```
   - Install NVIDIA drivers with WSL support
   - Restart your computer

2. **Verify GPU Access**
   ```powershell
   docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
   ```
   You should see your GPU information.

3. **Run Setup Script**
   ```powershell
   cd C:\Users\fredb\voice-assistant-project\gaming-pc-setup
   .\setup.ps1
   ```

4. **Wait for Models to Download**
   - Llama 3.1 8B: ~4.7GB
   - Phi-3 Mini: ~2.3GB
   - Whisper Large v3: ~3GB
   - Piper voices: ~100MB

   Total: ~10-15 minutes on fast connection

5. **Note Your IP Address**
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" under your active network adapter (e.g., 192.168.1.100)

#### Linux

1. **Run Setup Script**
   ```bash
   cd ~/voice-assistant-project/gaming-pc-setup
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Log Out and Back In**
   (Required for Docker group membership)

3. **Verify Services**
   ```bash
   docker-compose ps
   ```
   All services should show "Up"

4. **Note Your IP Address**
   ```bash
   ip addr show | grep "inet "
   ```

### Part 2: Home Assistant Configuration

1. **Get Your Gaming PC IP**
   From Part 1 (e.g., 192.168.1.100)

2. **Backup Current Configuration**
   ```bash
   # SSH into Home Assistant or use File Editor
   cp /config/configuration.yaml /config/configuration.yaml.backup
   ```

3. **Copy Configuration Files**

   Transfer these files to your Home Assistant:
   - `home-assistant-config/configuration.yaml` → Merge with your existing config
   - `home-assistant-config/automations.yaml` → `/config/automations.yaml`
   - `home-assistant-config/scripts.yaml` → `/config/scripts.yaml`

4. **Create Secrets File**
   ```bash
   # In Home Assistant
   nano /config/secrets.yaml
   ```

   Add:
   ```yaml
   gaming_pc_ip: "192.168.1.100"  # Your Gaming PC IP
   ```

5. **Update Configuration**

   In your `configuration.yaml`, replace `GAMING_PC_IP` with `!secret gaming_pc_ip`

6. **Check Configuration**
   - Go to Developer Tools → YAML
   - Click "Check Configuration"
   - Fix any errors

7. **Restart Home Assistant**
   - Developer Tools → Restart → Restart Home Assistant

8. **Verify Wyoming Services**
   - Settings → Devices & Services
   - You should see:
     - Whisper STT
     - Piper TTS
     - OpenWakeWord

### Part 3: Configure Assist Pipeline

1. **Create Assist Pipeline**
   - Settings → Voice Assistants → Add Assistant
   - Name: "Local Voice Assistant"
   - Language: English
   - Conversation agent: Home Assistant
   - Speech-to-text: Faster Whisper
   - Text-to-speech: Piper
   - Wake word: ok_nabu

2. **Create LLM Pipeline** (Optional - for conversational AI)
   - Add another assistant
   - Name: "Local LLM Assistant"
   - Conversation agent: Local LLM
   - (Same STT/TTS/Wake word)

3. **Set as Default**
   - Click the three dots on your preferred assistant
   - "Set as preferred"

### Part 4: Surface Go Satellite Setup

#### Windows

1. **Install Python**
   - Download from [python.org](https://www.python.org/downloads/)
   - During installation, CHECK "Add Python to PATH"
   - Install Python 3.10 or later

2. **Run Setup Script**
   ```powershell
   cd C:\Users\fredb\voice-assistant-project\surface-go-setup
   .\install-satellite.ps1
   ```

3. **Enter Configuration**
   - Gaming PC IP: (from Part 1)
   - Home Assistant IP: (your HA instance)

4. **Get Home Assistant Token**
   - Open Home Assistant in browser
   - Click your profile (bottom left)
   - Scroll down to "Long-Lived Access Tokens"
   - Click "Create Token"
   - Name it "Surface Go Satellite"
   - Copy the token

5. **Add Token to Config**
   ```powershell
   notepad $env:USERPROFILE\wyoming-satellite\config.yaml
   ```

   Paste token in the `token: ""` field

6. **Start the Satellite**
   ```powershell
   cd $env:USERPROFILE\wyoming-satellite
   .\start-satellite.ps1
   ```

#### Linux

1. **Run Setup Script**
   ```bash
   cd ~/voice-assistant-project/surface-go-setup
   chmod +x install-satellite.sh
   ./install-satellite.sh
   ```

2. **Get Home Assistant Token**
   (Same as Windows step 4)

3. **Add Token to Config**
   ```bash
   nano ~/wyoming-satellite/config.yaml
   ```

   Paste token in the `token: ""` field

4. **Start the Service**
   ```bash
   systemctl --user start wyoming-satellite.service
   ```

5. **Check Status**
   ```bash
   systemctl --user status wyoming-satellite.service
   ```

### Part 5: Testing

1. **Test Voice Satellite**
   - Say "ok nabu" (wake word)
   - Wait for beep/confirmation
   - Say "What's the weather?"
   - You should hear a response

2. **Test LLM Integration**
   - In Home Assistant, go to Developer Tools → Assist
   - Type or speak: "What should I focus on today?"
   - You should get an LLM-generated response

3. **Test Ollama Web UI**
   - Open browser: `http://YOUR_GAMING_PC_IP:8080`
   - You should see the Ollama web interface
   - Try chatting with the models

4. **Check Docker Services**
   ```bash
   # On Gaming PC
   docker-compose ps
   ```
   All should show "Up" status

## Verification Checklist

- [ ] Gaming PC - All Docker containers running
- [ ] Gaming PC - Ollama models downloaded
- [ ] Gaming PC - GPU accessible in containers
- [ ] Home Assistant - Wyoming integrations connected
- [ ] Home Assistant - Assist pipeline configured
- [ ] Home Assistant - Configuration check passed
- [ ] Surface Go - Satellite installed
- [ ] Surface Go - Can hear wake word detection
- [ ] Voice commands working end-to-end
- [ ] LLM responses working

## Next Steps

After successful installation:

1. **Configure Calendars** - See [CALENDAR_SETUP.md](CALENDAR_SETUP.md)
2. **Add Voice Commands** - See [COMMANDS.md](COMMANDS.md)
3. **Customize Automations** - Edit `automations.yaml`
4. **Add More Satellites** - Set up Raspberry Pi satellites

## Common Issues

If something isn't working, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Performance Tuning

### Gaming PC (Optional)

For better performance, you can:

1. **Use Faster Models**
   ```bash
   docker exec ollama ollama pull phi3:mini  # Already done
   ```

2. **Adjust Whisper Model**
   In `docker-compose.yml`, change:
   ```yaml
   --model large-v3  # Most accurate, slower
   # to
   --model medium    # Faster, still good
   ```

3. **Monitor GPU Usage**
   ```bash
   nvidia-smi -l 1  # Updates every second
   ```

### Home Assistant

1. **Reduce TTS Latency**
   - Use local recorder for faster playback
   - Adjust chunk size in Piper settings

2. **Optimize Database**
   - Set recorder history to 7 days
   - Exclude noisy entities

## Maintenance

### Regular Tasks

1. **Update Docker Images**
   ```bash
   cd gaming-pc-setup
   docker-compose pull
   docker-compose up -d
   ```

2. **Update Ollama Models**
   ```bash
   docker exec ollama ollama pull llama3.1:8b
   ```

3. **Backup Home Assistant**
   - Settings → System → Backups → Create Backup

4. **Check Logs**
   ```bash
   # Gaming PC
   docker-compose logs -f

   # Surface Go (Linux)
   journalctl --user -u wyoming-satellite.service -f
   ```

## Security Notes

- All processing is local - no cloud dependencies
- Keep Home Assistant access tokens secure
- Consider VPN if accessing remotely
- Regular security updates for all components

## Support

- **Issues**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Community**: Home Assistant forums
- **Documentation**:
  - [Home Assistant Voice](https://www.home-assistant.io/voice_control/)
  - [Wyoming Protocol](https://github.com/rhasspy/wyoming)
  - [Ollama](https://ollama.ai/docs)
