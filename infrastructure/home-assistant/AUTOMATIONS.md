# Home Assistant Automations Guide

## Overview

Your Home Assistant now has comprehensive automations covering presence detection, voice assistance, smart device control, and voice command shortcuts.

---

## 📋 Automations Created

### Presence-Based Automations

**Fred Leaves House**
- **Trigger**: When Fred leaves home zone
- **Action**: Turn off office light
- **Purpose**: Energy savings

**Fred Arrives Home**
- **Trigger**: When Fred enters home zone (after sunset only)
- **Action**: Turn on office light at 80% brightness, show welcome notification
- **Purpose**: Automatic welcome lighting

### Voice Assistant Integrated

**Morning Briefing** ⏰ 7:00 AM
- **Trigger**: Daily at 7:00 AM (only if home)
- **Action**: Voice announcement with date, weather, and calendar events
- **Customize**: Change time in automation or disable if not needed

**Calendar Event Reminder**
- **Trigger**: 15 minutes before calendar events
- **Action**: Voice reminder of upcoming event
- **Customize**: Change offset time or add more calendars

### Smart Device Control

**Christmas Lights - Turn On** 🎄
- **Trigger**: 30 minutes before sunset (between 4 PM - 11 PM)
- **Action**: Turn on Christmas lights (Sylvania Smart+ plug)
- **Seasonal**: Disable after holidays

**Christmas Lights - Turn Off**
- **Trigger**: 11:00 PM daily
- **Action**: Turn off Christmas lights
- **Customize**: Adjust bedtime

**Power Strip Energy Save**
- **Trigger**: 1:00 AM daily (only if home)
- **Action**: Turn off outlets 3, 4, 5 to save energy
- **Customize**: Choose which outlets and time

### Notifications & Alerts

**Low Battery Alert** 🔋
- **Trigger**: When device battery drops below 20%
- **Action**: Persistent notification
- **Note**: Adjust entity_id to match your devices

**Security Alert - Motion While Away** 🚨
- **Trigger**: Motion detected when not home
- **Action**: Mobile app notification
- **Note**: Requires motion sensor and mobile app

### Time-Based

**Goodnight Reminder** 🌙
- **Trigger**: 10:30 PM daily (only if home)
- **Action**: Voice reminder to run goodnight routine
- **Customize**: Adjust time to your schedule

**Weekly Todo Review** 📝
- **Trigger**: Sunday at 6:00 PM
- **Action**: Voice prompt to review todo lists
- **Purpose**: Weekly planning habit

---

## 🎤 Voice Command Scripts

Call these scripts via voice: "Hey Nabu, run [script name]" or via UI/automations.

### Daily Routines

**Morning Briefing**
- Announces: Date, weather, calendar events for today
- Use: "Run morning briefing"

**Goodnight**
- Turns off: All lights, Christmas lights, power strip outlets 1 & 2
- Announces: Goodnight message
- Use: "Run goodnight routine"

**I'm Home**
- Turns on: Office light (80%), Christmas lights (if after sunset)
- Announces: Welcome message with current temperature
- Use: "I'm home" or "Run I'm home"

**I'm Leaving**
- Turns off: All lights, Christmas lights, specific power outlets
- Announces: Goodbye message
- Use: "I'm leaving" or "Run I'm leaving"

### Environment Modes

**Movie Time** 🎬
- Sets: Office light to 20% brightness, warm color temp
- Use: "Movie time" or "Run movie time"

**Work Mode** 💼
- Sets: Office light to 100%, cool color temp
- Turns on: Power outlet 1
- Use: "Work mode" or "Run work mode"

### Power Management

**Power Strip - All Off**
- Turns off all 8 power strip outlets
- Shows notification

**Power Strip - All On**
- Turns on all 8 power strip outlets
- Shows notification

**Emergency - All Off** 🚨
- Emergency shutdown: ALL switches and lights
- Use: "Run emergency all off"

---

## 🔧 Customization Guide

### Entity ID Requirements

Some automations reference entities that might not exist in your setup yet. Check and update these:

**Person Entity:**
- `person.fred` - Update in Settings → People if different

**Sensors (Optional):**
- `sensor.fred_watch_battery` - Battery sensor for your watch
- `binary_sensor.motion_sensor` - Motion detector

**Media Player:**
- `media_player.piper_tts` - Your Piper TTS entity from Wyoming integration

**Calendar:**
- `calendar.personal_tasks` - Your personal calendar

### Adjusting Times

Edit `automations.yaml` and change the `at:` values:

```yaml
- platform: time
  at: "07:00:00"  # Change to your preferred time
```

### Adjusting Brightness/Colors

Edit `scripts.yaml` for lighting preferences:

```yaml
data:
  brightness_pct: 80  # 0-100
  color_temp: 250     # 153-500 (cool to warm)
```

### Adding More Devices

To control additional devices, add their `entity_id` to scripts:

```yaml
target:
  entity_id:
    - light.fred_office_light
    - light.bedroom_light  # Add new device
```

---

## 📱 Voice Commands via Assist

To use these with voice, you can either:

1. **Say the script name directly**:
   - "Hey Nabu, run goodnight"
   - "Hey Nabu, run movie time"

2. **Create Intent Scripts** (for more natural language):
   Add to `configuration.yaml`:

```yaml
intent_script:
  GoodNight:
    speech:
      text: "Running goodnight routine"
    action:
      service: script.goodnight
```

Then say: "Hey Nabu, goodnight" (no "run" needed)

---

## 🐛 Troubleshooting

### Automation Not Triggering

1. Check automation is enabled: Settings → Automations → Find automation → Enable toggle
2. Check conditions match (e.g., person.fred state, time of day)
3. Check logs: Settings → System → Logs → Search for automation alias

### Voice Commands Not Working

1. Test script manually: Developer Tools → Services → script.[script_name] → Call Service
2. Check Piper TTS entity exists: Developer Tools → States → Search "piper"
3. Check Wyoming integration: Settings → Integrations → Wyoming

### Entity Not Found Errors

1. Find correct entity ID: Developer Tools → States → Search for device
2. Update `automations.yaml` or `scripts.yaml` with correct ID
3. Reload automations: Developer Tools → YAML → Automations

---

## 💡 Tips & Best Practices

1. **Start Small**: Disable most automations, enable one at a time to test
2. **Test Before Bed**: Test goodnight routine before actually going to bed
3. **Adjust Times**: Tune trigger times to match your actual schedule
4. **Battery Alerts**: Add all your battery-powered devices for monitoring
5. **Security**: Only enable security automations after testing motion sensors
6. **Seasonal**: Disable Christmas light automations after the holidays
7. **Voice Feedback**: Scripts provide voice confirmation - adjust messages as preferred

---

## 🔄 Updating After Changes

After editing `automations.yaml` or `scripts.yaml`:

1. Copy files to HA server (via sync script or manual copy)
2. Go to Developer Tools → YAML
3. Click "Check Configuration"
4. If valid, click "Automations" → Reload (for automations)
5. Or click "Scripts" → Reload (for scripts)
6. Or full restart if needed

---

## 📚 Additional Resources

- [Home Assistant Automation Documentation](https://www.home-assistant.io/docs/automation/)
- [Script Documentation](https://www.home-assistant.io/docs/scripts/)
- [Templating Guide](https://www.home-assistant.io/docs/configuration/templating/)
- Your voice assistant docs: `voice-assistant-project/docs/COMMANDS.md`

---

**Last Updated**: 2025-11-27
