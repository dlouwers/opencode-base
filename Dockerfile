# VibeBox Base Image
# Secure foundation for Vibe Coding agents

FROM mcr.microsoft.com/devcontainers/base:1-bookworm

# OCI Labels
LABEL org.opencontainers.image.source="https://github.com/dlouwers/vibebox-base"
LABEL org.opencontainers.image.description="Secure base image for Vibe Coding agents with isolated tooling"
LABEL org.opencontainers.image.licenses="MIT"

# Install system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        nodejs \
        npm \
        build-essential \
        ca-certificates \
        curl \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Vibe tools globally
RUN npm install -g opencode-ai vibebox oh-my-opencode

# Create sandbox workspace with open permissions
RUN mkdir -p /workspaces && chmod 777 /workspaces

# Copy security configuration
COPY vibebox.toml /etc/vibebox.toml

# Set working directory
WORKDIR /workspaces

# Default shell
CMD ["/bin/bash"]
