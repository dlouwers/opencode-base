#!/bin/bash

# We REMOVE 'set -e' here so the container doesn't crash 
# if a single non-critical command (like prune) fails.

export PATH=/home/node/.opencode/bin:$PATH

echo "==> Configuring OpenKanban..."
# Ensure the directory exists before writing the file
mkdir -p ~/.config/openkanban
if [ ! -f ~/.config/openkanban/config.json ]; then
    echo '{"agent": {"command": "opencode", "args": ["-y", "ulw"]}, "defaults": {"worktree_base": "/worktrees"}}' > ~/.config/openkanban/config.json
else
    if command -v jq >/dev/null 2>&1; then
        tmp=$(mktemp)
        jq '.defaults.worktree_base = "/worktrees"' ~/.config/openkanban/config.json > "$tmp" 2>/dev/null && mv "$tmp" ~/.config/openkanban/config.json
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

# Fix permissions on /workspaces and /worktrees
sudo chmod 777 /worktrees || true
sudo chmod 755 /workspaces || true

# Workaround: openkanban's worktree_base config is broken (dead code).
# It hardcodes worktrees to {workspace}-worktrees. Symlink to our mount.
WORKSPACE_NAME=$(ls /workspaces 2>/dev/null | grep -v worktrees | head -1)
if [ -n "$WORKSPACE_NAME" ]; then
    EXPECTED_WORKTREE_DIR="/workspaces/${WORKSPACE_NAME}-worktrees"
    if [ ! -e "$EXPECTED_WORKTREE_DIR" ]; then
        sudo ln -s /worktrees "$EXPECTED_WORKTREE_DIR"
    fi
fi

git config --global --add safe.directory "/workspaces/$WORKSPACE_NAME" || true
git config --global --add safe.directory /worktrees || true
git config --global --add safe.directory '*' || true

if [ -d "/workspaces/$WORKSPACE_NAME/.git" ]; then
    echo "==> Pruning stale worktrees..."
    git -C "/workspaces/$WORKSPACE_NAME" worktree prune || true
fi

echo "==> Setup Complete! Engine ready after $((ATTEMPT / 2)) seconds."