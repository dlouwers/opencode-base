#!/bin/bash
# initialize-host.sh - Runs on your Mac

PATHS=(
    "$HOME/.config/openkanban"
    "$HOME/.config/opencode"
    "$HOME/.local/share/opencode"
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