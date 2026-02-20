#!/bin/bash
# verify-setup.sh - Test devcontainer setup after switching to published image
# Run this inside the devcontainer to verify everything works

set -e

echo "=========================================="
echo "OpenCode Base DevContainer Verification"
echo "=========================================="
echo ""

EXIT_CODE=0
IS_WORKTREE=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

WORKSPACE_NAME=$(ls /workspaces 2>/dev/null | grep -v worktrees | head -1)
if [ -n "$WORKSPACE_NAME" ]; then
    GIT_FILE="/workspaces/$WORKSPACE_NAME/.git"
    if [ -f "$GIT_FILE" ] && grep -q "gitdir:" "$GIT_FILE" 2>/dev/null; then
        IS_WORKTREE=true
    fi
fi

if [ "$IS_WORKTREE" = true ]; then
    echo -e "${YELLOW}NOTE: Running inside a git worktree.${NC}"
    echo "The devcontainer is designed to be opened from the main repo."
    echo "Worktree context will cause git and engine warnings — this is expected."
    echo "To test fully, open the main repo in VS Code and Reopen in Container."
    echo ""
fi

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    EXIT_CODE=1
}

test_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. Testing Required Binaries"
echo "------------------------------"

# Test opencode
if command -v opencode &> /dev/null; then
    VERSION=$(opencode --version 2>&1 | head -1 || echo "unknown")
    test_pass "opencode is installed: $VERSION"
else
    test_fail "opencode is NOT installed"
fi

# Test openkanban
if command -v openkanban &> /dev/null; then
    VERSION=$(openkanban version 2>&1 || echo "unknown")
    test_pass "openkanban is installed: $VERSION"
else
    test_fail "openkanban is NOT installed"
fi

# Test oh-my-opencode
if command -v oh-my-opencode &> /dev/null; then
    test_pass "oh-my-opencode is installed"
else
    test_fail "oh-my-opencode is NOT installed"
fi

echo ""
echo "2. Testing User and Permissions"
echo "--------------------------------"

CURRENT_USER=$(whoami)
test_pass "Running as user: $CURRENT_USER"

if [ "$CURRENT_USER" = "node" ]; then
    test_pass "User is 'node' as expected"
else
    test_warn "User is '$CURRENT_USER' (expected 'node')"
fi

echo ""
echo "3. Testing Directory Mounts"
echo "---------------------------"

# Test workspace
if [ -d "/workspaces" ]; then
    test_pass "/workspaces directory exists"
    
    WORKSPACE_DIR=$(ls -d /workspaces/*/ 2>/dev/null | head -1)
    if [ -n "$WORKSPACE_DIR" ] && [ -w "$WORKSPACE_DIR" ]; then
        test_pass "Workspace project directory is writable"
    elif [ -w "/workspaces" ]; then
        test_pass "/workspaces mount point is writable"
    else
        test_warn "/workspaces mount point owned by root (normal for Docker mounts)"
    fi
else
    test_fail "/workspaces directory does NOT exist"
fi

# Test worktrees
if [ -d "/worktrees" ]; then
    test_pass "/worktrees directory exists"
    if [ -w "/worktrees" ]; then
        test_pass "/worktrees is writable"
    else
        test_warn "/worktrees is NOT writable (post-start.sh may fix this)"
    fi
else
    test_warn "/worktrees directory does NOT exist (post-start.sh should create it)"
fi

# Test config directories
CONFIG_DIRS=(
    "$HOME/.config/openkanban"
    "$HOME/.config/opencode"
    "$HOME/.local/share/opencode"
    "$HOME/.local/state/opencode"
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        test_pass "$dir exists"
    else
        test_warn "$dir does NOT exist (may be created by post-start.sh)"
    fi
done

echo ""
echo "4. Testing OpenCode Configuration"
echo "----------------------------------"

if [ -f "$HOME/.config/opencode/opencode.json" ]; then
    test_pass "OpenCode config file exists"
    if grep -q "oh-my-opencode" "$HOME/.config/opencode/opencode.json" 2>/dev/null; then
        test_pass "oh-my-opencode is configured in OpenCode"
    else
        test_warn "oh-my-opencode NOT found in OpenCode config (post-start.sh may configure it)"
    fi
else
    test_warn "OpenCode config file does NOT exist (may be created on first run)"
fi

echo ""
echo "5. Testing OpenKanban Configuration"
echo "------------------------------------"

if [ -f "$HOME/.config/openkanban/config.json" ]; then
    test_pass "OpenKanban config file exists"
    if grep -q '"/worktrees"' "$HOME/.config/openkanban/config.json" 2>/dev/null; then
        test_pass "OpenKanban worktree_base is set to /worktrees"
    else
        test_warn "OpenKanban worktree_base NOT set to /worktrees (post-start.sh may fix this)"
    fi
else
    test_warn "OpenKanban config does NOT exist (post-start.sh should create it)"
fi

echo ""
echo "6. Testing OpenCode Engine"
echo "--------------------------"

if ps aux | grep -v grep | grep -q "opencode serve"; then
    test_pass "OpenCode engine process is running"
    if curl -s http://localhost:4096 > /dev/null 2>&1; then
        test_pass "OpenCode engine is responding on port 4096"
    else
        test_warn "OpenCode engine process running but not responding on port 4096"
    fi
elif [ "$IS_WORKTREE" = true ]; then
    test_warn "OpenCode engine not running (expected in worktree context — no main .git)"
else
    test_fail "OpenCode engine is NOT running"
fi

echo ""
echo "7. Testing Git Configuration"
echo "-----------------------------"

WORKSPACE_NAME=$(ls /workspaces 2>/dev/null | grep -v worktrees | head -1)
if [ -n "$WORKSPACE_NAME" ]; then
    test_pass "Found workspace: $WORKSPACE_NAME"
    
    if git config --global --get-all safe.directory | grep -qE "(\*|/workspaces/$WORKSPACE_NAME)" 2>/dev/null; then
        test_pass "Workspace is marked as git safe.directory"
    else
        test_warn "Workspace NOT marked as git safe.directory (post-start.sh may fix this)"
    fi
    
    if git -C "/workspaces/$WORKSPACE_NAME" rev-parse --git-dir >/dev/null 2>&1; then
        test_pass "Git repository is accessible"
    elif [ "$IS_WORKTREE" = true ]; then
        test_warn "Git not accessible (expected in worktree context — main .git not mounted)"
    else
        test_fail "Git repository not accessible"
    fi
else
    test_warn "No workspace found in /workspaces"
fi

echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}All critical tests passed!${NC}"
    echo ""
    echo "Note: Some warnings are expected before post-start.sh runs."
    echo "If you see warnings, try:"
    echo "  1. Close and reopen the devcontainer"
    echo "  2. Run: bash .devcontainer/post-start.sh"
else
    echo -e "${RED}Some tests failed!${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check that the published image is up to date:"
    echo "     docker pull dlouwers/opencode-base:latest"
    echo "  2. Rebuild the devcontainer:"
    echo "     Dev Containers: Rebuild Container"
    echo "  3. Check Docker logs for errors:"
    echo "     docker logs <container-id>"
    echo "  4. Verify the Dockerfile builds successfully:"
    echo "     docker build -t test-image ."
fi
echo "=========================================="

exit $EXIT_CODE
