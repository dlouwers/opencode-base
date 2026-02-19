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

### Vibe Kanban

[Vibe Kanban](https://vibekanban.com) is a task management tool that integrates with your project. It's designed to run on-demand from within your workspace, not as a background service.

**Usage from within the container:**

```bash
# Navigate to your project directory
cd /workspaces/my-project

# Start Vibe Kanban (opens in browser automatically)
npx vibe-kanban
```

Vibe Kanban will:
- Create git worktrees for task isolation
- Launch a web UI (typically on port 3000)
- Provide a Kanban board for task management

**Port forwarding:** When using Dev Containers, VS Code/IntelliJ will automatically detect and forward port 3000. You can also manually forward ports:

```bash
# Docker run with port forwarding
docker run -it --rm -p 3000:3000 -v $(pwd):/workspaces dlouwers/vibebox-base:latest
```

**Note:** Vibe Kanban requires user interaction to start and is intended for interactive development sessions, not as an always-on service.

## Development

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
