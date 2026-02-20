# VibeBox Base

[![Docker Image](https://img.shields.io/docker/v/dlouwers/vibebox-base?label=Docker%20Hub)](https://hub.docker.com/r/dlouwers/vibebox-base)
[![Build Status](https://github.com/dlouwers/vibebox-base/actions/workflows/publish.yml/badge.svg)](https://github.com/dlouwers/vibebox-base/actions)

Secure, reusable Docker base image for Vibe Coding agents. Provides isolated tooling and sandboxed execution environment.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Supported Architectures](#supported-architectures)
- [Using with Dev Containers](#using-with-dev-containers)
- [Security Configuration](#security-configuration)
- [Using Additional Tools](#using-additional-tools)
- [Development](#development)
- [CI/CD Pipeline](#cicd-pipeline)
- [Versioning](#versioning)
- [Maintenance](#maintenance)
- [License](#license)
- [Contributing](#contributing)

## Features

- **Multi-Architecture Support**: Native support for AMD64 (x86_64) and ARM64 (Apple Silicon, Raspberry Pi)
- **Debian Bookworm Base**: Stable, slim foundation from Microsoft Dev Containers
- **Pre-installed Tools**: 
  - `opencode-ai`: Autonomous terminal-based AI coding agent
  - `vibebox`: CLI for sandbox boundary management and security enforcement
  - `oh-my-opencode`: OpenCode plugin harness for multi-agent orchestration
  - Node.js & npm: Required runtime for agent tooling (not for language-specific development)
- **Hybrid Architecture**: Supports running vibe-kanban on host with containerized agents
- **Security First**: Strict isolation via `vibebox.toml` with blocked sensitive paths
- **CI/CD Ready**: Automated builds and publishing via GitHub Actions
- **Auto-updates**: Dependabot monitoring for base image and action updates

## Quick Start

### Pull from DockerHub

```bash
docker pull dlouwers/vibebox-base:latest
```

The image automatically pulls the correct architecture for your platform (AMD64 or ARM64).

### Run Interactive Container

```bash
docker run -it --rm -v $(pwd):/workspaces dlouwers/vibebox-base:latest
```

### Use in Dockerfile

```dockerfile
FROM dlouwers/vibebox-base:latest

# Your custom agent setup here
COPY ./agent-config /workspaces/config

# Start the agent with your configuration
CMD ["opencode-ai", "--config", "/workspaces/config/agent.json"]
```

## Supported Architectures

This image supports multiple architectures:

- `linux/amd64` - x86_64 processors (Intel, AMD)
- `linux/arm64` - ARM64 processors (Apple Silicon M1/M2/M3, Raspberry Pi 4/5)

Docker automatically selects the correct image for your platform.

## Using with Dev Containers

This image is optimized for use with [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) and [IntelliJ IDEA](https://www.jetbrains.com/help/idea/connect-to-devcontainer.html).

### VS Code Setup

Create a `.devcontainer/devcontainer.json` file in your project:

```json
{
  "name": "Vibe Coding Environment",
  "image": "dlouwers/vibebox-base:latest",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind",
  "forwardPorts": [3000],
  "portsAttributes": {
    "3000": {
      "label": "Vibe Kanban",
      "onAutoForward": "openBrowser"
    }
  },
  "containerEnv": {
    "PORT": "3000"
  },
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  },
  "remoteUser": "vscode",
  "features": {
    "ghcr.io/devcontainers/features/git:1": {}
  }
}
```

**To use:**
1. Install [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open your project in VS Code
3. Press `F1` → "Dev Containers: Reopen in Container"
4. VS Code will build and connect to the container automatically

### IntelliJ IDEA Setup

IntelliJ IDEA supports Dev Containers via Docker integration.

**Prerequisites:**
- IntelliJ IDEA 2023.3+ (Ultimate or Community Edition)
- Docker Desktop running

**Setup Steps:**

1. **Create `.devcontainer/devcontainer.json`** in your project root:

```json
{
  "name": "Vibe Coding Environment",
  "image": "dlouwers/vibebox-base:latest",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind"
}
```

2. **Open Project in IntelliJ:**
   - File → Open → Select your project directory
   - IntelliJ will detect the `.devcontainer` configuration

3. **Connect to Dev Container:**
   - Click the notification: "Dev Container configuration detected"
   - Or: Tools → Dev Containers → Create Dev Container and Mount Sources
   - IntelliJ will build/start the container and configure remote development

4. **Verify Connection:**
   - Terminal should show container shell
   - Run `which opencode-ai` to verify tools are available

**Note:** IntelliJ Ultimate has better Dev Container support than Community Edition. For Community Edition, consider using Docker Compose instead.

### Using with Docker Compose

For projects requiring multiple services, create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  dev:
    image: dlouwers/vibebox-base:latest
    volumes:
      - .:/workspaces:cached
    working_dir: /workspaces
    command: sleep infinity
    stdin_open: true
    tty: true
```

Then in `.devcontainer/devcontainer.json`:

```json
{
  "name": "Vibe Coding Environment",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "dev",
  "workspaceFolder": "/workspaces"
}
```

## Security Configuration

The image includes `vibebox.toml` with strict isolation and runs as a non-root user (`vscode`) by default for enhanced security.

### Default Security Settings

- **Allowed Workspace**: `/workspaces` (read-write)
- **Blocked Paths**: SSH keys, shell history, credentials, Docker socket
- **User Context**: Runs as non-root user `vscode` (UID 1000)

### Customizing Security

You can customize the security configuration by mounting your own `vibebox.toml`:

```bash
docker run -it --rm \
  -v $(pwd):/workspaces \
  -v $(pwd)/custom-vibebox.toml:/etc/vibebox.toml:ro \
  dlouwers/vibebox-base:latest
```

**Example custom configuration** to whitelist additional directories:

```toml
[security]
mode = "strict"

[mounts]
allowed = ["/workspaces", "/tmp/shared"]
read_write = ["/workspaces"]

[blocked_paths]
paths = [
    "/root/.ssh",
    "/home/*/.ssh",
    "/var/run/docker.sock"
]
```

See [`vibebox.toml`](./vibebox.toml) for the default configuration.

## Using Additional Tools

### Vibe Kanban (Recommended Architecture: Host + Container)

[Vibe Kanban](https://vibekanban.com) is a task management tool that integrates with your project. Due to upstream network binding limitations ([issue #1647](https://github.com/BloopAI/vibe-kanban/issues/1647)), the recommended setup is to run vibe-kanban on your **host machine** while agents execute in the **container**.

#### Architecture Overview

```
┌─────────────────────────────────────┐
│  HOST MACHINE                       │
│  ├─ Vibe Kanban (Web UI)           │  ← Runs natively (no network issues)
│  ├─ Git Worktrees                  │  ← Managed by vibe-kanban
│  └─ Spawns: docker exec ...        │  ← Executes agents in container
│                  ↓                  │
│  ┌─────────────────────────────┐   │
│  │ CONTAINER (vibebox-container)│  │
│  │  ├─ opencode-ai              │   │  ← Agent runs isolated
│  │  ├─ oh-my-opencode           │   │
│  │  └─ /vibe-workspaces/        │   │  ← Mounted from host
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

#### Setup Instructions

**Step 1: Install vibe-kanban on your host machine**

```bash
npm install -g vibe-kanban
```

**Step 2: Start the devcontainer**

Open your project in VS Code and reopen in container (`F1` → "Dev Containers: Reopen in Container"). This will:
- Start a container named `vibebox-container`
- Mount `~/.vibe-kanban-workspaces` to `/vibe-workspaces` in the container
- Mount `~/.config/opencode` to `/root/.config/opencode` (for agent configuration)

**Step 3: Configure vibe-kanban agent profile**

Create or edit `~/.vibe-kanban/profiles.json` on your **host machine**:

```json
{
  "executors": {
    "OPENCODE": {
      "DOCKER_CONTAINER": {
        "OPENCODE": {
          "auto_approve": false,
          "auto_compact": true,
          "base_command_override": "docker exec -i vibebox-container npx -y opencode-ai serve --hostname 0.0.0.0 --port 8080",
          "env": {
            "OPENCODE_PERMISSION": "{\"question\":\"allow\"}",
            "NODE_NO_WARNINGS": "1",
            "NPM_CONFIG_LOGLEVEL": "error"
          }
        }
      }
    }
  }
}
```

**Alternative:** A sample profile is included in this repository at `.vibe-kanban-profile.json`. You can copy it:

```bash
# Copy example profile to vibe-kanban config directory
mkdir -p ~/.vibe-kanban
cp .vibe-kanban-profile.json ~/.vibe-kanban/profiles.json
```

**Step 4: Start vibe-kanban on host**

```bash
# From your host terminal (not inside the container)
vibe-kanban
```

The web UI will open at http://localhost:3000 ✅ (works perfectly on host)

**Step 5: Select the DOCKER_CONTAINER agent profile**

In Vibe Kanban UI:
1. Go to Settings → Agents
2. Select "OPENCODE" → "DOCKER_CONTAINER" variant
3. Start a workspace - the agent will execute inside the container

#### How It Works

1. **Vibe-kanban runs on host** - No network binding issues, native performance
2. **Worktrees created on host** - In `~/.vibe-kanban-workspaces/` directory
3. **Agent spawned via docker exec** - `docker exec -i vibebox-container opencode-ai`
4. **Communication via stdio** - Vibe-kanban pipes stdin/stdout through docker exec
5. **Container accesses worktrees** - Via mounted volume at `/vibe-workspaces/`

#### Benefits of This Architecture

✅ **No network binding issues** - Vibe-kanban runs natively on host  
✅ **Agent isolation** - OpenCode runs in secure container  
✅ **Shared configuration** - `~/.config/opencode` accessible to both host and container  
✅ **File system consistency** - Worktrees on host, accessible in container via mount  
✅ **Flexible** - Can switch between container and native agents easily  

#### Troubleshooting

**Issue: "Cannot connect to Docker daemon"**
- Ensure Docker Desktop is running
- Verify `vibebox-container` exists: `docker ps | grep vibebox-container`
- If not running, open VS Code and reopen in container

**Issue: "Error: ENOENT: no such file or directory"**
- Check that `~/.vibe-kanban-workspaces` exists: `mkdir -p ~/.vibe-kanban-workspaces`
- Verify the devcontainer is running with correct mounts: `docker inspect vibebox-container | grep vibe-workspaces`

**Issue: Agent not responding**
- Check container logs: `docker logs vibebox-container`
- Verify opencode-ai is available: `docker exec vibebox-container which opencode-ai`
- Test manual execution: `docker exec -it vibebox-container npx -y opencode-ai --version`

**Issue: Worktree path mismatches**
- Vibe-kanban creates worktrees on host at `~/.vibe-kanban-workspaces/`
- These are mounted to `/vibe-workspaces/` in container
- Ensure paths in your project configuration account for this mapping

## Development

### Opening the Workspace

This project includes a `kanban-dev.code-workspace` file for multi-folder workspace support. It provides quick access to:
- **Main Project**: The repository root
- **Active Worktrees**: OpenKanban task branches at `/worktrees`

#### Expected Warning on Host

When opening `kanban-dev.code-workspace` on your host machine, VS Code will show a warning:

```
The workspace file references a path '/worktrees' that does not exist.
The devcontainer might fail to start.
```

**This warning is expected and harmless.** Here's why:

- The `/worktrees` folder only exists **inside** the devcontainer
- It's mounted from `~/.kanban-worktrees` on your host when the container starts
- VS Code validates paths before the container starts, hence the warning
- Once the devcontainer opens, the path becomes available and works correctly

**To use the workspace:**
1. Open `kanban-dev.code-workspace` in VS Code (ignore the warning)
2. When prompted, click "Reopen in Container"
3. The `/worktrees` folder will be accessible once the container starts

The workspace provides convenient sidebar access to all OpenKanban task branches, making it easy to review changes across multiple worktrees.

### Build Locally

```bash
docker build -t vibebox-base:local .
```

### Test Container

```bash
docker run -it --rm vibebox-base:local
```

## CI/CD Pipeline

Automated via GitHub Actions:

- **On Push to `main`**: Builds and publishes `latest` tag
- **On Release Tag (`v*`)**: Publishes versioned tags
- **On Pull Request**: Builds without publishing (validation)

## Versioning

- `latest`: Latest stable build from `main`
- `v1.0.0`: Semantic versioning for releases
- `v1.0`: Major.minor tags
- `v1`: Major version tags

## Maintenance

- **Dependabot**: Weekly checks for base image and GitHub Actions updates
- **Manual Review**: PRs reviewed before merging

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

For issues or questions, open a [GitHub Issue](https://github.com/dlouwers/vibebox-base/issues).
