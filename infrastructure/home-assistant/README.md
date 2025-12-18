# Home Infrastructure

Comprehensive documentation and configuration management for home network infrastructure, Home Assistant, and smart home automation.

## Repository Structure

```
infrastructure/
├── home-assistant/          # Home Assistant configuration files
│   ├── configuration.yaml
│   ├── automations.yaml
│   ├── scripts.yaml
│   ├── switches.yaml
│   └── secrets.yaml (gitignored)
│
├── esphome/                 # ESPHome device configurations
│   ├── garage-controller.yaml
│   └── README.md
│
├── voice-assistant/         # Local voice assistant system
│   ├── gaming-pc-setup/          # Docker services (GPU-accelerated AI)
│   ├── surface-go-setup/         # Wyoming satellite installation
│   ├── home-assistant-config/    # Voice pipeline HA config (merge with main)
│   ├── docs/                     # Voice system documentation
│   ├── README.md                 # Voice system overview
│   └── QUICK_START.md           # 30-minute voice setup guide
│
├── docs/                    # Infrastructure documentation
│   ├── FURNACE-PROJECT.md            # Furnace control integration project
│   ├── HOME-ASSISTANT-CONFIG-MERGE.md # Guide to merge voice HA config
│   ├── MQTT-SETUP.md                 # MQTT broker configuration
│   ├── DNS-OVER-TLS-SETUP.md         # DNS security setup
│   ├── MONITORING.md                 # System monitoring setup
│   ├── SERVICES.md                   # Services inventory
│   ├── DISASTER-RECOVERY.md          # Backup and recovery procedures
│   ├── RUNBOOK.md                    # Operational procedures
│   └── IMPROVEMENTS.md               # Future improvements tracking
│
├── scripts/                 # Automation and utility scripts
│
└── claude-shared/          # Shared resources with Claude Code assistant
```

## Quick Start

### Home Assistant
Configuration files are in `/home-assistant/`.

**Key Files:**
- `configuration.yaml` - Main HA configuration
- `automations.yaml` - All automations
- `scripts.yaml` - Reusable scripts
- `secrets.yaml` - Sensitive data (create from secrets.yaml.example)

**Deployment:**
Copy files to your Home Assistant config directory (typically `/config/` in HA OS).

### ESPHome Devices
Device configurations are in `/esphome/`.

**Current Devices:**
- **garage-controller** - ESP32 with 8-relay board controlling garage doors, lights, and planned furnace integration

**Deployment:**
```bash
cd esphome
esphome run garage-controller.yaml
```

Or use Home Assistant ESPHome integration for OTA updates.

### Voice Assistant

**Local GPU-accelerated voice assistant system** with Home Assistant integration.

**System Components:**
- **Gaming PC (RTX 5060):** Docker containers for Ollama LLM, Whisper STT, Piper TTS, OpenWakeWord
- **Home Assistant:** Voice pipeline coordinator
- **Surface Go:** Wyoming satellite (microphone/speaker interface)

**Quick Start:**
1. Set up Gaming PC AI services: `/voice-assistant/gaming-pc-setup/`
2. Set up Surface Go satellite: `/voice-assistant/surface-go-setup/`
3. Merge voice HA config: See `/docs/HOME-ASSISTANT-CONFIG-MERGE.md`
4. Full documentation: `/voice-assistant/README.md`

**Current Status:** Operational - needs HA config merge for full integration

## Active Projects

### 🔥 Furnace Control Integration
- **Status:** Planning phase
- **Goal:** Replace failed furnace board with ESP32-based smart control
- **Documentation:** [docs/FURNACE-PROJECT.md](docs/FURNACE-PROJECT.md)
- **Hardware:** ESP32-WROOM-32E with relay board, 6x temp/humidity sensors
- **Features:** Multi-zone monitoring (garage + shed), HA integration, safety interlocks

### 🎤 Local Voice Assistant
- **Status:** Operational, pending HA config merge
- **Goal:** GPU-accelerated local voice control with LLM
- **Documentation:** [voice-assistant/README.md](voice-assistant/README.md)
- **Hardware:** Gaming PC (RTX 5060), Surface Go (Wyoming satellite)
- **Features:** Ollama LLM, Whisper STT, Piper TTS, OpenWakeWord, no cloud dependencies
- **Integration:** See [docs/HOME-ASSISTANT-CONFIG-MERGE.md](docs/HOME-ASSISTANT-CONFIG-MERGE.md)

### 🌐 Network Infrastructure
- **MQTT:** Mosquitto broker for device communication
- **DNS:** DNS-over-TLS with Unbound
- **Documentation:** See docs/MQTT-SETUP.md and docs/DNS-OVER-TLS-SETUP.md

## Documentation

All infrastructure documentation is in the `/docs/` directory:

- **[FURNACE-PROJECT.md](docs/FURNACE-PROJECT.md)** - ESP32 furnace control integration
- **[HOME-ASSISTANT-CONFIG-MERGE.md](docs/HOME-ASSISTANT-CONFIG-MERGE.md)** - Merge voice assistant HA config
- **[MQTT-SETUP.md](docs/MQTT-SETUP.md)** - MQTT broker setup and configuration
- **[DNS-OVER-TLS-SETUP.md](docs/DNS-OVER-TLS-SETUP.md)** - Secure DNS configuration
- **[MONITORING.md](docs/MONITORING.md)** - System monitoring and alerting
- **[SERVICES.md](docs/SERVICES.md)** - Inventory of all services
- **[DISASTER-RECOVERY.md](docs/DISASTER-RECOVERY.md)** - Backup and recovery procedures
- **[RUNBOOK.md](docs/RUNBOOK.md)** - Operational procedures and troubleshooting

**Voice assistant documentation** is in `/voice-assistant/docs/`:
- Installation, commands, calendar setup, troubleshooting

## Network Information

Current network setup and IP allocations are documented in:
- [IP-ALLOCATION.md](IP-ALLOCATION.md) - IP address assignments
- DHCP exports in repository root

## Contributing

This is a personal infrastructure repository. Updates are made through:
1. Local testing and validation
2. Git commits with descriptive messages
3. Push to GitHub for backup and history

## Secrets Management

Sensitive information (passwords, API keys, etc.) is stored in `secrets.yaml` files which are gitignored.

**Template files:**
- `/home-assistant/secrets.yaml.example`
- Create your own `secrets.yaml` from the template

## Backup Strategy

See [DISASTER-RECOVERY.md](docs/DISASTER-RECOVERY.md) for:
- Backup procedures
- Recovery steps
- Critical system information

## Support & Notes

- **Experience Level:** 20+ years low voltage wiring, network infrastructure
- **Tools:** Home Assistant, ESPHome, MQTT, Unbound DNS
- **Approach:** Document everything, safety-first, incremental improvements

## Recent Updates

- **2025-11-28:**
  - Consolidated all smart home projects into monorepo
  - Added ESPHome directory and furnace control project documentation
  - Integrated voice assistant project (Gaming PC AI + Surface Go)
  - Created Home Assistant config merge guide
- **2025-11-27:** Home Assistant configuration updates
- **2025-11-18:** MQTT and DNS-over-TLS setup documentation

---

*Maintained by: Fred N9MRQ*
*Repository: https://github.com/FredN9MRQ/infrastructure*
