#!/bin/bash
# Test SSH Access to HOMELAB-COMMAND
# Run this from M6800 or n8n VM to verify SSH connectivity

TARGET_HOST="${1:-10.0.10.10}"
TARGET_USER="${2:-$USER}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================${NC}"
echo -e "${CYAN}SSH Connection Test to HOMELAB-COMMAND${NC}"
echo -e "${CYAN}====================================${NC}"
echo ""
echo "Target: $TARGET_USER@$TARGET_HOST"
echo ""

# Test 1: Network connectivity
echo -e "${CYAN}[Test 1]${NC} Network connectivity..."
if ping -c 1 -W 2 "$TARGET_HOST" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Host is reachable"
else
    echo -e "${RED}✗${NC} Host is not reachable"
    echo "  - Check network connection"
    echo "  - Verify HOMELAB-COMMAND is powered on"
    echo "  - Verify IP address: $TARGET_HOST"
    exit 1
fi
echo ""

# Test 2: SSH port open
echo -e "${CYAN}[Test 2]${NC} SSH port (22) availability..."
if timeout 2 bash -c "echo > /dev/tcp/$TARGET_HOST/22" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} SSH port 22 is open"
else
    echo -e "${RED}✗${NC} SSH port 22 is not accessible"
    echo "  - Verify SSH service is running on HOMELAB-COMMAND"
    echo "  - Check firewall rules"
    exit 1
fi
echo ""

# Test 3: SSH authentication
echo -e "${CYAN}[Test 3]${NC} SSH authentication..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "exit" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} SSH authentication successful (key-based)"
else
    echo -e "${YELLOW}⚠${NC} SSH key authentication failed, trying password..."
    if ssh -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "exit"; then
        echo -e "${GREEN}✓${NC} SSH authentication successful (password)"
        echo -e "${YELLOW}⚠${NC} Recommendation: Set up SSH key authentication"
    else
        echo -e "${RED}✗${NC} SSH authentication failed"
        echo "  - Verify username: $TARGET_USER"
        echo "  - Set up SSH keys: ssh-copy-id $TARGET_USER@$TARGET_HOST"
        exit 1
    fi
fi
echo ""

# Test 4: Basic commands
echo -e "${CYAN}[Test 4]${NC} Running basic commands..."
HOSTNAME=$(ssh -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "hostname" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Remote hostname: $HOSTNAME"
else
    echo -e "${RED}✗${NC} Failed to execute remote command"
    exit 1
fi
echo ""

# Test 5: Check Node.js
echo -e "${CYAN}[Test 5]${NC} Checking Node.js installation..."
NODE_VERSION=$(ssh -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "node --version" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Node.js version: $NODE_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Node.js not found or not in PATH"
fi
echo ""

# Test 6: Check Git
echo -e "${CYAN}[Test 6]${NC} Checking Git installation..."
GIT_VERSION=$(ssh -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "git --version" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Git version: $GIT_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Git not found or not in PATH"
fi
echo ""

# Test 7: Check Claude Code
echo -e "${CYAN}[Test 7]${NC} Checking Claude Code installation..."
CLAUDE_VERSION=$(ssh -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "claude --version" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Claude Code version: $CLAUDE_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Claude Code not found or not in PATH"
    echo "  - Install: npm install -g @anthropic-ai/claude-code"
fi
echo ""

# Test 8: Check projects directory
echo -e "${CYAN}[Test 8]${NC} Checking projects directory..."
PROJECTS_EXIST=$(ssh -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "test -d ~/projects && echo exists" 2>/dev/null)
if [ "$PROJECTS_EXIST" = "exists" ]; then
    echo -e "${GREEN}✓${NC} Projects directory exists: ~/projects"

    # List repositories
    REPOS=$(ssh -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "ls ~/projects 2>/dev/null" 2>/dev/null)
    if [ -n "$REPOS" ]; then
        echo "  Repositories found:"
        echo "$REPOS" | while read repo; do
            echo "    - $repo"
        done
    else
        echo -e "${YELLOW}⚠${NC} No repositories found in ~/projects"
    fi
else
    echo -e "${YELLOW}⚠${NC} Projects directory not found"
    echo "  - Create: mkdir ~/projects"
fi
echo ""

# Test 9: Test Claude Code execution
echo -e "${CYAN}[Test 9]${NC} Testing Claude Code execution..."
CLAUDE_TEST=$(ssh -o ConnectTimeout=10 "$TARGET_USER@$TARGET_HOST" "cd ~/projects/infrastructure 2>/dev/null && claude -p 'What is 2+2?' 2>&1 | head -5" 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$CLAUDE_TEST" ]; then
    echo -e "${GREEN}✓${NC} Claude Code executed successfully"
    echo "  Response preview:"
    echo "$CLAUDE_TEST" | sed 's/^/    /'
else
    echo -e "${YELLOW}⚠${NC} Claude Code execution test skipped or failed"
    echo "  - Ensure Claude Code is authenticated: claude auth"
    echo "  - Ensure infrastructure repo is cloned"
fi
echo ""

# Summary
echo -e "${CYAN}====================================${NC}"
echo -e "${CYAN}Summary${NC}"
echo -e "${CYAN}====================================${NC}"
echo ""
echo "Target: $TARGET_USER@$TARGET_HOST"
echo ""

# Count successes
SUCCESS_COUNT=0
TOTAL_TESTS=9

# We know test 1-4 passed if we got here
SUCCESS_COUNT=4

[ -n "$NODE_VERSION" ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ -n "$GIT_VERSION" ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ -n "$CLAUDE_VERSION" ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$PROJECTS_EXIST" = "exists" ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ -n "$CLAUDE_TEST" ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

if [ $SUCCESS_COUNT -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}✓ All tests passed ($SUCCESS_COUNT/$TOTAL_TESTS)${NC}"
    echo ""
    echo "Ready for:"
    echo "  - VSCode Remote SSH connection"
    echo "  - n8n SSH integration"
    echo "  - Claude Code automation"
    echo ""
    echo "Next steps:"
    echo "  1. Test VSCode Remote SSH from M6800"
    echo "  2. Configure n8n SSH credentials"
    echo "  3. Create test workflow in n8n"
elif [ $SUCCESS_COUNT -ge 7 ]; then
    echo -e "${GREEN}✓ Most tests passed ($SUCCESS_COUNT/$TOTAL_TESTS)${NC}"
    echo ""
    echo "Core SSH functionality is working."
    echo "Review warnings above for optional improvements."
else
    echo -e "${YELLOW}⚠ Some tests failed ($SUCCESS_COUNT/$TOTAL_TESTS)${NC}"
    echo ""
    echo "Review errors above and complete setup steps."
    echo "See: HOMELAB-COMMAND-SETUP.md"
fi
echo ""
