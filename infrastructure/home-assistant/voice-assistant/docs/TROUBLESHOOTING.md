# Troubleshooting Guide

Solutions to common issues with your local voice assistant.

## Quick Diagnostic

Run through this checklist first:

```bash
# Gaming PC - Check Docker containers
docker-compose ps

# All should show "Up":
# - ollama
# - whisper
# - piper
# - openwakeword
# - ollama-webui

# Check GPU access
nvidia-smi

# Home Assistant - Check integrations
# Settings → Devices & Services
# Should see: Wyoming Protocol integrations

# Surface Go - Check satellite
# Windows:
Get-Process python

# Linux:
systemctl --user status wyoming-satellite
```

## Gaming PC Issues

### Docker Containers Not Starting

**Symptom**: `docker-compose ps` shows containers as "Exit" or "Restarting"

**Solutions**:

1. **Check Logs**:
   ```bash
   docker-compose logs ollama
   docker-compose logs whisper
   ```

2. **GPU Not Accessible**:
   ```bash
   # Test GPU
   docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
   ```

   If fails:
   - **Windows**: Ensure WSL2 NVIDIA drivers installed
   - **Linux**: Install nvidia-container-toolkit:
     ```bash
     sudo apt-get install -y nvidia-container-toolkit
     sudo systemctl restart docker
     ```

3. **Port Conflicts**:
   ```bash
   # Check if ports are in use
   # Windows:
   netstat -ano | findstr "11434"
   netstat -ano | findstr "10300"

   # Linux:
   sudo netstat -tulpn | grep 11434
   sudo netstat -tulpn | grep 10300
   ```

   If port in use, edit `docker-compose.yml` to use different ports.

4. **Insufficient Resources**:
   - Check available disk space: Need 20GB+
   - Check RAM: Need 16GB+ total
   - Close other applications using GPU

### Ollama Not Responding

**Symptom**: Ollama container running but no response

**Solutions**:

1. **Check Ollama Status**:
   ```bash
   docker exec ollama ollama list
   ```

2. **Verify Models Downloaded**:
   ```bash
   docker exec ollama ollama list
   # Should show: llama3.1:8b and phi3:mini
   ```

   If missing:
   ```bash
   docker exec ollama ollama pull llama3.1:8b
   ```

3. **Test Ollama Directly**:
   ```bash
   curl http://localhost:11434/api/generate -d '{
     "model": "llama3.1:8b",
     "prompt": "Hello"
   }'
   ```

4. **VRAM Issues**:
   ```bash
   # Check GPU memory
   nvidia-smi
   ```

   If out of memory:
   - Use smaller model: `phi3:mini`
   - Close other GPU applications
   - Restart Docker containers

### Whisper STT Not Working

**Symptom**: No speech recognition

**Solutions**:

1. **Check Whisper Logs**:
   ```bash
   docker logs whisper
   ```

2. **Test Whisper Service**:
   ```bash
   # Should respond with service info
   curl http://localhost:10300
   ```

3. **Model Download Issue**:
   ```bash
   docker exec whisper ls /data/models
   ```

   If empty, whisper will download on first use. Check logs:
   ```bash
   docker logs -f whisper
   ```

4. **GPU Memory**:
   - Whisper Large v3 needs ~3GB VRAM
   - Switch to medium model if needed:
     ```yaml
     # In docker-compose.yml
     command: >
       --model medium  # Instead of large-v3
     ```

### Piper TTS Not Working

**Symptom**: No audio output

**Solutions**:

1. **Check Piper Logs**:
   ```bash
   docker logs piper
   ```

2. **Test Piper**:
   ```bash
   curl http://localhost:10200
   ```

3. **Voice Model Missing**:
   ```bash
   docker exec piper ls /data
   ```

   Piper downloads voices on demand. Check logs for download progress.

## Home Assistant Issues

### Wyoming Integrations Not Showing

**Symptom**: No Wyoming devices in Settings → Devices & Services

**Solutions**:

1. **Check Network Connectivity**:
   ```bash
   # From Home Assistant host
   telnet GAMING_PC_IP 10300
   telnet GAMING_PC_IP 10200
   ```

2. **Verify Configuration**:
   ```yaml
   # In configuration.yaml
   wyoming:
     - host: GAMING_PC_IP  # Not "localhost"
       port: 10300
   ```

3. **Check Firewall**:
   - Gaming PC firewall must allow ports: 10200, 10300, 10400, 11434
   - **Windows**:
     ```powershell
     New-NetFirewallRule -DisplayName "Voice Assistant" -Direction Inbound -Port 10200,10300,10400,11434 -Protocol TCP -Action Allow
     ```

4. **Restart Home Assistant**:
   - Developer Tools → YAML → Restart

5. **Check HA Logs**:
   - Settings → System → Logs
   - Search for "wyoming"

### Assist Pipeline Not Working

**Symptom**: Voice commands not processed

**Solutions**:

1. **Verify Pipeline Configuration**:
   - Settings → Voice Assistants
   - Check pipeline has all components:
     - STT: Faster Whisper
     - Conversation: Home Assistant (or Local LLM)
     - TTS: Piper
     - Wake word: OpenWakeWord

2. **Test Components Individually**:
   - Developer Tools → Assist
   - Type command (bypasses STT)
   - If works: STT issue
   - If fails: Conversation/TTS issue

3. **Check Entity Availability**:
   - Developer Tools → States
   - Search for: `stt.`, `tts.`, `wake_word.`
   - All should show "unknown" or actual state (not "unavailable")

### LLM Conversation Not Working

**Symptom**: LLM responses timing out or empty

**Solutions**:

1. **Test Ollama Connection**:
   ```bash
   # From Home Assistant
   curl http://GAMING_PC_IP:11434/api/generate -d '{
     "model": "llama3.1:8b",
     "prompt": "Hi"
   }'
   ```

2. **Check Configuration**:
   ```yaml
   conversation:
     - platform: ollama
       url: "http://GAMING_PC_IP:11434"  # Not localhost
       model: "llama3.1:8b"  # Exact model name
   ```

3. **Increase Timeout**:
   ```yaml
   conversation:
     - platform: ollama
       # ... other settings ...
       timeout: 30  # Increase from default
   ```

4. **Use Faster Model**:
   ```yaml
   model: "phi3:mini"  # Instead of llama3.1:8b
   ```

### Calendar Integration Issues

See [CALENDAR_SETUP.md](CALENDAR_SETUP.md) - Troubleshooting section

## Surface Go Issues

### Satellite Not Starting

**Symptom**: Error when running satellite script

**Solutions**:

1. **Check Python Version**:
   ```bash
   python --version
   # Need 3.10+
   ```

2. **Check Virtual Environment**:
   ```powershell
   # Windows
   cd $env:USERPROFILE\wyoming-satellite
   .\venv\Scripts\Activate.ps1
   python -c "import wyoming_satellite; print('OK')"
   ```

3. **Reinstall Dependencies**:
   ```bash
   pip install --upgrade wyoming-satellite pyaudio
   ```

4. **Audio Device Issues** (see below)

### Microphone Not Working

**Symptom**: Wake word not detected

**Solutions**:

1. **List Audio Devices**:
   ```python
   python -c "import pyaudio; p = pyaudio.PyAudio(); [print(f'{i}: {p.get_device_info_by_index(i)[\"name\"]}') for i in range(p.get_device_count())]; p.terminate()"
   ```

2. **Specify Device in Config**:
   ```yaml
   # config.yaml
   microphone:
     device: 1  # Use device number from list above
     sample_rate: 16000
     channels: 1
   ```

3. **Test Microphone**:
   ```bash
   # Windows (PowerShell)
   # Use Sound Recorder app

   # Linux
   arecord -d 3 test.wav && aplay test.wav
   ```

4. **Check Permissions**:
   - **Windows**: Settings → Privacy → Microphone → Allow apps
   - **Linux**: User in `audio` group
     ```bash
     sudo usermod -aG audio $USER
     # Log out and back in
     ```

### Speaker/Audio Output Issues

**Symptom**: No audio response

**Solutions**:

1. **Test Speakers**:
   ```bash
   # Windows: Play a system sound
   # Linux:
   speaker-test -t wav -c 2
   ```

2. **Specify Output Device**:
   ```yaml
   # config.yaml
   speaker:
     device: 2  # Use device number from list
     sample_rate: 22050
   ```

3. **Check Volume**:
   - Windows: Volume mixer
   - Linux: `alsamixer`

### Network Connection Issues

**Symptom**: Can't reach Gaming PC or Home Assistant

**Solutions**:

1. **Verify IPs**:
   ```bash
   # Ping Gaming PC
   ping GAMING_PC_IP

   # Ping Home Assistant
   ping HA_IP
   ```

2. **Test Ports**:
   ```bash
   # Windows
   Test-NetConnection -ComputerName GAMING_PC_IP -Port 10300

   # Linux
   nc -zv GAMING_PC_IP 10300
   ```

3. **Check Firewall** (on Gaming PC and HA)

4. **Verify config.yaml**:
   ```yaml
   wyoming:
     stt:
       uri: "tcp://GAMING_PC_IP:10300"  # Check IP is correct
   ```

### Wake Word Not Detected

**Symptom**: Saying "ok nabu" does nothing

**Solutions**:

1. **Check OpenWakeWord Reachable**:
   ```bash
   telnet GAMING_PC_IP 10400
   ```

2. **Verify Wake Word Model**:
   ```bash
   docker logs openwakeword
   # Should show: Loaded model: ok_nabu
   ```

3. **Test Microphone** (see above)

4. **Adjust Sensitivity**:
   ```yaml
   # config.yaml
   wyoming:
     wake:
       uri: "tcp://GAMING_PC_IP:10400"
       names:
         - "ok_nabu"
       threshold: 0.5  # Lower = more sensitive (0.0-1.0)
   ```

5. **Try Different Wake Word**:
   ```bash
   # Gaming PC
   docker exec openwakeword ls /data/models
   # Try: hey_jarvis, alexa, etc.
   ```

## Performance Issues

### Slow Response Time

**Solutions**:

1. **Use Faster Model**:
   ```yaml
   # Home Assistant configuration.yaml
   conversation:
     - platform: ollama
       model: "phi3:mini"  # ~2-3 sec vs ~5-7 sec for llama
   ```

2. **Check Network Latency**:
   ```bash
   ping GAMING_PC_IP
   # Should be <10ms on local network
   ```

3. **Reduce LLM Token Limit**:
   ```yaml
   conversation:
     - platform: ollama
       max_tokens: 200  # Instead of 500
   ```

4. **Monitor GPU Usage**:
   ```bash
   nvidia-smi -l 1
   # Watch for memory/utilization
   ```

5. **Disable LLM for Simple Commands**:
   - Use "Local Voice Assistant" pipeline (no LLM)
   - Use "Local LLM Assistant" only when needed

### High GPU Memory Usage

**Solutions**:

1. **Check What's Using GPU**:
   ```bash
   nvidia-smi
   ```

2. **Use Smaller Models**:
   - Whisper: `medium` instead of `large-v3`
   - Ollama: `phi3:mini` instead of `llama3.1:8b`

3. **Restart Containers**:
   ```bash
   docker-compose restart
   ```

4. **Reduce Concurrent Processes**:
   ```yaml
   # docker-compose.yml - Piper
   command: >
     --voice en_US-lessac-medium
     --max-piper-procs 1  # Instead of 2
   ```

## Common Error Messages

### "CUDA out of memory"

**Solution**: GPU memory exhausted

1. Close other GPU applications
2. Use smaller models
3. Restart Docker containers
4. Check: `nvidia-smi` - should show available memory

### "Connection refused"

**Solution**: Service not reachable

1. Check service is running: `docker-compose ps`
2. Check firewall allows port
3. Verify IP address correct
4. Test with curl: `curl http://IP:PORT`

### "Model not found"

**Solution**: Ollama model not downloaded

```bash
docker exec ollama ollama list
docker exec ollama ollama pull llama3.1:8b
```

### "Invalid client"

**Solution**: Google Calendar OAuth issue

1. Check redirect URIs in Google Cloud Console
2. Ensure calendar API enabled
3. Re-authorize integration in Home Assistant

### "Authentication failed" (CalDAV)

**Solution**: Apple Calendar password issue

1. Generate new app-specific password
2. Update secrets.yaml
3. Restart Home Assistant

## Diagnostic Commands

### Check All Services

```bash
# Gaming PC
cd gaming-pc-setup
docker-compose ps
docker-compose logs --tail=50

# Test each service
curl http://localhost:11434/api/tags  # Ollama
curl http://localhost:10300           # Whisper
curl http://localhost:10200           # Piper
curl http://localhost:10400           # OpenWakeWord

# GPU status
nvidia-smi

# Disk space
df -h  # Linux
Get-PSDrive C  # Windows
```

### Home Assistant Diagnostics

```bash
# Check configuration
ha core check

# View logs
ha core logs

# Test voice processing
# Developer Tools → Assist → Type test command
```

### Surface Go Diagnostics

```bash
# Windows
Get-Process python
netstat -ano | findstr "GAMING_PC_IP"

# Linux
systemctl --user status wyoming-satellite
journalctl --user -u wyoming-satellite -f

# Test audio
# Windows: Use Sound Recorder
# Linux:
arecord -d 3 test.wav
aplay test.wav
```

## Reset/Clean Install

### Gaming PC

```bash
# Stop and remove all containers
docker-compose down

# Remove volumes (deletes models!)
docker-compose down -v

# Clean start
docker-compose up -d
```

### Home Assistant

1. Remove Wyoming integrations:
   - Settings → Devices & Services → Wyoming → Remove

2. Restore backup if needed:
   - Settings → System → Backups

3. Re-add configuration

### Surface Go

```powershell
# Windows
Remove-Item -Recurse $env:USERPROFILE\wyoming-satellite

# Re-run setup script
.\install-satellite.ps1
```

## Getting Help

### Collect Diagnostic Information

Before asking for help, gather:

1. **System Info**:
   - OS versions
   - GPU model
   - Home Assistant version

2. **Logs**:
   ```bash
   # Gaming PC
   docker-compose logs > logs.txt

   # Home Assistant
   # Settings → System → Logs → Download

   # Surface Go
   # Windows: Copy PowerShell output
   # Linux:
   journalctl --user -u wyoming-satellite > satellite-logs.txt
   ```

3. **Configuration** (remove secrets):
   - docker-compose.yml
   - Home Assistant configuration.yaml snippet
   - Surface Go config.yaml

### Where to Get Help

- **Home Assistant Community**: https://community.home-assistant.io/
- **Wyoming Protocol**: https://github.com/rhasspy/wyoming/issues
- **Ollama**: https://github.com/ollama/ollama/issues
- **Project Issues**: (Your project repository)

### Useful Resources

- [Home Assistant Voice Docs](https://www.home-assistant.io/voice_control/)
- [Wyoming Protocol Docs](https://github.com/rhasspy/wyoming)
- [Ollama Docs](https://ollama.ai/docs)
- [Docker Docs](https://docs.docker.com/)

## Preventive Maintenance

### Regular Tasks

1. **Weekly**:
   - Check disk space
   - Review logs for errors
   - Test voice commands

2. **Monthly**:
   - Update Docker images:
     ```bash
     docker-compose pull
     docker-compose up -d
     ```
   - Update Ollama models:
     ```bash
     docker exec ollama ollama pull llama3.1:8b
     ```
   - Backup Home Assistant

3. **Quarterly**:
   - Review and clean old logs
   - Update Home Assistant
   - Review and optimize automations

### Monitoring

Set up monitoring for:
- Docker container health
- GPU temperature/usage
- Disk space
- Network connectivity

Example automation:
```yaml
automation:
  - alias: "Alert - Voice Assistant Down"
    trigger:
      - platform: state
        entity_id: binary_sensor.ollama_health
        to: "off"
        for: "00:05:00"
    action:
      - service: notify.mobile_app
        data:
          message: "Voice assistant services down!"
```

## Still Having Issues?

If you've tried everything here:

1. Check the specific component documentation
2. Search Home Assistant community
3. Review project issues/discussions
4. Create detailed bug report with logs

Remember: Most issues are configuration or network related!
