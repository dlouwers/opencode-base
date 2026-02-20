# Testing Guide: Published DevContainer Image

## Overview

This project now uses the published image `dlouwers/opencode-base:latest` instead of building from the local Dockerfile. This guide explains how to verify the setup works correctly.

## Automated Verification

Run the verification script inside the devcontainer:

```bash
bash .devcontainer/verify-setup.sh
```

This tests:
- Required binaries (opencode, openkanban, oh-my-opencode)
- User and permissions
- Directory mounts
- Configuration files
- OpenCode engine
- Git configuration

## Manual Testing Steps

### 1. Container Startup Test

**Purpose**: Verify the devcontainer starts without errors

**Steps**:
1. Open VS Code in this project
2. Press F1 → "Dev Containers: Rebuild Container"
3. Wait for container to build and start
4. Check the terminal output for errors

**Expected Result**: Container starts successfully, post-start.sh completes without errors

**If it fails**:
- Check Docker is running: `docker ps`
- Pull the latest image: `docker pull dlouwers/opencode-base:latest`
- Check Docker Desktop has sufficient resources (4GB+ RAM recommended)

### 2. Tool Availability Test

**Purpose**: Verify all required tools are installed

**Steps**:
```bash
opencode --version
openkanban version
oh-my-opencode --help
node --version
npm --version
```

**Expected Result**: All commands return version information

**If it fails**:
- Check PATH: `echo $PATH` should include `/home/node/.opencode/bin`
- Manually verify binaries: `ls -la /home/node/.opencode/bin/`
- Check image was built recently: `docker inspect dlouwers/opencode-base:latest | grep Created`

### 3. Mount Points Test

**Purpose**: Verify host directories are correctly mounted

**Steps**:
```bash
# Check workspace mount
ls -la /workspaces
touch /workspaces/test-file.txt
ls -la /workspaces/test-file.txt
rm /workspaces/test-file.txt

# Check worktrees mount
ls -la /worktrees
touch /worktrees/test-file.txt
ls -la /worktrees/test-file.txt
rm /worktrees/test-file.txt

# Check config mounts
ls -la ~/.config/opencode
ls -la ~/.config/openkanban
ls -la ~/.local/share/opencode
```

**Expected Result**: 
- All directories exist and are writable
- Files created in container appear on host
- Config directories are persistent

**If it fails**:
- Check initialize-host.sh ran: Check host directories exist
  ```bash
  # On host (outside container):
  ls -la ~/.config/openkanban
  ls -la ~/.kanban-worktrees
  ```
- Verify mounts in devcontainer.json match host paths
- Check Docker Desktop file sharing settings (Mac/Windows)

### 4. OpenCode Engine Test

**Purpose**: Verify OpenCode engine starts and responds

**Steps**:
```bash
# Check if engine is running
curl http://localhost:4096

# Check process
ps aux | grep opencode

# Check logs
cat /tmp/opencode-startup.log
```

**Expected Result**: 
- curl returns a response (may be error page, but should connect)
- opencode serve process is running
- Log shows successful startup

**If it fails**:
- Manually start engine: `opencode serve --port 4096`
- Check port isn't already in use: `netstat -tlnp | grep 4096`
- Check firewall settings
- Review post-start.sh for startup issues

### 5. OpenKanban Integration Test

**Purpose**: Verify OpenKanban can create and manage worktrees

**Steps**:
```bash
# Test config
cat ~/.config/openkanban/config.json

# Test worktree creation (if you have a git repo in workspace)
cd /workspaces/*
git worktree list
```

**Expected Result**:
- Config file exists with worktree_base="/worktrees"
- Git worktree commands work
- Symlink exists: `/workspaces/<project>-worktrees` → `/worktrees`

**If it fails**:
- Manually run post-start.sh: `bash .devcontainer/post-start.sh`
- Check git configuration: `git config --global --list | grep safe`
- Verify symlink: `ls -la /workspaces/ | grep worktrees`

### 6. Configuration Persistence Test

**Purpose**: Verify configs persist across container rebuilds

**Steps**:
1. Create a test config:
   ```bash
   echo "test-value" > ~/.config/opencode/test.txt
   ```
2. Rebuild container: F1 → "Dev Containers: Rebuild Container"
3. Check file still exists:
   ```bash
   cat ~/.config/opencode/test.txt
   ```
4. Clean up:
   ```bash
   rm ~/.config/opencode/test.txt
   ```

**Expected Result**: File persists across rebuilds

**If it fails**:
- Check mounts in devcontainer.json are type=bind
- Verify host directories exist and are writable
- Check Docker volume configuration

## Common Issues and Solutions

### Issue: "Failed to pull image"

**Symptoms**: Container build fails with network error

**Solution**:
```bash
# Pull image manually to see full error
docker pull dlouwers/opencode-base:latest

# Check Docker Hub status
curl https://hub.docker.com/v2/repositories/dlouwers/opencode-base/tags/latest

# Try with explicit platform
docker pull --platform linux/amd64 dlouwers/opencode-base:latest  # For Intel/AMD
docker pull --platform linux/arm64 dlouwers/opencode-base:latest  # For Apple Silicon
```

### Issue: "Permission denied" on mounts

**Symptoms**: Cannot write to /worktrees or /workspaces

**Solution**:
```bash
# Check ownership
ls -la /worktrees
ls -la /workspaces

# Fix permissions (run post-start.sh)
bash .devcontainer/post-start.sh

# If still failing, check host permissions:
# On host:
chmod 755 ~/.kanban-worktrees
```

### Issue: "OpenCode engine not starting"

**Symptoms**: curl to localhost:4096 fails

**Solution**:
```bash
# Check what went wrong
cat /tmp/opencode-startup.log

# Try starting manually
opencode serve --port 4096

# Check if port is available
netstat -tlnp | grep 4096

# Kill existing process if needed
pkill -f "opencode serve"
```

### Issue: "Command not found: opencode"

**Symptoms**: opencode command not available

**Solution**:
```bash
# Check PATH
echo $PATH

# Should include /home/node/.opencode/bin
# If not, add it:
export PATH=/home/node/.opencode/bin:$PATH

# Check if binary exists
ls -la /home/node/.opencode/bin/opencode

# If missing, the published image may be outdated
# Pull latest:
docker pull dlouwers/opencode-base:latest

# Or fall back to building locally:
# Edit .devcontainer/devcontainer.json and change:
# "image": "dlouwers/opencode-base:latest"
# to:
# "build": { "dockerfile": "../Dockerfile" }
```

### Issue: "Wrong architecture image"

**Symptoms**: "exec format error" or crashes

**Solution**:
```bash
# Check your platform
uname -m  # Should show x86_64 (amd64) or aarch64 (arm64)

# Check image platform
docker inspect dlouwers/opencode-base:latest | grep Architecture

# Pull correct platform explicitly
docker pull --platform linux/arm64 dlouwers/opencode-base:latest  # Apple Silicon
docker pull --platform linux/amd64 dlouwers/opencode-base:latest  # Intel/AMD
```

## Rollback Plan

If the published image doesn't work, you can revert to building locally:

1. Edit `.devcontainer/devcontainer.json`:
   ```json
   {
     "name": "OpenCode Base Dev Container",
     "build": {
       "dockerfile": "../Dockerfile"
     },
     "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
     ...
   }
   ```

2. Rebuild: F1 → "Dev Containers: Rebuild Container"

This uses the local Dockerfile instead of the published image.

## Performance Comparison

### Published Image (Current)
- **First startup**: ~30-60 seconds (image pull + container start)
- **Subsequent startups**: ~10-15 seconds (cached image)
- **Disk space**: ~500MB (shared across all projects using this image)
- **Consistency**: Same image across all developers

### Local Build (Previous)
- **First startup**: ~5-10 minutes (full build)
- **Subsequent startups**: ~10-15 seconds (cached build)
- **Disk space**: ~500MB per project (separate build cache per project)
- **Consistency**: May differ if Dockerfile changes or base image updates

**Recommendation**: Use published image unless:
- You need custom modifications to the Dockerfile
- The published image is broken or outdated
- You're developing/testing changes to the base image itself
