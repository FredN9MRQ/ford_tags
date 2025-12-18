# Home Assistant Configuration

**Server IP**: 10.0.10.24
**Web Interface**: http://10.0.10.24:8123
**Installation Type**: Home Assistant OS
**Configuration Editor**: Studio Code Server add-on

---

## Configuration Files

| File | Purpose |
|------|---------|
| `configuration.yaml` | Main configuration file with includes |
| `automations.yaml` | Automations (managed via UI) |
| `scripts.yaml` | Scripts (managed via UI) |
| `scenes.yaml` | Scenes (managed via UI) |
| `switches.yaml` | Custom RESTful and template switches |
| `secrets.yaml.example` | Template for secrets (DO NOT commit actual secrets.yaml) |

---

## Current Integrations

### Smart Devices
- **Govee Curtain Lights** - Official Govee LAN integration (local control)
- **Sylvania Smart+ WiFi Plug** - LocalTuya (local control) for Christmas lights
- **Digital Loggers Web Power Switch** - RESTful switches (8 outlets) at 10.0.10.88

### Voice Assistant
- Wyoming Protocol integrations
- Gaming PC (10.0.10.92) provides: Whisper STT, Piper TTS, OpenWakeWord

### Other Integrations
- Weather (Met.no)
- Local Todo lists
- ESPHome (10.0.10.28)

---

## Deployment Workflow

1. **Edit locally**: Make changes to config files in this directory
2. **Commit to git**: `git add . && git commit -m "Update HA config"`
3. **Deploy to server**: Run `../scripts/sync-ha-config.sh` (or manual SCP)
4. **Check config**: In HA: Developer Tools → YAML → Check Configuration
5. **Reload/Restart**: Reload specific sections or restart HA as needed

---

## Manual Deployment (if sync script not working)

### Via SCP:
```bash
scp -r * root@10.0.10.24:/config/
```

### Via Samba:
1. Mount: `\\10.0.10.24\config`
2. Copy files to mounted drive

---

## Important Notes

- **NEVER commit `secrets.yaml`** - it contains credentials
- Use `secrets.yaml.example` as a template
- Always check configuration before restarting HA
- Keep this README updated as integrations change
