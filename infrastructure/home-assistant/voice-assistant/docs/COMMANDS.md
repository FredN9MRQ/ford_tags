# Voice Commands Reference

Complete guide to using voice commands with your local AI assistant.

## Wake Word

**Default**: "ok nabu"

Say the wake word, wait for the confirmation sound, then speak your command.

## Basic Usage

1. Say: **"ok nabu"**
2. Wait for beep/chime
3. Speak your command
4. Wait for response

## Built-in Commands

### Calendar

| Command | Description | Example |
|---------|-------------|---------|
| "What's on my calendar?" | Lists today's events | Shows all events for today |
| "What's on my calendar today?" | Same as above | Shows all events |
| "What's my next event?" | Shows next upcoming event | Shows time and title |
| "Do I have any meetings?" | Checks for meetings | Yes/no with details |

### Weather

| Command | Description | Example |
|---------|-------------|---------|
| "What's the weather?" | Current conditions | Temperature and status |
| "What's the weather like?" | Same as above | Detailed conditions |
| "Weather forecast" | Detailed forecast | Temp, humidity, wind |

### Tasks

| Command | Description | Example |
|---------|-------------|---------|
| "What are my tasks?" | Lists pending tasks | Reads task list |
| "How many tasks do I have?" | Task count | Number of pending tasks |
| "List my tasks" | Detailed task list | First 3 tasks from each list |

### Time & Date

| Command | Description | Example |
|---------|-------------|---------|
| "What time is it?" | Current time | 3:45 PM |
| "What's today's date?" | Current date | Monday, January 15th |

## LLM-Powered Commands

When using the "Local LLM Assistant" pipeline, you can use natural language:

### Conversational Calendar

**Examples:**
- "Tell me about my schedule today"
- "What should I prepare for?"
- "When am I free this afternoon?"
- "Summarize my week"
- "What's coming up?"

### Task Management

**Query Tasks:**
- "What should I focus on today?"
- "What are my priorities?"
- "Tell me about my work projects"

**Add Tasks** (with proper intent script):
- "Add buy groceries to my shopping list"
- "Remind me to call Bob"
- "Add review proposal to work projects"

### Productivity

**Examples:**
- "Give me a productivity tip"
- "Help me plan my day"
- "What should I tackle first?"
- "How can I be more efficient?"

### General Knowledge

**Examples:**
- "Explain [topic]"
- "How do I [task]?"
- "What's [concept]?"

## Custom Scripts

The following scripts are available (callable via voice or automation):

### Morning Routine

**Trigger**: Automatic at 7 AM, or say:
- "Morning briefing"
- "Give me my morning update"

**Includes**:
- Weather forecast
- Calendar events
- Task count
- Productivity tip from LLM

### Today's Agenda

**Command**:
- "What's my agenda?"
- "Tell me about today"

**Includes**:
- All calendar events
- Pending tasks
- Time-ordered list

### Evening Review

**Trigger**: Automatic at 9 PM, or say:
- "Evening review"
- "How did I do today?"

**Includes**:
- Tasks remaining
- Encouraging message from LLM
- Tomorrow preview

### Project Status

**Command**:
- "Project status"
- "How are my work projects?"

**Includes**:
- Completed vs total tasks
- Remaining work
- Project breakdown

## Creating Custom Commands

### Method 1: Intent Scripts

Add to `configuration.yaml`:

```yaml
intent_script:
  CheckReminders:
    speech:
      text: >
        {% set reminders = state_attr('todo.reminders', 'items') %}
        You have {{ reminders | count }} reminders.
    action:
      - service: logbook.log
        data:
          name: "Reminder Check"
          message: "User checked reminders"
```

Then use with: "Check reminders"

### Method 2: Script + Sentence Trigger

1. **Create Script** in `scripts.yaml`:

```yaml
start_focus_mode:
  alias: "Start Focus Mode"
  sequence:
    - service: notify.mobile_app
      data:
        message: "Focus mode activated"
    - service: switch.turn_off
      target:
        entity_id: switch.notifications
    - service: tts.speak
      data:
        entity_id: media_player.surface_go
        message: "Focus mode enabled. I'll be quiet now."
```

2. **Add Sentence Trigger** in Home Assistant UI:
   - Settings → Voice Assistants
   - Click your assistant → Sentences
   - Add: "Start focus mode" → Calls `script.start_focus_mode`

### Method 3: LLM Function Calling

For complex, natural language commands, use the LLM:

```yaml
conversation:
  - platform: ollama
    # ... existing config ...
    prompt: |
      You are a voice assistant with access to these functions:
      - check_calendar(date): Check calendar events
      - add_task(task, list): Add task to list
      - get_weather(): Get weather info

      When user requests these, respond with the function call.
```

## Command Tips

### Phrasing

**Good**:
- Clear, direct commands
- "What's the weather?"
- "Add milk to shopping list"

**Avoid**:
- Overly complex sentences
- "Um, could you maybe tell me what the weather might be like today?"

### Timing

- Wait for wake word confirmation before speaking
- Speak at normal pace (not too fast)
- Brief pause between wake word and command

### Accuracy

If command not understood:
1. Repeat clearly
2. Try alternative phrasing
3. Check microphone positioning
4. Review recognized text in HA logs

## Advanced: Contextual Commands

### Multi-Turn Conversations

With LLM assistant, you can have context:

**Turn 1**: "What's my next meeting?"
**Response**: "Team sync at 2 PM"
**Turn 2**: "Who's invited?"
**Response**: *Checks calendar attendees*

### Conditional Responses

Create scripts that adapt:

```yaml
adaptive_greeting:
  sequence:
    - service: tts.speak
      data:
        entity_id: media_player.surface_go
        message: >
          {% set hour = now().hour %}
          {% if hour < 12 %}
            Good morning!
          {% elif hour < 17 %}
            Good afternoon!
          {% else %}
            Good evening!
          {% endif %}
          {{ ['Ready to help!', 'How can I assist?', 'What can I do for you?'] | random }}
```

## Automation-Triggered Announcements

These happen automatically:

### Proactive Reminders

- **15 minutes before event**: "Reminder: [event] starts in 15 minutes"
- **Morning**: Daily briefing at 7 AM
- **Evening**: Day review at 9 PM
- **Task due**: Alerts for approaching deadlines

### Event-Based

- **Weather alerts**: Announces rain, snow, etc.
- **Task completed**: Confirms completion
- **Calendar changes**: Alerts to new/updated events

### Disable Announcements

To temporarily disable:

```yaml
# Add input_boolean to configuration.yaml
input_boolean:
  voice_announcements:
    name: Voice Announcements
    initial: on

# Update automations to check state
condition:
  - condition: state
    entity_id: input_boolean.voice_announcements
    state: 'on'
```

Say: "Turn off voice announcements"

## Debugging Commands

### Test in Home Assistant

1. **Developer Tools → Assist**
2. Type your command (no wake word needed)
3. See processed result
4. Check for errors

### View Recognition

1. **Settings → System → Logs**
2. Filter: "wyoming"
3. See what was heard

### Manual Script Execution

1. **Developer Tools → Services**
2. Select your script
3. Call it directly
4. Test without voice

## Voice Command Best Practices

### Do's

✅ Use simple, direct language
✅ Wait for confirmation before speaking
✅ Speak clearly at normal volume
✅ Position microphone appropriately
✅ Test new commands in HA first

### Don'ts

❌ Don't string multiple commands together
❌ Don't speak while wake word is processing
❌ Don't shout or whisper
❌ Don't use complex sentence structures
❌ Don't expect perfect accuracy without training

## Customizing Wake Word

### Change to Custom Wake Word

1. **Train Custom Wake Word** using openWakeWord
2. **Add Model** to Gaming PC:
   ```bash
   cd gaming-pc-setup/config/custom-wakewords
   # Add your .tflite model file
   ```

3. **Update docker-compose.yml**:
   ```yaml
   command: >
     --preload-model 'ok_nabu'
     --preload-model 'your_custom_wakeword'
   ```

4. **Restart Services**:
   ```bash
   docker-compose restart openwakeword
   ```

### Popular Wake Word Alternatives

- "hey jarvis"
- "computer"
- "assistant"
- Custom name

## Multi-Language Support

To add another language:

1. **Download Models**:
   ```bash
   # In Gaming PC
   docker exec whisper download-model large-v3-es  # Spanish
   ```

2. **Create New Pipeline** in HA:
   - Language: Spanish
   - Same STT/TTS services
   - Separate wake word if desired

3. **Switch Languages**:
   - Use different wake words per language
   - Or switch pipeline manually in HA

## Performance Optimization

### Faster Responses

1. **Use Phi-3 Mini** for quick queries:
   - Faster inference
   - Good for simple tasks
   - Edit conversation config to use `phi3:mini`

2. **Reduce TTS Latency**:
   - Use faster Piper voice
   - Adjust chunk size

3. **Cache Common Responses**:
   ```yaml
   # Create template sensors for frequent queries
   sensor:
     - platform: template
       sensors:
         quick_weather:
           value_template: "{{ state_attr('weather.local_weather', 'temperature') }}°"
   ```

## Privacy & Security

- All voice processed locally
- LLM runs on your hardware
- No cloud services for core functionality
- Calendar data stays local
- Conversation history not stored by default

## Next Steps

- Add more custom commands
- Train custom wake word
- Set up additional voice satellites
- Integrate smart home control
- Create custom LLM prompts

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common command issues.
