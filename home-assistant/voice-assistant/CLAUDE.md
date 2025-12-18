# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Local voice assistant system built on Home Assistant with GPU-accelerated AI processing. The system has three main components:

1. **Gaming PC (RTX 5060)** - AI Hub running Docker containers for LLM, STT, TTS, and wake word detection
2. **Home Assistant Server** - Central coordinator for voice pipeline, calendar integration, tasks, and automations
3. **Surface Go** - Voice satellite (microphone/speaker interface using Wyoming Satellite)

All voice processing and AI inference happens locally on the GPU - no cloud dependencies for core functionality.

## Architecture

### Three-Tier System

```
Voice Satellite (Surface Go)
    ↓ Wyoming Protocol (TCP)
Home Assistant (Coordinator)
    ↓ Wyoming Protocol (TCP)
Gaming PC (AI Services - Docker)
    ├── Ollama (LLM) - GPU - Port 11434
    ├── Faster-Whisper (STT) - GPU - Port 10300
    ├── Piper (TTS) - Port 10200
    └── OpenWakeWord (Wake) - Port 10400
```

### Voice Pipeline Flow

1. Surface Go detects "ok nabu" wake word (via Gaming PC OpenWakeWord)
2. Audio stream sent to Gaming PC Whisper for STT
3. Text sent to Home Assistant Assist Pipeline
4. Home Assistant routes to conversation agent (built-in or Ollama LLM)
5. Response sent to Gaming PC Piper for TTS
6. Audio returned to Surface Go for playback

### Key Network Relationships

- All Wyoming services (ports 10200, 10300, 10400) must be accessible from Home Assistant
- Ollama (port 11434) must be accessible from Home Assistant for LLM conversation agent
- Surface Go Wyoming Satellite connects to Gaming PC Wyoming services AND Home Assistant API (port 8123)
- All devices must be on the same local network

## Common Commands

### Gaming PC - Docker Services

All commands run from `gaming-pc-setup/` directory:

```bash
# Start all AI services
docker-compose up -d

# Stop services
docker-compose down

# View status
docker-compose ps

# View logs (all services)
docker-compose logs -f

# View specific service logs
docker-compose logs -f ollama
docker-compose logs -f whisper
docker-compose logs -f piper

# Restart a service
docker-compose restart whisper

# Pull latest images
docker-compose pull
docker-compose up -d

# Check GPU usage
nvidia-smi
nvidia-smi -l 1  # Continuous monitoring
```

### Ollama Model Management

```bash
# List installed models
docker exec ollama ollama list

# Download/update models
docker exec ollama ollama pull llama3.1:8b
docker exec ollama ollama pull phi3:mini

# Remove a model
docker exec ollama ollama rm llama3.1:8b

# Test model directly
docker exec -it ollama ollama run llama3.1:8b "Hello"
```

### Home Assistant Configuration

Home Assistant configs are in `home-assistant-config/` but must be copied/merged to actual HA instance (`/config/`):

```bash
# Check Home Assistant configuration
# (Run from HA instance, not this repo)
ha core check

# Restart Home Assistant after config changes
# Developer Tools → YAML → Restart (in HA UI)

# View Home Assistant logs
ha core logs
```

### Surface Go - Wyoming Satellite

**Windows:**
```powershell
# Start satellite
cd $env:USERPROFILE\wyoming-satellite
.\venv\Scripts\Activate.ps1
wyoming-satellite --config config.yaml

# Or use convenience script
.\start-satellite.ps1
```

**Linux:**
```bash
# Start/stop service
systemctl --user start wyoming-satellite
systemctl --user stop wyoming-satellite

# Check status
systemctl --user status wyoming-satellite

# View logs
journalctl --user -u wyoming-satellite -f

# Manual start (for debugging)
cd ~/wyoming-satellite
source venv/bin/activate
python -m wyoming_satellite --config config.yaml
```

### Testing Components

```bash
# Test Ollama API
curl http://GAMING_PC_IP:11434/api/tags

# Test Whisper STT
curl http://GAMING_PC_IP:10300

# Test Piper TTS
curl http://GAMING_PC_IP:10200

# Test OpenWakeWord
curl http://GAMING_PC_IP:10400

# Test from Home Assistant to Gaming PC
ping GAMING_PC_IP
telnet GAMING_PC_IP 10300
```

## Configuration Architecture

### Gaming PC - docker-compose.yml

The Docker Compose file defines all AI services. Key configuration points:

- **GPU Access**: All GPU services use `deploy.resources.reservations.devices` with `nvidia` driver
- **Whisper Model**: Controlled by `--model large-v3` parameter (can change to `medium` for speed)
- **Piper Voice**: Controlled by `--voice en_US-lessac-medium` parameter
- **Ollama Models**: Downloaded separately via `ollama pull` command
- **Network Ports**: Must match Home Assistant Wyoming configuration

### Home Assistant - configuration.yaml

The HA config has several interdependent sections:

1. **Wyoming Integrations** (`wyoming:`): Connects to Gaming PC services (requires IP address)
2. **Assist Pipelines** (`assist_pipeline:`): Chains STT → Conversation → TTS together
3. **Ollama Conversation** (`conversation:`): Optional LLM integration pointing to Gaming PC Ollama
4. **Calendar Integrations** (`google:`, `caldav:`): External calendar sources
5. **Intent Scripts** (`intent_script:`): Voice command handlers
6. **Scripts** (`script:`): Reusable automation logic
7. **Automations** (`automation:`): Proactive voice announcements

**Critical**: All `GAMING_PC_IP` placeholders must be replaced with actual IP or `!secret gaming_pc_ip`

### Wyoming Satellite - config.yaml

Surface Go satellite config connects to BOTH Gaming PC (Wyoming services) AND Home Assistant (API):

```yaml
wyoming:
  stt:
    uri: "tcp://GAMING_PC_IP:10300"  # Whisper
  tts:
    uri: "tcp://GAMING_PC_IP:10200"  # Piper
  wake:
    uri: "tcp://GAMING_PC_IP:10400"  # OpenWakeWord

home_assistant:
  url: "http://HA_IP:8123"
  token: "long-lived-access-token"  # From HA Profile → Security
```

## Key Customization Points

### Switching LLM Models

In `home-assistant-config/configuration.yaml`:

```yaml
conversation:
  - platform: ollama
    model: "phi3:mini"  # Faster, 2-3 sec response
    # or
    model: "llama3.1:8b"  # Slower, 5-7 sec, better quality
```

Must have model downloaded: `docker exec ollama ollama pull phi3:mini`

### Changing Whisper Model (Speed vs Accuracy)

In `gaming-pc-setup/docker-compose.yml`:

```yaml
whisper:
  command: >
    --model medium  # Faster, still accurate
    # or
    --model large-v3  # Slower, most accurate
```

Restart required: `docker-compose restart whisper`

### Adding Custom Voice Commands

Two approaches:

1. **Intent Scripts** (simple, pattern-based) - Add to `configuration.yaml`:
   ```yaml
   intent_script:
     CustomCommand:
       speech:
         text: "Response text"
   ```

2. **Scripts with LLM** (flexible, natural language) - Add to `scripts.yaml`:
   ```yaml
   custom_script:
     sequence:
       - service: conversation.process
         data:
           agent_id: conversation.local_llm
           text: "{{ user_query }}"
   ```

### Customizing Automations

Edit `home-assistant-config/automations.yaml` for:
- Morning briefing time and content
- Event reminder timing (default: 15 min before)
- Proactive announcement conditions

All automations use TTS service to speak via Surface Go: `media_player.surface_go`

## IP Address Configuration Pattern

The system requires IP addresses in three places:

1. **Gaming PC IP** → Used in:
   - `home-assistant-config/configuration.yaml` (Wyoming integrations, Ollama URL)
   - `surface-go-setup/config.yaml` (Wyoming service URIs)
   - Should be defined in `home-assistant-config/secrets.yaml` as `gaming_pc_ip`

2. **Home Assistant IP** → Used in:
   - `surface-go-setup/config.yaml` (Home Assistant URL)
   - Google Calendar OAuth redirect URI (setup only)

3. **Surface Go IP** → Referenced for documentation only, not required in configs

**Best Practice**: Use static DHCP reservations or static IPs to prevent connection issues after router reboots.

## Secrets Management

`home-assistant-config/secrets.yaml` (not tracked in git) should contain:

```yaml
# Required
gaming_pc_ip: "192.168.1.100"

# Optional - Google Calendar
google_client_id: "..."
google_client_secret: "..."

# Optional - Apple Calendar
icloud_email: "..."
icloud_app_password: "..."

# Optional - OpenWeatherMap
openweathermap_api_key: "..."
```

Use in configs with `!secret key_name`

## Installation Script Behavior

### gaming-pc-setup/setup.ps1 (Windows) or setup.sh (Linux)

1. Installs Docker (if missing on Linux)
2. Installs NVIDIA Container Toolkit (Linux)
3. Tests GPU access in Docker
4. Starts Docker Compose services
5. Downloads Ollama models (llama3.1:8b, phi3:mini) - **This takes 10-15 minutes**
6. Displays service URLs and next steps

**Important**: Models download in foreground - script waits for completion.

### surface-go-setup/install-satellite.ps1 (Windows) or install-satellite.sh (Linux)

1. Checks Python 3.10+ installed
2. Creates virtual environment
3. Installs wyoming-satellite and pyaudio
4. Prompts for Gaming PC IP and HA IP
5. Creates config.yaml with placeholders
6. **Does NOT start satellite** - user must add HA token first, then start manually

**Post-install required**: Edit config.yaml to add Home Assistant long-lived access token.

## Troubleshooting Common Issues

### "Can't connect to Gaming PC services"

1. Check Docker containers running: `docker-compose ps` (all should be "Up")
2. Check firewall allows ports: 10200, 10300, 10400, 11434
3. Verify IP address correct in configs
4. Test connectivity: `telnet GAMING_PC_IP 10300`

### "CUDA out of memory"

1. Check GPU usage: `nvidia-smi`
2. Restart Docker containers to clear memory: `docker-compose restart`
3. Switch to smaller models (medium Whisper, phi3:mini)
4. Reduce `--max-piper-procs` in docker-compose.yml

### "Wake word not detected"

1. Check microphone working (test with system recorder)
2. Check OpenWakeWord container running: `docker logs openwakeword`
3. Verify config.yaml points to correct Gaming PC IP:10400
4. Check microphone permissions (Windows: Settings → Privacy → Microphone)

### "LLM responses timing out"

1. Test Ollama directly: `docker exec ollama ollama list`
2. Switch to faster model: `phi3:mini` instead of `llama3.1:8b`
3. Increase timeout in HA config: `timeout: 30`
4. Check GPU not saturated: `nvidia-smi`

## Development Workflow

### Testing Configuration Changes

1. **Gaming PC changes** (docker-compose.yml):
   ```bash
   docker-compose down
   docker-compose up -d
   docker-compose logs -f  # Watch for errors
   ```

2. **Home Assistant changes** (configuration.yaml, automations.yaml, scripts.yaml):
   - Developer Tools → YAML → Check Configuration
   - If valid: Developer Tools → Restart
   - If invalid: Fix errors, repeat

3. **Surface Go satellite changes** (config.yaml):
   - Stop satellite (Ctrl+C or `systemctl --user stop`)
   - Edit config.yaml
   - Restart: `./start-satellite.ps1` or `systemctl --user start`

### Adding New LLM Models

```bash
# Download model
docker exec ollama ollama pull mistral:latest

# Test it
docker exec -it ollama ollama run mistral:latest "test"

# Update HA configuration.yaml
conversation:
  - platform: ollama
    model: "mistral:latest"

# Restart HA
```

### Voice Command Testing Without Hardware

1. Open Home Assistant UI
2. Developer Tools → Assist
3. Type command (bypasses STT/wake word)
4. See response in UI (bypasses TTS)
5. Debug conversation flow without voice satellite

## File Modification Guidelines

### Never Modify
- Model data in Docker volumes
- Home Assistant database files
- Downloaded Ollama models (manage via `ollama` commands)

### Merge, Don't Replace
- `home-assistant-config/configuration.yaml` - User may have existing config
- Templates should be merged into existing HA instance

### User Must Configure
- `secrets.yaml` - Never commit secrets
- IP addresses - Network-specific
- Calendar credentials - User-specific
- HA access tokens - Security-sensitive

## Performance Characteristics

### Response Times (typical)

- Wake word detection: <500ms
- STT (Whisper large-v3): 1-2 seconds
- LLM (llama3.1:8b): 5-7 seconds
- LLM (phi3:mini): 2-3 seconds
- TTS (Piper): <1 second
- **Total end-to-end with LLM**: 8-11 seconds (llama) or 4-6 seconds (phi3)

### Resource Usage

- GPU VRAM: ~6-7GB with all services active (Whisper large-v3 + Llama 3.1)
- RAM: ~4-6GB for all Docker containers
- Disk: ~15GB for models (grows with more Ollama models)
- Network: Minimal latency on local network (<10ms)

### Optimization Trade-offs

- **Accuracy vs Speed**: `large-v3` Whisper vs `medium`, `llama3.1` vs `phi3:mini`
- **GPU Memory vs Capability**: Larger models need more VRAM
- **Response Time vs Quality**: Phi-3 Mini fast but less capable than Llama 3.1

## Documentation Structure

- `README.md` - High-level overview and architecture
- `QUICK_START.md` - 30-minute setup walkthrough
- `docs/INSTALLATION.md` - Comprehensive installation with all details
- `docs/COMMANDS.md` - Voice command reference and customization
- `docs/CALENDAR_SETUP.md` - Google/Apple calendar OAuth setup
- `docs/TROUBLESHOOTING.md` - Problem-solving guide

When helping users, direct them to appropriate doc based on their need.
