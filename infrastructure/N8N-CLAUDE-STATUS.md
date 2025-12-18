# n8n + Claude Code Integration Status

**Created**: 2025-12-13
**Status**: In Progress

---

## What's Already Done ✅

1. **PostgreSQL** - ✅ Deployed at 10.0.10.20
2. **n8n** - ✅ Deployed at 10.0.10.22:5678
3. **HOMELAB-COMMAND** - ✅ Running at 10.0.10.10 (Gaming PC, Windows 11)
4. **Setup Scripts Created**:
   - `/scripts/setup-homelab-command.ps1` - HOMELAB-COMMAND setup
   - `/scripts/setup-ssh-server.ps1` - SSH server setup
   - `/scripts/test-homelab-ssh.sh` - SSH connectivity test

---

## What's Left To Do 📋

### Phase 1: Claude Code on HOMELAB-COMMAND
- [ ] Verify Node.js 20.x+ installed on HOMELAB-COMMAND
- [ ] Install Claude Code: `npm install -g @anthropic-ai/claude-code`
- [ ] Authenticate Claude Code: `claude auth`
- [ ] Test headless mode: `claude -p "What is 2+2?"`

### Phase 2: SSH Server on HOMELAB-COMMAND
- [ ] Enable OpenSSH Server on Windows 11
- [ ] Start SSH service
- [ ] Configure firewall rules
- [ ] Test local SSH access

### Phase 3: n8n SSH Integration
- [ ] Generate SSH key pair on n8n VM
- [ ] Copy public key to HOMELAB-COMMAND
- [ ] Test SSH from n8n: `ssh user@10.0.10.10 "hostname"`
- [ ] Configure n8n SSH credentials in UI
- [ ] Create test workflow with SSH node

### Phase 4: Verify Integration
- [ ] Test: n8n → SSH → Claude Code headless command
- [ ] Test: Multi-turn conversation with session management
- [ ] Test: Claude Code accessing local files
- [ ] Verify error handling

---

## Quick Start Commands

### On HOMELAB-COMMAND (10.0.10.10):
```powershell
# Check if Node.js installed
node --version

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Authenticate
claude auth

# Test
claude -p "What is 2+2?"

# Enable SSH (if not done)
Add-WindowsCapability -Online -Name OpenSSH.Server
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

### On n8n VM (10.0.10.22):
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "n8n-to-homelab"

# Copy to HOMELAB-COMMAND
ssh-copy-id user@10.0.10.10

# Test
ssh user@10.0.10.10 "claude --version"
```

---

## Reference

- Architecture: n8n (10.0.10.22) → SSH → Claude Code (10.0.10.10)
- Guide: https://github.com/theNetworkChuck/n8n-claude-code-guide
- See MIGRATION-CHECKLIST.md section 6.4 for detailed steps

---

## Next Session

Start with Phase 1: Verify/install Claude Code on HOMELAB-COMMAND
