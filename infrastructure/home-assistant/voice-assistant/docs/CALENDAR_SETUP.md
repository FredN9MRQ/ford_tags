# Calendar Integration Guide

Complete guide to integrating Google Calendar and Apple Calendar with your voice assistant.

## Overview

Your voice assistant can:
- Check today's schedule
- Announce upcoming events
- Add new calendar events
- Get reminders before events
- Query across multiple calendars

## Google Calendar Integration

### Step 1: Enable Google Calendar API

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create a New Project**
   - Click "Select a Project" → "New Project"
   - Name: "Home Assistant Voice"
   - Click "Create"

3. **Enable Google Calendar API**
   - In the project, go to "APIs & Services" → "Library"
   - Search for "Google Calendar API"
   - Click on it and click "Enable"

4. **Configure OAuth Consent Screen**
   - Go to "APIs & Services" → "OAuth consent screen"
   - Select "External" → "Create"
   - App name: "Home Assistant"
   - User support email: Your email
   - Developer contact: Your email
   - Click "Save and Continue"
   - Scopes: Click "Add or Remove Scopes"
     - Add: `.../auth/calendar` (Google Calendar API)
     - Add: `.../auth/calendar.readonly`
   - Click "Save and Continue"
   - Test users: Add your Gmail address
   - Click "Save and Continue"

5. **Create OAuth Credentials**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: "Web application"
   - Name: "Home Assistant"
   - Authorized redirect URIs:
     - Add: `http://YOUR_HA_IP:8123/auth/external/callback`
     - Add: `https://YOUR_HA_DOMAIN/auth/external/callback` (if using HTTPS)
   - Click "Create"
   - **Copy the Client ID and Client Secret**

### Step 2: Configure Home Assistant

1. **Edit secrets.yaml**
   ```yaml
   google_client_id: "123456789-abcdef.apps.googleusercontent.com"
   google_client_secret: "your-client-secret-here"
   ```

2. **Verify configuration.yaml**
   Should already have:
   ```yaml
   google:
     client_id: !secret google_client_id
     client_secret: !secret google_client_secret
   ```

3. **Restart Home Assistant**
   - Developer Tools → Restart

4. **Authorize Google Calendar**
   - Go to Settings → Devices & Services
   - Click "Add Integration"
   - Search for "Google Calendar"
   - Click on it
   - A new window will open asking you to sign in to Google
   - Sign in and grant permissions
   - Select which calendars to sync

5. **Verify Integration**
   - After authorization, you should see calendar entities:
     - `calendar.your_email_gmail_com`
     - Any other calendars you selected

### Step 3: Test Google Calendar

1. **In Home Assistant**
   - Developer Tools → States
   - Find `calendar.your_email_gmail_com`
   - Should show next event

2. **Voice Test**
   - Say: "ok nabu"
   - Say: "What's on my calendar today?"

## Apple Calendar (iCloud) Integration

### Step 1: Generate App-Specific Password

1. **Sign in to Apple ID**
   - Visit: https://appleid.apple.com/
   - Sign in with your Apple ID

2. **Enable Two-Factor Authentication** (if not already)
   - Security section
   - Follow prompts to enable 2FA

3. **Generate App-Specific Password**
   - Security section
   - App-Specific Passwords → Generate Password
   - Label: "Home Assistant"
   - **Copy the password** (format: xxxx-xxxx-xxxx-xxxx)

### Step 2: Configure CalDAV

1. **Edit secrets.yaml**
   ```yaml
   icloud_email: "your-apple-id@icloud.com"
   icloud_app_password: "xxxx-xxxx-xxxx-xxxx"  # From Step 1
   ```

2. **Verify configuration.yaml**
   Should already have:
   ```yaml
   caldav:
     - url: https://caldav.icloud.com
       username: !secret icloud_email
       password: !secret icloud_app_password
       calendars:
         - "Personal"
         - "Work"
   ```

3. **Find Your Calendar Names**

   iCloud calendar names must match exactly. To find them:

   - Option 1: Check iCloud.com
     - Visit: https://www.icloud.com/calendar
     - Your calendar names are in the left sidebar

   - Option 2: Use CalDAV discovery
     ```bash
     curl -u "YOUR_EMAIL:xxxx-xxxx-xxxx-xxxx" \
       https://caldav.icloud.com/
     ```

4. **Update Calendar Names**

   Edit `configuration.yaml` to match your actual calendar names:
   ```yaml
   caldav:
     - url: https://caldav.icloud.com
       username: !secret icloud_email
       password: !secret icloud_app_password
       calendars:
         - "Home"        # Change to match
         - "Work"        # your actual
         - "Personal"    # calendar names
   ```

5. **Restart Home Assistant**
   - Developer Tools → Restart

6. **Verify Integration**
   - Developer Tools → States
   - Look for entities like:
     - `calendar.personal`
     - `calendar.work`

### Step 3: Test Apple Calendar

1. **Check Events**
   - Developer Tools → States
   - Find your CalDAV calendar entities
   - Should show next event

2. **Voice Test**
   - Say: "ok nabu"
   - Say: "What's on my calendar?"

## Combining Multiple Calendars

### Create Unified Calendar View

In `configuration.yaml`, add:

```yaml
sensor:
  - platform: template
    sensors:
      all_upcoming_events:
        friendly_name: "All Upcoming Events"
        value_template: >
          {% set events = namespace(list=[]) %}
          {% for cal in states.calendar %}
            {% if cal.state == 'on' %}
              {% set events.list = events.list + [cal.attributes] %}
            {% endif %}
          {% endfor %}
          {{ events.list | count }}
        attribute_templates:
          events: >
            {% set events = namespace(list=[]) %}
            {% for cal in states.calendar %}
              {% if cal.state == 'on' %}
                {% set events.list = events.list + [cal.attributes] %}
              {% endif %}
            {% endfor %}
            {{ events.list | sort(attribute='start_time') }}
```

### Update Voice Commands

In `scripts.yaml`, update `todays_agenda`:

```yaml
todays_agenda:
  alias: "Today's Agenda"
  sequence:
    - service: tts.speak
      data:
        entity_id: media_player.surface_go
        message: >
          {% set now_date = now().date() %}
          Here's your agenda for {{ now().strftime('%A, %B %d') }}.

          {% set all_events = [] %}
          {% for cal in states.calendar %}
            {% if cal.attributes.all_events %}
              {% set all_events = all_events + cal.attributes.all_events %}
            {% endif %}
          {% endfor %}

          {% if all_events %}
            You have {{ all_events | count }} events:
            {% for event in all_events | sort(attribute='start') %}
              {{ event.summary }} at {{ event.start | as_timestamp | timestamp_custom('%I:%M %p') }}
              {% if event.calendar_name %}from {{ event.calendar_name }}{% endif %}.
            {% endfor %}
          {% else %}
            No events scheduled today.
          {% endif %}
```

## Voice Commands for Calendars

### Checking Calendar

**Basic Commands:**
- "What's on my calendar?"
- "What's on my calendar today?"
- "Do I have any meetings today?"
- "What's my next event?"

**Using LLM Assistant:**
- "Tell me about my schedule today"
- "What should I prepare for today?"
- "When is my next meeting?"

### Adding Events (via LLM)

With the LLM assistant, you can use natural language:

- "Add a meeting with Bob at 2pm tomorrow"
- "Schedule dentist appointment for next Tuesday at 10am"
- "Block off Friday afternoon for project work"

The LLM will extract the details and call the appropriate service.

## Advanced: Custom Calendar Intents

### Add Event Intent

In `scripts.yaml`, create:

```yaml
add_calendar_event_voice:
  alias: "Add Calendar Event (Voice)"
  fields:
    event_name:
      description: "Name of the event"
    event_time:
      description: "Time of event (natural language)"
  sequence:
    # Parse natural language time using LLM
    - service: conversation.process
      data:
        agent_id: conversation.local_llm
        text: >
          Parse this into ISO datetime: {{ event_time }}
          Today is {{ now().strftime('%Y-%m-%d') }}
          Return ONLY the ISO datetime in format: YYYY-MM-DD HH:MM:SS
      response_variable: parsed_time

    # Add to Google Calendar
    - service: calendar.create_event
      target:
        entity_id: calendar.your_calendar
      data:
        summary: "{{ event_name }}"
        start_date_time: "{{ parsed_time.response.speech.plain.speech }}"
        end_date_time: "{{ (parsed_time.response.speech.plain.speech | as_datetime + timedelta(hours=1)) }}"

    # Confirm
    - service: tts.speak
      data:
        entity_id: media_player.surface_go
        message: "Added {{ event_name }} to your calendar."
```

## Troubleshooting

### Google Calendar

**Issue: "Invalid Client" Error**
- Check redirect URIs match exactly (including http/https)
- Ensure project has Google Calendar API enabled

**Issue: No Events Showing**
- Check calendar is not empty
- Verify calendar was selected during authorization
- Try re-authorizing: Settings → Integrations → Google Calendar → Configure

**Issue: Authorization Loop**
- Clear browser cache
- Use incognito window
- Check system time is correct

### Apple Calendar (CalDAV)

**Issue: "Authentication Failed"**
- Verify app-specific password is correct
- Check 2FA is enabled on Apple ID
- Try generating new app-specific password

**Issue: Calendars Not Found**
- Verify calendar names match exactly (case-sensitive)
- Check calendar exists in iCloud.com
- Try using calendar UID instead of name:
  ```yaml
  calendars:
    - "12345678-1234-1234-1234-123456789abc"  # Calendar UID
  ```

**Issue: Events Not Updating**
- CalDAV sync may be delayed (up to 15 minutes)
- Restart Home Assistant to force sync
- Check Home Assistant logs for errors

### General Calendar Issues

**Issue: Old Events Still Showing**
- Home Assistant caches calendar data
- Restart to refresh
- Check event hasn't recurred

**Issue: Voice Commands Not Working**
- Test command in Developer Tools → Assist first
- Check TTS is working
- Verify calendar entities exist (Developer Tools → States)

## Privacy & Security

- **Google Calendar**: OAuth tokens stored encrypted in Home Assistant
- **Apple Calendar**: App-specific password isolates access
- **Local Processing**: Calendar data processed locally, not sent to cloud for LLM
- **Revoke Access**:
  - Google: https://myaccount.google.com/permissions
  - Apple: Delete app-specific password from appleid.apple.com

## Tips & Best Practices

1. **Multiple Calendars**: Use separate calendars for work/personal
2. **Color Coding**: Use different calendars, not colors (better for voice)
3. **Event Titles**: Clear, concise titles work best for voice
4. **Reminders**: Set up automations for important event types
5. **Sync Frequency**: CalDAV checks every 15 minutes by default

## Next Steps

- Configure task/todo lists: See main configuration
- Add weather integration: See [INSTALLATION.md](INSTALLATION.md)
- Create custom voice commands: See [COMMANDS.md](COMMANDS.md)
