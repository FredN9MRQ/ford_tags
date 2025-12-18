# Home Assistant Configuration Merge Guide

## Overview

After consolidating projects, you now have TWO Home Assistant configuration directories:

1. **`/home-assistant/`** - Main smart home config (automations, switches, Digital Loggers integration)
2. **`/voice-assistant/home-assistant-config/`** - Voice pipeline config (Wyoming, Ollama, calendar integration)

## Decision: Merge or Keep Separate?

### Option A: Single Home Assistant Instance (RECOMMENDED)

**If you're running ONE Home Assistant server**, you need to merge these configs.

**Advantages:**
- Voice commands can control garage doors, lights, furnace
- One place to manage all automations
- Calendar integration works with smart home automations
- Ollama LLM can control all devices

**How to merge:**
1. Use `/home-assistant/` as your base (it's already working)
2. Copy sections from `/voice-assistant/home-assistant-config/` into it
3. Follow the merge checklist below

---

### Option B: Two Separate Home Assistant Instances

**If you're running TWO different HA servers** (unlikely but possible):
- One for smart home (garage, furnace, lights)
- One for voice assistant experiments

Keep the configs separate and deploy to different servers.

---

## Merge Checklist (Option A)

### 1. Wyoming Voice Services

**From:** `/voice-assistant/home-assistant-config/configuration.yaml`

**Add to:** `/home-assistant/configuration.yaml`

```yaml
# Wyoming Protocol Services (Voice Pipeline)
wyoming:
  stt:
    - platform: wyoming
      name: "Whisper STT"
      host: !secret gaming_pc_ip
      port: 10300

  tts:
    - platform: wyoming
      name: "Piper TTS"
      host: !secret gaming_pc_ip
      port: 10200

  wake:
    - platform: wyoming
      name: "OpenWakeWord"
      host: !secret gaming_pc_ip
      port: 10400
```

**Also add to `/home-assistant/secrets.yaml`:**
```yaml
gaming_pc_ip: "192.168.1.XXX"  # Your Gaming PC IP
```

---

### 2. Ollama Conversation Agent

**From:** `/voice-assistant/home-assistant-config/configuration.yaml`

**Add to:** `/home-assistant/configuration.yaml`

```yaml
# Ollama LLM Integration
conversation:
  - platform: ollama
    name: "Local LLM"
    url: "http://!secret gaming_pc_ip:11434"
    model: "phi3:mini"  # Or llama3.1:8b
    timeout: 30
    prompt: |
      You are a helpful voice assistant for a smart home.
      You can control garage doors, lights, and furnace.
      Be concise and friendly.
```

---

### 3. Assist Pipeline

**From:** `/voice-assistant/home-assistant-config/configuration.yaml`

**Add to:** `/home-assistant/configuration.yaml`

```yaml
# Voice Assistant Pipeline
assist_pipeline:
  - name: "Local Voice Pipeline"
    language: "en"
    stt_engine: "wyoming.whisper_stt"
    conversation_engine: "conversation.local_llm"
    tts_engine: "wyoming.piper_tts"
```

---

### 4. Calendar Integrations (Optional)

**From:** `/voice-assistant/home-assistant-config/configuration.yaml`

Only add if you want voice assistant to read calendar events:

```yaml
# Google Calendar
google:
  client_id: !secret google_client_id
  client_secret: !secret google_client_secret

# Or Apple iCloud Calendar
caldav:
  - url: "https://caldav.icloud.com"
    username: !secret icloud_email
    password: !secret icloud_app_password
    calendars:
      - "Home"
      - "Work"
```

**Add to secrets.yaml** if using.

---

### 5. Voice Automations

**From:** `/voice-assistant/home-assistant-config/automations.yaml`

**Merge into:** `/home-assistant/automations.yaml`

Example automations to add:
- Morning briefing with weather
- Calendar event reminders
- Proactive announcements

**Customize** to use your actual `media_player` entity (Surface Go).

---

### 6. Voice Intent Scripts

**From:** `/voice-assistant/home-assistant-config/scripts.yaml`

**Merge into:** `/home-assistant/scripts.yaml`

Add voice command handlers for:
- "What's on my calendar?"
- "What's the weather?"
- Custom smart home voice commands

---

## Step-by-Step Merge Process

### 1. Backup Current Config
```bash
cd C:\Users\Fred\AI\claude\infrastructure\home-assistant
cp configuration.yaml configuration.yaml.backup
cp automations.yaml automations.yaml.backup
cp scripts.yaml scripts.yaml.backup
```

### 2. Add Wyoming Services
Edit `configuration.yaml`, add Wyoming section from checklist above.

### 3. Add Ollama (Optional)
If you want LLM voice control, add conversation section.

### 4. Add Assist Pipeline
Add assist_pipeline section to tie STT → Conversation → TTS together.

### 5. Update Secrets
Add `gaming_pc_ip` to `secrets.yaml`.

### 6. Merge Automations/Scripts
Carefully copy relevant automations and scripts.

### 7. Validate Configuration
```bash
# In Home Assistant UI:
Developer Tools → YAML → Check Configuration
```

### 8. Restart Home Assistant
```bash
Developer Tools → YAML → Restart
```

### 9. Test Voice Pipeline
- Say "OK Nabu" (or your wake word)
- Test a command: "Turn on workbench lights"
- Verify it works end-to-end

---

## What NOT to Merge

**Keep these separate/don't duplicate:**
- `api:` - Only one instance needed
- `logger:` - Main config is fine
- `ota:` - Not relevant for HA (ESPHome only)
- Entity IDs that don't exist in your setup

---

## Reference Documentation

After merging, keep these for reference:
- `/voice-assistant/README.md` - Voice system architecture
- `/voice-assistant/QUICK_START.md` - Voice setup guide
- `/voice-assistant/docs/` - Detailed voice assistant docs

**Original voice config:** `/voice-assistant/home-assistant-config/` (keep as template)

---

## Testing the Merged Config

### 1. Test Wyoming Services
```bash
# From HA terminal or SSH:
nc -zv GAMING_PC_IP 10300  # Whisper
nc -zv GAMING_PC_IP 10200  # Piper
nc -zv GAMING_PC_IP 10400  # OpenWakeWord
```

### 2. Test Ollama
Settings → Integrations → Look for "Ollama" or check conversation agents

### 3. Test Assist Pipeline
Developer Tools → Assist → Type a command

### 4. Test Voice End-to-End
Surface Go → Say wake word → Give command → Listen for response

---

## Troubleshooting

### "Wyoming integrations not found"
- Check Gaming PC Docker containers running: `docker-compose ps`
- Verify Gaming PC IP in secrets.yaml
- Check firewall allows ports 10200, 10300, 10400

### "Conversation agent not responding"
- Check Ollama container: `docker logs ollama`
- Test Ollama API: `curl http://GAMING_PC_IP:11434/api/tags`
- Verify model downloaded: `docker exec ollama ollama list`

### "Configuration invalid"
- Check YAML indentation (use spaces, not tabs)
- Verify all `!secret` values exist in secrets.yaml
- Look at specific error message in HA UI

---

## Next Steps After Merge

1. **Test basic voice commands** with existing devices (garage doors, lights)
2. **Add furnace control** voice commands when ESP32 furnace integration ready
3. **Customize automations** for your daily routine
4. **Add more voice intents** for specific tasks

---

*Created: 2025-11-28*
*Part of infrastructure consolidation project*
