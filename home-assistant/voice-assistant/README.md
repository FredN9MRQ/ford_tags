# Local Voice Assistant with Home Assistant

A privacy-focused, local-first voice assistant powered by Home Assistant, leveraging your RTX 5060 GPU for AI processing.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GAMING PC (RTX 5060)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   Ollama     │  │   Whisper    │  │   Piper TTS     │  │
│  │  (LLM GPU)   │  │  (STT GPU)   │  │   (Local TTS)   │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
│         ▲                  ▲                   ▲            │
│         └──────────────────┴───────────────────┘            │
│                    Wyoming Protocol                         │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Network
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    HOME ASSISTANT SERVER                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Assist Pipeline │ Calendars │ Weather │ Tasks │ etc   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Network
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 SURFACE GO (Voice Satellite)                │
│         Microphone → Wyoming Satellite → Speaker            │
└─────────────────────────────────────────────────────────────┘
```

## Features

- **100% Local Processing** - All AI runs on your hardware
- **GPU-Accelerated** - Fast STT and LLM inference using RTX 5060
- **Multi-Calendar Support** - Google Calendar + Apple Calendar
- **Weather Integration** - Local weather data
- **Task Management** - Project and todo tracking
- **Conversational AI** - Natural language understanding via local LLM
- **Voice Everywhere** - Surface Go as primary, expandable to Raspberry Pi satellites

## Hardware Requirements

### Gaming PC
- RTX 5060 8GB (or similar NVIDIA GPU)
- Docker + Docker Compose
- NVIDIA Container Toolkit
- 16GB+ RAM recommended
- Windows/Linux

### Surface Go
- Windows 10/11 or Linux
- Microphone and speakers
- Network connection to Gaming PC

### Home Assistant
- Existing Home Assistant installation
- Version 2023.11+ (for native todo lists)

## Quick Start

### 1. Gaming PC Setup (AI Hub)
```bash
cd gaming-pc-setup
./setup.sh
```

### 2. Home Assistant Configuration
Copy configurations from `home-assistant-config/` to your HA instance.

### 3. Surface Go Setup (Voice Satellite)
```bash
cd surface-go-setup
./install-satellite.sh
```

## Directory Structure

```
voice-assistant-project/
├── README.md (this file)
├── gaming-pc-setup/          # Docker & AI services for GPU server
│   ├── docker-compose.yml
│   ├── setup.sh
│   └── config/
├── home-assistant-config/     # HA configurations
│   ├── configuration.yaml
│   ├── secrets.yaml.example
│   ├── automations.yaml
│   └── scripts/
├── surface-go-setup/          # Voice satellite setup
│   ├── install-satellite.sh
│   └── config.yaml
└── docs/                      # Documentation
    ├── INSTALLATION.md
    ├── COMMANDS.md
    └── TROUBLESHOOTING.md
```

## Current Status

This project is under active development. Check `docs/INSTALLATION.md` for detailed setup instructions.

## Privacy & Security

- All voice processing happens locally
- No cloud API calls for core functionality
- Calendar data stays on your network
- Optional: Cloud weather service (can be replaced with local station)

## Credits

Inspired by NetworkChuck's Home Assistant voice assistant tutorial, enhanced with local LLM integration and multi-device support.
