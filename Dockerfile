FROM mcr.microsoft.com/devcontainers/javascript-node:24

LABEL org.opencontainers.image.source="https://github.com/dlouwers/opencode-base"
LABEL org.opencontainers.image.description="Secure devcontainer for Vibe Coding agents"
LABEL org.opencontainers.image.licenses="MIT"

ARG TARGETARCH
ARG OPENKANBAN_VERSION=0.1.0

RUN apt-get update && apt-get install -y tar \
    && if [ "$TARGETARCH" = "arm64" ]; then \
         ARCH="arm64"; \
       else \
         ARCH="amd64"; \
       fi \
    && curl -fSL -o openkanban.tar.gz "https://github.com/TechDufus/openkanban/releases/download/v${OPENKANBAN_VERSION}/openkanban_${OPENKANBAN_VERSION}_linux_${ARCH}.tar.gz" \
    && tar -xzf openkanban.tar.gz -C /usr/local/bin/ openkanban \
    && chmod +x /usr/local/bin/openkanban \
    && rm openkanban.tar.gz \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g oh-my-opencode

USER node
RUN curl -fsSL https://opencode.ai/install | bash

USER root
RUN echo 'export PATH=/home/node/.opencode/bin:$PATH' > /etc/profile.d/opencode.sh \
    && chmod +x /etc/profile.d/opencode.sh
ENV PATH="/home/node/.opencode/bin:$PATH"

RUN mkdir -p /home/node/.local/share/opencode \
    && chown -R node:node /home/node/.local

USER node
