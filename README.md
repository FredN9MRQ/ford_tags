# Fred's Projects - Source of Truth

This is the master directory for all active projects. It serves as the "source of truth" for Claude Code sessions.

---

## Quick Start with VS Code Insiders

**Open the workspace**:
```
Double-click: fred-workspace.code-workspace
```

Or from VS Code: `File → Open Workspace → fred-workspace.code-workspace`

**Start Claude Code**:
```bash
cd C:\Users\Fred\projects
claude
```

**Tell Claude to load context**:
```
"Read .claude-context.md to understand my project structure"
```

---

## Projects Overview

### 🎯 [claude-workflows](claude-workflows/)
**ADHD-friendly productivity tools for Claude Code**
- Slash commands (`/push`, `/eod`)
- ADHD assistant with sidequest detection
- Auto-discovery for cross-project setup

**Start here when**: Working on Claude Code tooling, productivity features

---

### 🏥 [VA-Strategy](VA-Strategy/)
**VA disability claims management system**
- Goal: 100% VA rating via TDIU
- Current: 60% combined (30% highest single)
- Tracking, evidence, statements, forms

**Start here when**: Working on VA claims, medical documentation

**Quick commands**:
```bash
cd VA-Strategy
git status                    # Check what's changed
cat tracking/master-tracking.md  # See current status
```

---

### 🏠 [infrastructure](infrastructure/)
**Home network, Home Assistant, smart home**
- Home Assistant configuration
- ESPHome devices (garage controller, furnace)
- Voice assistant system (GPU-accelerated, local)
- Network infrastructure (MQTT, DNS-over-TLS)

**Start here when**: Working on home automation, voice assistant, ESPHome

**Active subprojects**:
- Voice Assistant: Gaming PC + Surface Go
- Furnace Control: ESP32 planning phase
- Home Assistant: Main config

---

### ⚙️ [config](config/)
**Shared configuration files**

Minimal/placeholder for cross-project configs.

---

### 📚 [claude-code-history](claude-code-history/)
**Background: Claude Code session history**

Session transcripts, state files, stats. Mostly hidden from searches.

---

## Key Files

| File | Purpose |
|------|---------|
| `.claude-context.md` | Master context file - tells Claude about all projects |
| `fred-workspace.code-workspace` | VS Code multi-root workspace |
| `VSCODE-SETUP.md` | Detailed setup guide for VS Code + Claude |
| `README.md` | This file - quick reference |

---

## ADHD-Friendly Workflow

### How Sidequest Detection Works

1. You're working in one project (e.g., VA-Strategy)
2. You start exploring something related to another project (e.g., ESP32 for infrastructure)
3. Claude detects the context shift
4. Claude offers to:
   - Track it as a side quest
   - Switch projects formally
   - Create a new project
   - Return to original work

### Example

```
You: [Working in VA-Strategy on headache log]
You: "I wonder if I could automate headache tracking with Home Assistant"

Claude: 🤔 Side quest detected!

   Current: VA-Strategy (headache log)
   New idea: HA automation (infrastructure)

   Options:
   1. Continue exploring (I'll track it)
   2. Switch to infrastructure project
   3. Create new "health-automation" project
   4. Return to headache log
```

---

## Common Workflows

### Start Working on a Project
```bash
cd C:\Users\Fred\projects\VA-Strategy
claude
# Tell Claude what you want to work on
```

### Switch Projects Mid-Session
Just tell Claude:
```
"I want to switch to working on infrastructure now"
```

Claude will track the context switch.

### Explore a Side Quest
```
"This is a side quest - I want to explore X for 20 minutes"
```

Claude will set a timer and check in.

### End of Day
```
/eod
```

Claude will:
- Commit your changes
- Show what you accomplished
- Prepare for tomorrow

---

## Setup Checklist

- [x] `.claude-context.md` created
- [x] Workspace file created
- [ ] Open workspace in VS Code Insiders
- [ ] Create ADHD assistant state directory:
  ```powershell
  New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude-assistant" -Force
  Copy-Item "claude-workflows\.assistant\state.json.template" "$env:USERPROFILE\.claude-assistant\state.json"
  ```
- [ ] Start Claude Code session
- [ ] Test sidequest detection

---

## Files You Should Know About

### Global Context
- **`.claude-context.md`** - Tells Claude about all your projects
- **`fred-workspace.code-workspace`** - Multi-root workspace for VS Code
- **`VSCODE-SETUP.md`** - Detailed setup instructions

### ADHD Assistant
- **`claude-workflows/.assistant/personality.md`** - How Claude should behave
- **`claude-workflows/.assistant/state.json.template`** - Session state template
- **`~/.claude-assistant/state.json`** - Your active state file (to be created)

### Project-Specific
- **`VA-Strategy/CLAUDE.md`** - VA project context
- **`VA-Strategy/README.md`** - VA project overview
- **`infrastructure/README.md`** - Infrastructure overview
- **`claude-workflows/README.md`** - Workflows overview

---

## Customization

### Adjust ADHD Assistant Behavior

Edit: `~/.claude-assistant/state.json`

```json
{
  "user": {
    "preferences": {
      "intervention_style": "gentle",    // gentle | assertive | minimal
      "stuck_threshold": 3,              // How many times before intervention
      "sidequest_time_limit_minutes": 30, // Check-in time
      "celebrates_completions": true     // Celebrate wins
    }
  }
}
```

### Add More Projects

Edit: `fred-workspace.code-workspace`

Add new folder:
```json
{
  "path": "new-project",
  "name": "📦 New Project"
}
```

---

## Getting Help

### Claude Code
- `/help` - Claude Code help
- Ask Claude: "How does sidequest detection work?"

### Project-Specific
- Each project has a README.md
- VA-Strategy and infrastructure have CLAUDE.md files

### Issues
Report at: https://github.com/anthropics/claude-code/issues

---

## Philosophy

This setup is designed to work **with** ADHD, not against it:

✓ Side quests are valid exploration
✓ Context switching is supported
✓ Progress is celebrated
✓ No judgment on workflow
✓ Gentle nudging, not rigid control

Claude is here to help you stay aware of what you're working on, not to police your focus.

---

**Ready?** Open `fred-workspace.code-workspace` and start a Claude session!
