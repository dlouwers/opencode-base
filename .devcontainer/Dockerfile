FROM mcr.microsoft.com/devcontainers/javascript-node:20

ARG TARGETARCH

# 1. Dynamically fetch arm64 for Apple Silicon, or amd64 for Intel/Windows
RUN apt-get update && apt-get install -y jq tar \
    && if [ "$TARGETARCH" = "arm64" ]; then \
         ARCH_REGEX="(?i)linux.*arm64.*\\.tar\\.gz$"; \
       else \
         ARCH_REGEX="(?i)linux.*(amd64|x86_64).*\\.tar\\.gz$"; \
       fi \
    && ASSET_URL=$(curl -s https://api.github.com/repos/TechDufus/openkanban/releases/latest | jq -r --arg regex "$ARCH_REGEX" '.assets[] | select(.name | test($regex)) | .browser_download_url') \
    && if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then \
         echo "Error: Failed to determine OpenKanban asset URL for architecture regex: $ARCH_REGEX" >&2; \
         exit 1; \
       fi \
    && curl -fSL -o openkanban.tar.gz "$ASSET_URL" \
    && tar -xzf openkanban.tar.gz -C /usr/local/bin/ openkanban \
    && chmod +x /usr/local/bin/openkanban \
    && rm openkanban.tar.gz

# 2. Pre-install oh-my-opencode CLI globally as root
RUN npm install -g oh-my-opencode

# 3. Switch to the built-in non-root user to install OpenCode
USER node
RUN curl -fsSL https://opencode.ai/install | bash

# 4. Fix PATH for non-interactive shells (opencode installer only adds to .bashrc
#    after the interactive guard, making it unreachable for scripts/docker exec)
USER root
RUN echo 'export PATH=/home/node/.opencode/bin:$PATH' > /etc/profile.d/opencode.sh \
    && chmod +x /etc/profile.d/opencode.sh
ENV PATH="/home/node/.opencode/bin:$PATH"

# 5. Create opencode data directories (mounts target subdirs, so parent must exist)
RUN mkdir -p /home/node/.local/share/opencode \
    && chown -R node:node /home/node/.local

USER node