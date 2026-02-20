#!/bin/bash
# initialize-host.sh - Runs on your Mac

PATHS=(
    "$HOME/.config/openkanban"
    "$HOME/.config/opencode"
    # Mount opencode data directories individually (NOT bin/) to avoid Linux/macOS binary conflicts
    "$HOME/.local/share/opencode/storage"
    "$HOME/.local/share/opencode/snapshot"
    "$HOME/.local/share/opencode/tool-output"
    "$HOME/.local/share/opencode/log"
    "$HOME/.local/state/opencode"
    "$HOME/.kanban-worktrees"
)

echo "==> [Host] Preparing local filesystem..."

for p in "${PATHS[@]}"; do
    mkdir -p "$p"
done

# Ensure the worktree folder is accessible to Docker
# (Required for some Mac Docker Desktop versions)
chmod 755 "$HOME/.kanban-worktrees"

echo "==> [Host] Done."