# Morning Reminder

## Questions to Ask Claude Code

### GitHub Sync for Multiple Claude Code Sessions

**Question:** How can I use GitHub to synchronize my Claude Code sessions across different machines?

**Context:**
- I have Claude Code running on multiple machines:
  - VPS (ubuntu-24.04 - 66.63.182.168)
  - Mac Pro 2013 (Sequoia via Open Core Legacy Patcher)
  - Potentially other development machines

**What I want to understand:**
- How to keep this infrastructure repository in sync across all machines
- Best practices for Git workflow with Claude Code on multiple machines
- How to ensure changes made in one Claude Code session are available in others
- Whether I should use branches for machine-specific work or work directly on main
- How to handle potential merge conflicts when working from different locations
- Whether Claude Code has any built-in features for multi-machine workflows

**Use Cases:**
1. Start work on VPS, continue on Mac Pro
2. Document infrastructure changes from whichever machine I'm on
3. Run scripts and update documentation in the same repo from different locations
4. Ensure consistency across all documentation and automation scripts

---

## Git Workflow for Multiple Machines (Quick Reference)

**On laptop (first time):**
```bash
git clone https://github.com/FredN9MRQ/infrastructure.git
cd infrastructure
claude  # Start Claude Code (install first if needed)
```

**When switching between machines:**

**Before leaving current machine:**
```bash
git add .                          # Stage all changes
git commit -m "Description here"   # Save snapshot
git push                           # Upload to GitHub
```

**On new machine:**
```bash
cd infrastructure
git pull                           # Download latest changes
claude                             # Continue working
```

**All your work is now synced!** Any changes on desktop → laptop → VPS stay in sync.

---

## Today's Priority Tasks

1. **Configure WireGuard tunnel between UCG Ultra and VPS** ← CRITICAL - services are down
2. Continue filling out infrastructure-audit.md (Proxmox, network config)
3. Plan IP addressing scheme and DHCP pool boundaries

---

**Created:** 2025-11-14 (midnight)
**Status:** ✅ All changes committed and pushed to GitHub - ready for laptop!
**Read this first thing in the morning!**
