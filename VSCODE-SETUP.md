# VS Code Insiders Setup for Context-Aware Claude Code

This guide shows you how to use VS Code Insiders with Claude Code so that Claude has full awareness of all your projects and can detect sidequests.

---

## Quick Start (5 Minutes)

### 1. Open the Multi-Root Workspace

**Option A: Double-click the workspace file**
```
C:\Users\Fred\projects\fred-workspace.code-workspace
```

**Option B: From VS Code Insiders**
1. File → Open Workspace from File
2. Navigate to `C:\Users\Fred\projects\`
3. Select `fred-workspace.code-workspace`

This opens all your projects in a single window with sidebar folders:
- 🎯 Claude Workflows
- 🏥 VA Strategy
- 🏠 Infrastructure
- ⚙️ Config

---

### 2. Start Claude Code in the Workspace

**From VS Code Insiders terminal:**
```bash
cd "C:\Users\Fred\projects"
claude
```

**Or from any project folder:**
```bash
cd "C:\Users\Fred\projects\VA-Strategy"
claude
```

Claude will now have access to `.claude-context.md` which tells it about your entire project ecosystem.

---

### 3. Tell Claude to Read the Context

When you start a session, say:

> "Read the .claude-context.md file to understand my project structure"

Or just start working and Claude will reference it automatically when relevant.

---

## How It Works

### Context Loading Flow

1. **You open VS Code** with the workspace
2. **You start Claude Code** in a project folder
3. **Claude reads** `.claude-context.md` for ecosystem awareness
4. **Claude reads** project-specific `CLAUDE.md` (if exists)
5. **Claude knows**:
   - All your projects
   - Current project context
   - How to detect sidequests
   - ADHD-friendly behaviors to use

### Example Session

```
You: [Working in VA-Strategy, writing headache log]
Claude: [Helping with headache log entries]

You: "Hey, I wonder if I can use an ESP32 to track my headaches automatically"
Claude: 🤔 I notice we've shifted focus:

   Current project: VA-Strategy (headache log)
   New idea: ESP32 headache tracker

   This looks like a side quest that connects to your infrastructure project!

   Would you like to:
   1. Continue exploring (I'll track it as a side quest)
   2. Switch to the infrastructure project
   3. Create a new project for health tracking
   4. Park it and return to the headache log
```

---

## Advanced Setup

### Create State Directory

The ADHD assistant uses a state file to track sessions:

```powershell
# Create the directory
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude-assistant" -Force

# Copy the template
Copy-Item "C:\Users\Fred\projects\claude-workflows\.assistant\state.json.template" "$env:USERPROFILE\.claude-assistant\state.json"
```

**Location**: `C:\Users\Fred\.claude-assistant\state.json`

### Customize Assistant Behavior

Edit the state file to set preferences:

```json
{
  "user": {
    "name": "Fred",
    "preferences": {
      "intervention_style": "gentle",
      "stuck_threshold": 3,
      "sidequest_time_limit_minutes": 30,
      "celebrates_completions": true
    }
  }
}
```

---

## Project-Specific Context

Each project can have its own `CLAUDE.md` file:

### Existing CLAUDE.md Files

1. **[VA-Strategy/CLAUDE.md](VA-Strategy/CLAUDE.md)**
   - VA claims context
   - Current status
   - Strategic goals
   - Evidence requirements

2. **[infrastructure/voice-assistant/CLAUDE.md](infrastructure/voice-assistant/CLAUDE.md)**
   - Voice assistant setup
   - Docker configuration
   - Integration details

### When to Create CLAUDE.md

Create a `CLAUDE.md` in a project when:
- The project has specific domain knowledge
- There are recurring workflows
- You want Claude to remember project-specific context

**Template**:
```markdown
# CLAUDE.md

## Project Purpose
[What this project does]

## Current Status
[Where things are at]

## Common Tasks
[Things you do regularly]

## Critical Context
[Things Claude should always remember]

## Common Commands
[Frequently used commands]
```

---

## Workspace Customization

### Edit the Workspace File

To add/remove projects or change settings:

```bash
code "C:\Users\Fred\projects\fred-workspace.code-workspace"
```

### Add a New Project

```json
{
  "folders": [
    // ... existing folders ...
    {
      "path": "new-project",
      "name": "🆕 New Project"
    }
  ]
}
```

### Workspace-Specific VS Code Settings

The workspace file includes settings to:
- Hide `claude-code-history` from searches (it's big and not relevant)
- Show `.git` folders (useful for git operations)
- Optimize file watching

---

## Slash Commands Integration

### Available Everywhere

The `/push` and `/eod` commands from claude-workflows should work in any project:

```bash
# Quick commit and push
/push

# End of day workflow
/eod
```

### Setup Symlinks (If Not Done)

If slash commands aren't working across projects:

**Windows PowerShell (Run as Administrator)**:
```powershell
cd "C:\Users\Fred\projects\claude-workflows"
.\setup-symlinks.ps1
```

This creates symlinks in all project `.claude/commands` directories.

---

## Sidequest Detection Example

### Scenario: Working on VA Strategy, Get Distracted

```
📋 Current Project: VA-Strategy
🎯 Goal: Complete headache log for migraine claim

[You start researching Home Assistant voice commands for headache tracking]

Claude: 🤔 Side quest detected!

   Started: Researching HA voice commands
   Time: 15 minutes
   Original goal: Headache log completion

   This could be valuable! Should we:
   1. Keep going (it's worth it)
   2. Switch to infrastructure project formally
   3. Create new project: "health-tracking"
   4. Wrap up and return to headache log

   Your call!
```

---

## Tips for ADHD-Friendly Workflow

### 1. Single Window, Multiple Projects
The multi-root workspace lets you see all projects without switching windows.

### 2. Use Claude to Track Context
When you get distracted, Claude remembers what you were doing.

### 3. Explicit Side Quests
When you start something new, tell Claude:
> "This is a side quest - I'm exploring X for 20 minutes"

### 4. Regular Check-ins
Use the `/focus` command (when implemented) to ask:
> "What was I working on?"

### 5. End of Day Ritual
Use `/eod` to:
- Commit your work
- Review what you accomplished
- Set up tomorrow's focus

---

## Troubleshooting

### Claude Doesn't Seem to Know About Other Projects

**Solution**: Explicitly ask Claude to read the context:
```
"Read .claude-context.md to understand my project ecosystem"
```

### Slash Commands Not Working

**Solution**: Check that commands are symlinked:
```powershell
ls "C:\Users\Fred\projects\VA-Strategy\.claude\commands"
```

Should show symlink to shared commands.

### State File Not Persisting

**Solution**: Verify state directory exists:
```powershell
Test-Path "$env:USERPROFILE\.claude-assistant\state.json"
```

If false, create it:
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude-assistant" -Force
Copy-Item "C:\Users\Fred\projects\claude-workflows\.assistant\state.json.template" "$env:USERPROFILE\.claude-assistant\state.json"
```

---

## Next Steps

### Immediate
- [x] Created `.claude-context.md` with all project info
- [x] Created workspace file
- [ ] Open workspace in VS Code Insiders
- [ ] Start Claude Code session
- [ ] Test sidequest detection

### Soon
- [ ] Create state directory if needed
- [ ] Customize ADHD assistant preferences
- [ ] Test cross-project workflow
- [ ] Add more project-specific CLAUDE.md files as needed

---

## Quick Reference

| File | Purpose |
|------|---------|
| `.claude-context.md` | Ecosystem-level context for all projects |
| `CLAUDE.md` | Project-specific context and guidance |
| `fred-workspace.code-workspace` | VS Code multi-root workspace |
| `~/.claude-assistant/state.json` | ADHD assistant state tracking |
| `.assistant/personality.md` | ADHD behavior rules |

---

**You're all set!** Open the workspace and start a Claude session. Claude will now understand your entire project structure and can intelligently help with sidequests and context switching.
