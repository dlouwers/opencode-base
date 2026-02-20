#!/bin/bash

# We REMOVE 'set -e' here so the container doesn't crash 
# if a single non-critical command (like prune) fails.

echo "==> Configuring OpenKanban..."
# Ensure the directory exists before writing the file
mkdir -p ~/.config/openkanban
if [ ! -f ~/.config/openkanban/config.json ]; then
    echo '{"agent": {"command": "opencode", "args": ["-y", "ulw"]}, "defaults": {"worktree_base": "/worktrees"}}' > ~/.config/openkanban/config.json
else
    # Ensure worktree_base is set in existing config
    if command -v jq >/dev/null 2>&1; then
        tmp=$(mktemp)
        jq '.defaults.worktree_base = "/worktrees"' ~/.config/openkanban/config.json > "$tmp" && mv "$tmp" ~/.config/openkanban/config.json
    fi
fi

echo "==> Configuring OhMyOpenCode..."
if command -v oh-my-opencode >/dev/null 2>&1; then
    if [ -f ~/.config/opencode/opencode.json ] && ! grep -q 'oh-my-opencode' ~/.config/opencode/opencode.json; then
        oh-my-opencode install --no-tui --claude=no --openai=no --gemini=no --copilot=yes || echo "Notice: oh-my-opencode already configured."
    fi
fi

# --- OpenCode Engine Setup ---
export OPENCODE_PORT=4096
MAX_ATTEMPTS=40
ATTEMPT=0
OPENCODE_LOG="/tmp/opencode-startup.log"

echo "==> Starting OpenCode engine..."
# Use nohup and disown to ensure the process is orphaned from the terminal.
# This prevents it from being killed when the "Configuring..." terminal closes.
nohup opencode serve --port $OPENCODE_PORT > "$OPENCODE_LOG" 2>&1 &
disown

echo "==> Waiting for engine to stabilize (Port $OPENCODE_PORT)..."
until curl -s http://localhost:$OPENCODE_PORT > /dev/null; do
  sleep 0.5
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "Error: OpenCode engine failed to start within $((MAX_ATTEMPTS / 2)) seconds."
    echo "==> OpenCode startup log:"
    cat "$OPENCODE_LOG" 2>/dev/null || echo "(no log available)"
    exit 1
  fi
done

# --- Worktree & Permission Setup ---
echo "==> Preparing Worktree Sandbox..."

# 1. Fix Permissions for the worktree mount
sudo chmod 777 /worktrees || true

# 2. Workaround: openkanban's worktree_base config is broken (dead code).
#    It hardcodes worktrees to {workspace}-worktrees. Symlink to our mount.
WORKSPACE_NAME=$(basename "$(pwd)")
EXPECTED_WORKTREE_DIR="/workspaces/${WORKSPACE_NAME}-worktrees"
if [ ! -e "$EXPECTED_WORKTREE_DIR" ]; then
    sudo ln -s /worktrees "$EXPECTED_WORKTREE_DIR"
fi

# 3. Secure Git Trust
git config --global --add safe.directory "$(pwd)" || true
git config --global --add safe.directory /worktrees || true

# 3. Clean up stale Git metadata (Safe check)
# Only run if we are actually in a git repo to prevent Exit 1 failures
if [ -d .git ] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "==> Pruning stale worktrees..."
    git worktree prune || true
fi

echo "==> Setup Complete! Engine ready after $((ATTEMPT / 2)) seconds."