# Aider Quick Start Guide

## What is Aider?

Aider is your **local, free AI coding assistant** that works with Ollama. It saves Claude API tokens for routine coding tasks.

## Setup Complete! ✓

- Aider installed
- Ollama configured with two models:
  - `qwen2.5-coder:7b-instruct` (fast, 8GB VRAM)
  - `qwen2.5-coder:14b-instruct` (smart, uses some RAM)
- Config file: `~/.aider.conf.yml`
- Helper functions: `C:\Users\Fred\projects\aider-helpers.ps1`

## Quick Start

### 1. Load Helper Functions (One Time Setup)

Add this line to your PowerShell profile:

```powershell
. C:\Users\Fred\projects\aider-helpers.ps1
```

To find your profile location:
```powershell
$PROFILE
```

Or run the helpers manually each session:
```powershell
. C:\Users\Fred\projects\aider-helpers.ps1
```

### 2. Basic Usage

```powershell
# Navigate to your project
cd C:\Users\Fred\projects\VA-Strategy

# Start Aider (uses 7b model by default)
aider-fast

# Or use the smarter model for complex tasks
aider-smart

# Or use plain aider (reads .aider.conf.yml)
aider
```

### 3. Inside Aider

```
> Add a function to parse headache log entries
> Refactor the PTSD statement generator
> Add error handling to the tracking module
> /help  # see all commands
> /exit  # quit
```

## When to Use What

### Use Aider (Local) for:
- ✅ Refactoring code
- ✅ Writing boilerplate
- ✅ Adding simple features
- ✅ Code reviews
- ✅ Fixing simple bugs
- ✅ Documentation
- ✅ Test writing

Cost: **$0** (completely free, uses your GPU)

### Use Claude Code for:
- 🎯 Complex architectural decisions
- 🎯 Multi-file refactors requiring deep understanding
- 🎯 Difficult debugging
- 🎯 Planning new features
- 🎯 Strategic code design

Cost: ~$3-15 per million tokens (monthly limit)

## Helper Commands

```powershell
aider-fast      # Fast 7b model (everyday coding)
aider-smart     # Powerful 14b model (complex tasks)
aider-plan      # Architect mode (planning)
aider-commit    # Generate git commit messages
aider-watch     # Auto-reload on file changes
aider-status    # Show available models and commands
aider-estimate  # Compare token costs
```

## Examples

### Example 1: Simple Refactor
```powershell
cd C:\Users\Fred\projects\VA-Strategy
aider-fast tracking/headache-log.py

> Refactor this to use dataclasses instead of dictionaries
```

### Example 2: Add Feature
```powershell
cd C:\Users\Fred\projects\infrastructure\voice-assistant
aider-fast

> Add a new command to check system temperature
> /add sensors.py utils.py
> Make sure it logs to the debug file
```

### Example 3: Git Commit
```powershell
git add .
aider-commit
# Aider will analyze changes and suggest a commit message
```

## Tips

1. **Start Small**: Try Aider on simple tasks first to get comfortable
2. **Use Git**: Aider works best with git repos (can auto-commit)
3. **Be Specific**: Clear prompts get better results ("Add error handling for missing files" vs "make it better")
4. **Switch Models**: Use 7b for speed, 14b for quality
5. **Save Claude Tokens**: Use Aider for 80% of tasks, Claude for the 20% that need genius-level reasoning

## Token Savings Example

**Typical Day:**
- 10 simple refactors: Aider (free) instead of Claude ($0.30)
- 5 feature additions: Aider (free) instead of Claude ($0.75)
- 3 bug fixes: Aider (free) instead of Claude ($0.45)
- 2 complex architecture tasks: Claude ($0.60)

**Total saved: $1.50/day = $45/month**

## Troubleshooting

### Ollama not running
```powershell
# Check Ollama status
ollama list

# Restart Ollama if needed (it should auto-start)
```

### Model too slow
```powershell
# Switch to faster 7b model
aider --model ollama/qwen2.5-coder:7b-instruct
```

### Need better quality
```powershell
# Switch to smarter 14b model
aider --model ollama/qwen2.5-coder:14b-instruct
```

## Next Steps

1. Load the helper functions in your PowerShell profile
2. Try `aider-status` to verify everything works
3. Navigate to a project and run `aider-fast`
4. Start with a simple task like "Add a docstring to this function"

---

**Happy coding!** You're now set up to save Claude tokens while maintaining productivity.

For full Aider documentation: https://aider.chat
