# Quick Start Guide

Get your local voice assistant running in 30 minutes!

## What You're Building

A completely local, privacy-focused voice assistant that:
- Runs AI models on your RTX 5060 GPU
- Manages your Google & Apple calendars
- Provides weather updates
- Tracks tasks and projects
- Uses your Surface Go as a voice interface
- **All processing happens locally - no cloud required!**

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Gaming PC with RTX 5060 (8GB)
- [ ] Docker Desktop installed (Windows) or Docker (Linux)
- [ ] Home Assistant running (v2023.11+)
- [ ] Surface Go with Python 3.10+
- [ ] All devices on same network
- [ ] ~20GB free disk space on Gaming PC

## 30-Minute Setup

### Step 1: Gaming PC (10 minutes + model download time)

**Windows:**
```powershell
cd C:\Users\fredb\voice-assistant-project\gaming-pc-setup
.\setup.ps1
```

**Linux:**
```bash
cd ~/voice-assistant-project/gaming-pc-setup
chmod +x setup.sh
./setup.sh
```

**Wait for models to download** (~10-15 minutes):
- Llama 3.1 8B: 4.7GB
- Phi-3 Mini: 2.3GB
- Whisper: 3GB

☕ **Take a break while models download**

**Save your Gaming PC IP address** (you'll need it):
- Windows: `ipconfig` → Look for IPv4 Address
- Linux: `ip addr show` → Look for inet address

### Step 2: Home Assistant (10 minutes)

1. **Copy configuration files to Home Assistant**

   Using File Editor or SSH, add to `/config/`:
   - Merge `home-assistant-config/configuration.yaml` content
   - Copy `home-assistant-config/automations.yaml`
   - Copy `home-assistant-config/scripts.yaml`

2. **Create secrets file**

   Edit `/config/secrets.yaml`:
   ```yaml
   gaming_pc_ip: "192.168.1.100"  # YOUR Gaming PC IP
   ```

3. **Update configuration**

   In `configuration.yaml`, replace all `GAMING_PC_IP` with:
   ```yaml
   !secret gaming_pc_ip
   ```

4. **Check and restart**
   - Developer Tools → YAML → Check Configuration
   - Developer Tools → Restart

5. **Configure voice assistant**
   - Settings → Voice Assistants → Add Assistant
   - Name: "Local Voice Assistant"
   - Speech-to-text: Faster Whisper
   - Text-to-speech: Piper
   - Conversation: Home Assistant
   - Wake word: ok_nabu
   - Save and set as preferred

### Step 3: Surface Go (10 minutes)

**Windows:**
```powershell
cd C:\Users\fredb\voice-assistant-project\surface-go-setup
.\install-satellite.ps1
```

When prompted, enter:
- Gaming PC IP: (from Step 1)
- Home Assistant IP: (your HA address)

**Get Home Assistant Token:**
1. Open Home Assistant
2. Profile → Security → Long-Lived Access Tokens
3. Create Token → Copy it

**Add token to config:**
```powershell
notepad $env:USERPROFILE\wyoming-satellite\config.yaml
```
Paste token in the `token: ""` field

**Start the satellite:**
```powershell
cd $env:USERPROFILE\wyoming-satellite
.\start-satellite.ps1
```

**Linux:**
```bash
cd ~/voice-assistant-project/surface-go-setup
chmod +x install-satellite.sh
./install-satellite.sh

# Add HA token to config
nano ~/wyoming-satellite/config.yaml

# Start service
systemctl --user start wyoming-satellite
```

## First Test! 🎉

On your Surface Go, say:

1. **"ok nabu"** (wait for beep)
2. **"What time is it?"**

You should hear a response!

## Additional Tests

Try these commands:

- "ok nabu" → "What's the weather?"
- "ok nabu" → "What's on my calendar?"
- "ok nabu" → "How many tasks do I have?"

## Optional: Add Calendars (15 minutes)

### Google Calendar

1. **Google Cloud Console**: https://console.cloud.google.com/
   - Create project → Enable Calendar API
   - OAuth consent screen → Add your email as test user
   - Create OAuth credentials (Web application)
   - Add redirect: `http://YOUR_HA_IP:8123/auth/external/callback`

2. **Add to secrets.yaml**:
   ```yaml
   google_client_id: "your-client-id"
   google_client_secret: "your-client-secret"
   ```

3. **In Home Assistant**:
   - Settings → Devices & Services → Add Integration
   - Search "Google Calendar" → Sign in → Authorize

### Apple Calendar

1. **Generate app-specific password**: https://appleid.apple.com/
   - Security → Generate Password → Copy it

2. **Add to secrets.yaml**:
   ```yaml
   icloud_email: "your@icloud.com"
   icloud_app_password: "xxxx-xxxx-xxxx-xxxx"
   ```

3. **Restart Home Assistant**

See [CALENDAR_SETUP.md](docs/CALENDAR_SETUP.md) for detailed instructions.

## What's Next?

### Start Using It!

Your assistant can now:
- ✅ Answer voice commands
- ✅ Tell time and weather
- ✅ Manage calendars (if configured)
- ✅ Track tasks
- ✅ Have natural conversations (using local LLM)

### Customize

**Add more voice commands**: See [COMMANDS.md](docs/COMMANDS.md)

**Customize automations**: Edit `home-assistant-config/automations.yaml`

**Add more satellites**: Install on Raspberry Pi devices

**Switch models**: Use `phi3:mini` for faster responses

### Useful Commands

**Gaming PC - Check status:**
```bash
cd gaming-pc-setup
docker-compose ps
```

**Gaming PC - View logs:**
```bash
docker-compose logs -f
```

**Gaming PC - Restart services:**
```bash
docker-compose restart
```

**Test Ollama web interface:**
- Open browser: `http://GAMING_PC_IP:8080`

**Surface Go - Stop satellite (Windows):**
- Ctrl+C in PowerShell window

**Surface Go - Check status (Linux):**
```bash
systemctl --user status wyoming-satellite
```

## Troubleshooting

### Voice commands not working?

1. **Check all services running:**
   ```bash
   # Gaming PC
   docker-compose ps
   ```

2. **Test in Home Assistant UI:**
   - Developer Tools → Assist
   - Type command (no voice needed)

3. **Check microphone:**
   - Test with system recorder
   - Check permissions

4. **View logs:**
   ```bash
   # Gaming PC
   docker-compose logs whisper
   docker-compose logs piper
   ```

### Can't connect to Gaming PC?

1. **Verify IP address:**
   ```bash
   ping GAMING_PC_IP
   ```

2. **Check firewall:**
   - Ports 10200, 10300, 10400, 11434 must be open

3. **Test ports:**
   ```bash
   # Windows
   Test-NetConnection -ComputerName GAMING_PC_IP -Port 10300

   # Linux
   nc -zv GAMING_PC_IP 10300
   ```

### Models not downloading?

- Check internet connection
- Check disk space: need 20GB+
- View download progress: `docker-compose logs -f ollama`

### More issues?

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed solutions.

## Architecture Diagram

```
┌─────────────────────────────────────┐
│      Surface Go (Voice)             │
│   "ok nabu, what's the weather?"    │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│    Home Assistant (Coordinator)     │
│   - Processes commands              │
│   - Manages calendar/tasks          │
│   - Triggers automations            │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│  Gaming PC - RTX 5060 (AI Hub)      │
│                                     │
│  ┌──────────┐  ┌─────────────┐    │
│  │ Whisper  │  │   Ollama    │    │
│  │  (STT)   │  │   (LLM)     │    │
│  │  GPU     │  │   GPU       │    │
│  └──────────┘  └─────────────┘    │
│                                     │
│  ┌──────────┐  ┌─────────────┐    │
│  │  Piper   │  │ OpenWake    │    │
│  │  (TTS)   │  │   Word      │    │
│  └──────────┘  └─────────────┘    │
└─────────────────────────────────────┘
```

## Project Structure

```
voice-assistant-project/
├── README.md                    # Project overview
├── QUICK_START.md              # This file
├── gaming-pc-setup/            # GPU server setup
│   ├── docker-compose.yml      # Services definition
│   ├── setup.ps1               # Windows setup
│   └── setup.sh                # Linux setup
├── home-assistant-config/      # HA configuration
│   ├── configuration.yaml      # Main config
│   ├── automations.yaml        # Voice automations
│   ├── scripts.yaml            # Custom scripts
│   └── secrets.yaml.example    # Secrets template
├── surface-go-setup/           # Voice satellite
│   ├── install-satellite.ps1   # Windows installer
│   └── install-satellite.sh    # Linux installer
└── docs/                       # Documentation
    ├── INSTALLATION.md         # Detailed setup
    ├── COMMANDS.md             # Voice commands
    ├── CALENDAR_SETUP.md       # Calendar integration
    └── TROUBLESHOOTING.md      # Problem solving
```

## Performance Tips

### For Faster Responses

1. **Use Phi-3 Mini** (instead of Llama 3.1):
   ```yaml
   # In Home Assistant configuration.yaml
   conversation:
     - platform: ollama
       model: "phi3:mini"  # Much faster!
   ```

2. **Use Medium Whisper model**:
   ```yaml
   # In docker-compose.yml
   command: >
     --model medium  # Instead of large-v3
   ```

3. **Reduce LLM response length**:
   ```yaml
   conversation:
     - platform: ollama
       max_tokens: 200  # Instead of 500
   ```

### Monitor Performance

```bash
# Watch GPU usage
nvidia-smi -l 1

# Check response times in HA logs
# Settings → System → Logs → Filter: "assist"
```

## Security & Privacy

✅ **All AI processing is local** - No data sent to cloud
✅ **Calendar data stays on your network**
✅ **Voice never leaves your network**
✅ **LLM runs on your hardware**

Optional cloud services (can be replaced):
- Weather (can use local weather station)
- Calendar sync (can use local CalDAV)

## Resources

- **Full Documentation**: See `docs/` folder
- **Home Assistant Voice**: https://www.home-assistant.io/voice_control/
- **Ollama Models**: https://ollama.ai/library
- **Wyoming Protocol**: https://github.com/rhasspy/wyoming

## Need Help?

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review logs (Gaming PC, HA, Surface Go)
3. Test components individually
4. Ask on Home Assistant Community forums

## Success! 🎉

You now have a fully local, GPU-powered voice assistant that:
- Respects your privacy
- Runs fast on your hardware
- Understands natural language
- Manages your life

Enjoy your new AI assistant!

---

**Next Steps:**
- Explore [COMMANDS.md](docs/COMMANDS.md) for more voice commands
- Set up calendars with [CALENDAR_SETUP.md](docs/CALENDAR_SETUP.md)
- Add custom automations
- Set up additional voice satellites
- Train custom wake words
